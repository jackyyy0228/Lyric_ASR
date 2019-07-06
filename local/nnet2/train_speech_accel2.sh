#!/bin/bash

stage=1
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
  dir=exp/speech/gpu_pnorm_accel_clean_100
else
  # with just 4 jobs this might be a little slow.
  num_threads=16
  parallel_opts="--num-threads $num_threads" 
  minibatch_size=128
  dir=exp/speech/threads_pnorm_accel_clean_100
fi

. ./cmd.sh
. utils/parse_options.sh

if [ ! -f $dir/final.mdl ]; then
  steps/nnet2/train_pnorm_accel2.sh --stage $train_stage \
   --samples-per-iter 400000 \
   --parallel-opts "$parallel_opts" \
   --num-threads "$num_threads" \
   --minibatch-size "$minibatch_size" \
   --num-jobs-initial 10 --num-jobs-final 10 \
   --initial-effective-lrate 0.005 --final-effective-lrate 0.0005 \
   --num-hidden-layers 4 \
   --pnorm-input-dim 2000 --pnorm-output-dim 400 \
   --cmd "$decode_cmd" \
    data/speech/train_clean_100 data/lang exp/speech/tri4b_ali_clean_100 $dir || exit 1
fi

if [ $stage -ge 1 ]; then
  for test in test_clean test_other dev_clean dev_other; do
    steps/nnet2/decode.sh --nj 10 --cmd "$decode_cmd" \
        --transform-dir exp/speech/tri4b/decode_tgsmall_$test \
        exp/speech/tri4b/graph_tgsmall data/speech/$test $dir/decode_tgsmall_$test || exit 1;
  done
fi

exit 0;

