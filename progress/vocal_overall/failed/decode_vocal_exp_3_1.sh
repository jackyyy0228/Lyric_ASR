#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=4
expid=exp3

lm=$datadir/lang_lyric
testset=$datadir/vocal/test_clean


#TODO : Train triphone with aligned model
if [ $stage -le 2 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/labeled_tri1_$expid\_1k\_5k
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
if [ $stage -le 3 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/labeled_tri1_$expid\_1p5k\_8k
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
if [ $stage -le 4 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/labeled_tri1_$expid\_2p2k\_12k
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le 1 ]; then
  # decode using monophone model
  mdl=$expdir/genre/vmono_all
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh --mono \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result || exit 1;
fi
