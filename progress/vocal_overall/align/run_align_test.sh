#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=10

#TODO : Split word-level labeled file
if [ $stage -eq 0 ]; then
  audio=$rootdir/vocal_data/words/words_train
  trainset=$datadir/vocal/words_train
  results=$expdir/make_mfcc/vocal/words_train
  mfcc=$mfccdir/vocal
  local/vocaldata_prep.sh $audio $trainset || exit 1;
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
fi

#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -eq 1 ]; then
  trainset=$datadir/vocal/words_train
  lm=$datadir/lang_nosp
  mdl=$expdir/vocal/labeled_mono_only_words
  steps/train_mono.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl || exit 1;
fi

#TODO : Align to utterance-level file
if [ $stage -eq 2 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_nosp
  mdl=$expdir/vocal/labeled_mono_only_words
  ali=$expdir/vocal/labeled_mono_ali
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali
fi

#TODO : Train triphone with aligned model
if [ $stage -eq 3 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_nosp
  ali=$expdir/vocal/labeled_mono_ali
  mdl=$expdir/vocal/labeled_tri1
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Test the decode WER
if [ $stage -le 4 ]; then
  : '
  # decode using monophone model
  lm=$datadir/lang_nosp_test_tgsmall
  mdl=$expdir/vocal/labeled_mono_only_words
  graph=$mdl/graph_nosp_tgsmall
  testset=$datadir/vocal/test_clean
  result=$mdl/decode_nosp_tgsmall_vocal_test_clean
  utils/mkgraph.sh --mono \
    $lm $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result || exit 1;
  '

  # decode using triphone model (delta+delta-delta)
  lm=$datadir/lang_nosp_test_tgsmall
  mdl=$expdir/vocal/labeled_tri1
  graph=$mdl/graph_nosp_tgsmall
  testset=$datadir/vocal/test_clean
  result=$mdl/decode_nosp_tgsmall_vocal_test_clean
  : '
  utils/mkgraph.sh \
    $lm $mdl $graph || exit 1;
  '
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result || exit 1;
  : '
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm $testset $result || exit 1;
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
    $lm $testset $result || exit 1;
  '
  lm=$datadir/lang_nosp_test_tgsmall
  mdl=$expdir/vocal/vtri1
  graph=$mdl/graph_nosp_tgsmall
  testset=$datadir/vocal/test_clean
  result=$mdl/decode_nosp_tgsmall_vocal_test_clean
  
  utils/mkgraph.sh \
    $lm $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result || exit 1;
fi
