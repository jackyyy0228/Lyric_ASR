#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=8
expid=exp2

# run_5a_clean_100.sh

#TODO : Split word-level labeled file
if [ $stage -le -1 ]; then
  #audio=$rootdir/vocal_data/words/words_train
  trainset=$datadir/vocal/words_train
  results=$expdir/make_mfcc/vocal/words_train
  mfcc=$mfccdir/vocal
  #local/vocaldata_prep.sh $audio $trainset || exit 1;
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
fi

#TODO : Align to word-level file, 5 min clips
if [ $stage -le 2 ]; then
  trainset=$datadir/vocal/words_train
  lm=$datadir/lang_lyric
  mdl=$expdir/speech/tri4b
  ali=$expdir/vocal/stri4b_ali_only_words_$expid
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train a first delta + delta-delta triphone system
# called tri1
#TODO : Train triphone with aligned model
if [ $stage -le 3 ]; then
  trainset=$datadir/vocal/words_train
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/stri4b_ali_only_words_$expid
  mdl=$expdir/vocal/svtri1_only_words_$expid
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le 4 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/svtri1_only_words_$expid
  ali=$expdir/vocal/svtri1_only_words_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train an LDA+MLLT system
# called tri2b
#TODO : Train triphone with aligned model
if [ $stage -le 5 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri1_only_words_ali_$expid
  mdl=$expdir/vocal/svtri2b_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le 6 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/svtri2b_$expid
  ali=$expdir/vocal/svtri2b_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    --use-graphs true $trainset $lm $mdl $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri2b_ali_$expid
  mdl=$expdir/vocal/svtri3b_$expid
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

lm=$datadir/lang_lyric
testset=$datadir/vocal/test_clean

#TODO : Decode using triphone model
if [ $stage -le 10 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/svtri1_only_words_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 11 ]; then
  # decode using triphone model (lda+mllt)
  mdl=$expdir/vocal/svtri2b_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 12 ]; then
  mdl=$expdir/vocal/svtri3b_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi
