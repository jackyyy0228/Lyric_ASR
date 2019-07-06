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

#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le 1 ]; then
  # decode using monophone model
  mdl=$expdir/vocal/labeled_mono_only_words
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh --mono \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 2 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/labeled_tri1_30utts
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  #progress/cal_wer.sh $results\_{tgsmall,tgmed}
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tglarge} $testset $result\_{tgsmall,tglarge} || exit 1;
  #progress/cal_wer.sh $results\_{tgsmall,tglarge}
fi

#TODO : Train triphone with aligned model
if [ $stage -le 5 ]; then
  # decode using triphone model (lda+mllt)
  mdl=$expdir/vocal/labeled_tri2b_100utts
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  #progress/cal_wer.sh $results\_{tgsmall,tgmed}
  : '
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tglarge} $testset $result\_{tgsmall,tglarge} || exit 1;
  '
  #progress/cal_wer.sh $results\_{tgsmall,tglarge}
fi

#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  mdl=$expdir/vocal/labeled_tri3b_100utts
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  #progress/cal_wer.sh $results\_{tgsmall,tgmed}
  : '
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tglarge} $testset $result\_{tgsmall,tglarge} || exit 1;
  '
  #progress/cal_wer.sh $results\_{tgsmall,tglarge}
fi

#TODO : Train triphone with aligned model
if [ $stage -le 9 ]; then
  mdl=$expdir/vocal/labeled_tri4b
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  #progress/cal_wer.sh $results\_{tgsmall,tgmed}
  :'
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tglarge} $testset $result\_{tgsmall,tglarge} || exit 1;
  #progress/cal_wer.sh $results\_{tgsmall,tglarge}
  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,fglarge} $testset $result\_{tgsmall,fglarge} || exit 1;
  '
  #progress/cal_wer.sh $results\_{tgsmall,fglarge}
fi

exit 0;
