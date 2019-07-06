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

lm=$datadir/lang_lyric
testset=$datadir/vocal/test_clean

if [ $stage -le 0 ]; then
  audio=$rootdir/vocal_data/test_clean
  trainset=$datadir/vocal/test_clean
  results=$expdir/make_mfcc/vocal/test_clean
  mfcc=$mfccdir/vocal
  local/vocaldata_prep.sh $audio $trainset || exit 1;
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
fi

#TODO : decode with triphone model
if [ $stage -le 3 ]; then
  mdl=$expdir/speech/tri4b
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  #utils/mkgraph.sh \
  #  $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  progress/cal_wer.sh $results\_{tgsmall,tgmed} >> tmp_wer.txt
fi

#TODO : decode with nnet2
if [ $stage -le 5 ]; then
  premdl=$expdir/speech/tri4b
  pregraph=$premdl/graph_tgsmall
  preresult=$premdl/decode_vocal_test_clean
  mdl=$expdir/speech/nnet5a_clean_100_gpu_2
  result=$mdl/decode_vocal_test_clean
  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
    --transform-dir $preresult\_tgsmall \
    $pregraph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  progress/cal_wer.sh $results\_tgsmall >>tmp_wer.txt
  progress/cal_wer.sh $results\_tgmed >>tmp_wer.txt
fi

exit 0;
