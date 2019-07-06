#!/bin/bash
#go through the best path of exp3
#but replace with speech langauge model
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=12
expid=exp5

lm=$datadir/lang_nosp
testset=$datadir/vocal/test_clean
trainset=$datadir/vocal/ori_train_clean

if [ $stage -le 1 ]; then
  mdl=$expdir/vocal/svmono_exp3
  ali=$expdir/vocal/svmono_ali_$expid
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

if [ $stage -le 2 ]; then
  ali=$expdir/vocal/svmono_ali_$expid
  mdl=$expdir/vocal/svtri1_$expid\_1k\_5k
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    1000 5000 $trainset $lm $ali $mdl || exit 1;
fi

if [ $stage -le 3 ]; then
  mdl=$expdir/vocal/svtri1_exp3\_1k\_5k
  ali=$expdir/vocal/svtri1_1k_5k_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

if [ $stage -le 4 ]; then
  ali=$expdir/vocal/svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri2b_svtri1_1k_5k_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

if [ $stage -le 5 ]; then
  mdl=$expdir/vocal/svtri2b_svtri1_1k_5k_exp3
  ali=$expdir/vocal/svtri2b_svtri1_1k_5k_ali_$expid
  steps/align_si.sh --nj 8 --cmd "$train_cmd" \
    --use-graphs true $trainset $lm $mdl $ali || exit 1;
fi

if [ $stage -le 6 ]; then
  ali=$expdir/vocal/svtri2b_svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri3b_svtri1_1k_5k_$expid
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

if [ $stage -le 7 ]; then
  mdl=$expdir/vocal/svtri3b_svtri1_1k_5k_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

if [ $stage -le 8 ]; then
  mdl=$expdir/vocal/svtri2b_svtri1_1k_5k_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

if [ $stage -le 9 ]; then
  mdl=$expdir/vocal/svtri1_$expid\_1k\_5k
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi
