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
expid=exp3

lm=$datadir/lang_lyric
trainset=$datadir/vocal/ori_train_clean
testset=$datadir/vocal/test_clean

if [ $stage -le 1 ]; then
  ali=$expdir/vocal/svtri3b_svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri4b_svtri1_1k_5k_$expid
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

if [ $stage -le 2 ]; then
  mdl=$expdir/vocal/svtri4b_svtri1_1k_5k_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

if [ $stage -le 3 ]; then
  ali=$expdir/vocal/svtri3b_svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri4b_3k_18k_svtri1_1k_5k_$expid
  steps/train_sat.sh --cmd "$train_cmd" 3000 18000 \
    $trainset $lm $ali $mdl || exit 1;
fi

if [ $stage -le 4 ]; then
  mdl=$expdir/vocal/svtri4b_3k_18k_svtri1_1k_5k_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi
