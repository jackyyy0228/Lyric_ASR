#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

# This is p-norm neural net training, with the "fast" script, on top of adapted
# 40-dimensional features.

stage=2
train_stage=-10
use_gpu=false
numjob=12
expid=exp3
suffix=svtri3b_svtri1_1k_5k
mdl=$expdir/vocal/svtri3b_svtri1_1k_5k_$expid
ali=$expdir/vocal/svtri3b_svtri1_1k_5k_all_clean_ali_$expid

. cmd.sh
. ./path.sh
. utils/parse_options.sh

if [ $stage -ge 1 ]; then
  dir=$expdir/vocal/nnet5a_2l_tuned_exp6_3_$suffix
  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
    --transform-dir $mdl/decode_vocal_test_clean_tgsmall \
    --iter 18\
    $mdl/graph_tgsmall $datadir/vocal/test_clean $dir/decode_18_vocal_test_clean_tgsmall || exit 1;

  dir=$expdir/vocal/nnet5a_2l_tuned_exp7_3_$suffix
  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
    --transform-dir $mdl/decode_vocal_test_clean_tgsmall \
    --iter 15 \
    $mdl/graph_tgsmall $datadir/vocal/test_clean $dir/decode_15_vocal_test_clean_tgsmall || exit 1;
fi

exit 0;

