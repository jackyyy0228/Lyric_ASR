#!/bin/bash

storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
# for nnet2
expdir=/data1/hao246/singing-voice-recog/exp
nnet2expdir=/data/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc
# This is p-norm neural net training, with the "fast" script, on top of adapted
# 40-dimensional features.


stage=2
train_stage=-10
use_gpu=true

. cmd.sh
. ./path.sh
. utils/parse_options.sh


if $use_gpu; then
  if ! cuda-compiled; then
    cat <<EOF && exit 1 
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA 
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
  fi
  parallel_opts="--gpu 1"
  num_threads=1
  minibatch_size=512
  dir=$nnet2expdir/speech/nnet5a_clean_100_gpu
else
  # with just 4 jobs this might be a little slow.
  num_threads=16
  parallel_opts="--num-threads $num_threads" 
  minibatch_size=128
  dir=$nnet2expdir/speech/nnet5a_clean_100
fi

. ./cmd.sh
. utils/parse_options.sh

if [ ! -f $dir/final.mdl ]; then
  steps/nnet2/train_pnorm_fast.sh --stage $train_stage \
   --samples-per-iter 400000 \
   --parallel-opts "$parallel_opts" \
   --num-threads "$num_threads" \
   --minibatch-size "$minibatch_size" \
   --num-jobs-nnet 4  --mix-up 8000 \
   --initial-learning-rate 0.01 --final-learning-rate 0.001 \
   --num-hidden-layers 4 \
   --pnorm-input-dim 2000 --pnorm-output-dim 400 \
   --cmd "$decode_cmd" \
    $datadir/speech/train_clean_100 $datadir/lang $expdir/speech/tri4b_ali_clean_100 $dir || exit 1
fi

if [ $stage -ge 1 ]; then
  #utils/mkgraph.sh \
  #  $datadir/lang_test_tgsmall $expdir/speech/tri4b $expdir/speech/tri4b/graph_tgsmall || exit 1;
  for test in test_clean test_other dev_clean dev_other; do
    steps/decode_fmllr.sh --nj 10 --cmd "$decode_cmd" \
      $expdir/speech/tri4b/graph_tgsmall $datadir/speech/$test \
      $expdir/speech/tri4b/decode_tgsmall_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tgmed} \
      $datadir/speech/$test $expdir/speech/tri4b/decode_{tgsmall,tgmed}_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tglarge} \
      $datadir/speech/$test $expdir/speech/tri4b/decode_{tgsmall,tglarge}_$test || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,fglarge} \
      $datadir/speech/$test $expdir/speech/tri4b/decode_{tgsmall,fglarge}_$test || exit 1;
  done
  for test in test_clean test_other dev_clean dev_other; do
    steps/nnet2/decode.sh --nj 10 --cmd "$decode_cmd" \
        --transform-dir $expdir/speech/tri4b/decode_tgsmall_$test \
        $expdir/speech/tri4b/graph_tgsmall $datadir/speech/$test $dir/decode_tgsmall_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tgmed} \
        $datadir/speech/$test $dir/decode_{tgsmall,tgmed}_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
        --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tglarge} \
        $datadir/speech/$test $dir/decode_{tgsmall,tglarge}_$test || exit 1;
    steps/lmrescore_const_arpa.sh \
        --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,fglarge} \
        $datadir/speech/$test $dir/decode_{tgsmall,fglarge}_$test || exit 1;
  done
fi

exit 0;

