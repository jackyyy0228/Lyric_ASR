#!/bin/bash

# This is p-norm neural net training, with the "fast" script, on top of adapted
# 40-dimensional features.

stage=1
train_stage=-10
use_gpu=true
numjob=4
lm=data/lang_lyric_exten
mdl=exp/paper/fmllr/tri3b_utt
ali=exp/paper/nnet/tri3b_ali_all_clean_utt
trainset=data/paper/train_clean_utt
testset=data/paper/test_clean_utt

ali_s=exp/speech/tri4b_ali_clean_100
ali_v=$ali
egs_s=exp/speech/paper_nnet_egs2
egs_v=exp/paper/paper_nnet_egs2
mdl_s=exp/speech/threads_pnorm_accel_clean_100/100.mdl


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
  dir=exp/paper/nnet_from_speech/gpu_pnorm_multi_utt
else
  # with just 4 jobs this might be a little slow.
  num_threads=8
  parallel_opts="--num-threads $num_threads" 
  minibatch_size=128
  dir=exp/paper/nnet_from_speech/threads_pnorm_multi_utt
fi

. ./cmd.sh
. utils/parse_options.sh

if [ $stage -le 0 ]; then
  steps/nnet2/get_egs2.sh --cmd "$train_cmd" \
    data/speech/train_clean_100 $ali_s $egs_s
  local/nnet2/get_egs2_3.sh --cmd "$train_cmd" \
    $trainset $testset $ali_v $egs_v
fi

if [ ! -f $dir/1/final.mdl ]; then
  steps/nnet2/train_multilang2.sh --stage $train_stage \
   --parallel-opts "$parallel_opts" \
   --minibatch-size "$minibatch_size" \
   --num-jobs-nnet "5 10" \
   --initial-learning-rate 0.01 --final-learning-rate 0.001 \
   --num-epochs 1 \
   --max-models-combine 10 \
   --cmd "$decode_cmd" \
   $ali_s $egs_s $ali_v $egs_v $mdl_s $dir || exit 1
fi

if [ $stage -le 1 ]; then
  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
    --transform-dir $mdl/decode_fmllr_test_clean_tgsmall \
    $mdl/graph_tgsmall $testset $dir/1/decode_test_clean_tgsmall || exit 1;
  #steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_lyric_test_{tgsmall,tgmed} \
    #$datadir/vocal/test_clean $dir/decode_vocal_test_clean_{tgsmall,tgmed} || exit 1;
fi

exit 0;
