#!/bin/bash
storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
expdir=/data1/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc


. cmd.sh
. path.sh

stage=0

sleep 3h

# train a monophone system
steps/train_mono.sh --boost-silence 1.25 --nj 2 --cmd "$train_cmd" \
  $datadir/speech/train_2kshort $datadir/lang_nosp $expdir/speech/mono || exit 1;

# decode using the monophone model
if [ $stage -ge 1 ]; then
  utils/mkgraph.sh --mono $datadir/lang_nosp_test_tgsmall \
    $expdir/speech/mono $expdir/speech/mono/graph_nosp_tgsmall || exit 1
  for test in test_clean test_other dev_clean dev_other; do
    steps/decode.sh --nj 2 --cmd "$decode_cmd" $expdir/speech/mono/graph_nosp_tgsmall \
      $datadir/speech/$test $expdir/speech/mono/decode_nosp_tgsmall_$test || exit 1
  done
fi

steps/align_si.sh --boost-silence 1.25 --nj 1 --cmd "$train_cmd" \
  $datadir/speech/train_5k $datadir/lang_nosp $expdir/speech/mono $expdir/speech/mono_ali_5k


# train a first delta + delta-delta triphone system on a subset of 5000 utterances
steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 $datadir/speech/train_5k $datadir/lang_nosp $expdir/speech/mono_ali_5k $expdir/speech/tri1 || exit 1;

# decode using the tri1 model
if [ $stage -ge 1 ]; then
  utils/mkgraph.sh $datadir/lang_nosp_test_tgsmall \
    $expdir/speech/tri1 $expdir/speech/tri1/graph_nosp_tgsmall || exit 1;
  for test in test_clean test_other dev_clean dev_other; do
    steps/decode.sh --nj 2 --cmd "$decode_cmd" $expdir/speech/tri1/graph_nosp_tgsmall \
      $datadir/speech/$test $expdir/speech/tri1/decode_nosp_tgsmall_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tgmed} \
      $datadir/speech/$test $expdir/speech/tri1/decode_nosp_{tgsmall,tgmed}_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tglarge} \
      $datadir/speech/$test $expdir/speech/tri1/decode_nosp_{tgsmall,tglarge}_$test || exit 1;
  done
fi

steps/align_si.sh --nj 1 --cmd "$train_cmd" \
  $datadir/speech/train_10k $datadir/lang_nosp $expdir/speech/tri1 $expdir/speech/tri1_ali_10k || exit 1;


# train an LDA+MLLT system.
steps/train_lda_mllt.sh --cmd "$train_cmd" \
   --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
   $datadir/speech/train_10k $datadir/lang_nosp $expdir/speech/tri1_ali_10k $expdir/speech/tri2b || exit 1;

# decode using the LDA+MLLT model
if [ $stage -ge 1 ]; then
  utils/mkgraph.sh $datadir/lang_nosp_test_tgsmall \
    $expdir/speech/tri2b $expdir/speech/tri2b/graph_nosp_tgsmall || exit 1;
  for test in test_clean test_other dev_clean dev_other; do
    steps/decode.sh --nj 2 --cmd "$decode_cmd" $expdir/speech/tri2b/graph_nosp_tgsmall \
      $datadir/speech/$test $expdir/speech/tri2b/decode_nosp_tgsmall_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tgmed} \
      $datadir/speech/$test $expdir/speech/tri2b/decode_nosp_{tgsmall,tgmed}_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tglarge} \
      $datadir/speech/$test $expdir/speech/tri2b/decode_nosp_{tgsmall,tglarge}_$test || exit 1;
  done
fi

# Align a 10k utts subset using the tri2b model
steps/align_si.sh  --nj 1 --cmd "$train_cmd" --use-graphs true \
  $datadir/speech/train_10k $datadir/lang_nosp $expdir/speech/tri2b $expdir/speech/tri2b_ali_10k || exit 1;


# Train tri3b, which is LDA+MLLT+SAT on 10k utts
steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
  $datadir/speech/train_10k $datadir/lang_nosp $expdir/speech/tri2b_ali_10k $expdir/speech/tri3b || exit 1;

# decode using the tri3b model
if [ $stage -ge 1 ]; then
  utils/mkgraph.sh $datadir/lang_nosp_test_tgsmall \
    $expdir/speech/tri3b $expdir/speech/tri3b/graph_nosp_tgsmall || exit 1;
  for test in test_clean test_other dev_clean dev_other; do
    steps/decode_fmllr.sh --nj 2 --cmd "$decode_cmd" \
      $expdir/speech/tri3b/graph_nosp_tgsmall $datadir/speech/$test \
      $expdir/speech/tri3b/decode_nosp_tgsmall_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tgmed} \
      $datadir/speech/$test $expdir/speech/tri3b/decode_nosp_{tgsmall,tgmed}_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tglarge} \
      $datadir/speech/$test $expdir/speech/tri3b/decode_nosp_{tgsmall,tglarge}_$test || exit 1;
  done
fi

# align the entire train_clean_100 subset using the tri3b model
steps/align_fmllr.sh --nj 2 --cmd "$train_cmd" \
  $datadir/speech/train_clean_100 $datadir/lang_nosp \
  $expdir/speech/tri3b $expdir/speech/tri3b_ali_clean_100 || exit 1;


# train another LDA+MLLT+SAT system on the entire 100 hour subset
steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
  $datadir/speech/train_clean_100 $datadir/lang_nosp \
  $expdir/speech/tri3b_ali_clean_100 $expdir/speech/tri4b || exit 1;

# decode using the tri4b model
if [ $stage -ge 1 ]; then
  utils/mkgraph.sh $datadir/lang_nosp_test_tgsmall \
    $expdir/speech/tri4b $expdir/speech/tri4b/graph_nosp_tgsmall || exit 1;
  for test in test_clean test_other dev_clean dev_other; do
    steps/decode_fmllr.sh --nj 2 --cmd "$decode_cmd" \
      $expdir/speech/tri4b/graph_nosp_tgsmall $datadir/speech/$test \
      $expdir/speech/tri4b/decode_nosp_tgsmall_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tgmed} \
      $datadir/speech/$test $expdir/speech/tri4b/decode_nosp_{tgsmall,tgmed}_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,tglarge} \
      $datadir/speech/$test $expdir/speech/tri4b/decode_nosp_{tgsmall,tglarge}_$test || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_nosp_test_{tgsmall,fglarge} \
      $datadir/speech/$test $expdir/speech/tri4b/decode_nosp_{tgsmall,fglarge}_$test || exit 1;
  done
fi
