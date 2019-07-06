#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

# This is p-norm neural net training, with the "fast" script, on top of adapted
# 40-dimensional features.

stage=3
train_stage=-10
use_gpu=false
numjob=10
expid=exp3
mdl=exp/genre/new_gat/tri3b_utt
ali=exp/vocal/tri3b_ali_all_clean_utt

. cmd.sh
. ./path.sh
. utils/parse_options.sh

if [ $stage -le 2 ]; then
  dataset=data/vocal/all_clean_utt
  lm=data/lang_lyric
  steps/align_fmllr.sh --nj $numjob --cmd "$train_cmd" \
    $dataset $lm $mdl $ali || exit 1;
fi

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
  dir=$expdir/vocal/gpu_pnorm_utt_exp1
else
  # with just 4 jobs this might be a little slow.
  num_threads=16
  parallel_opts="--num-threads $num_threads" 
  minibatch_size=128
  dir=$expdir/vocal/threads_pnorm_utt_exp1
fi

. ./cmd.sh
. utils/parse_options.sh

if [ ! -f $dir/final.mdl ]; then
  local/nnet2/train_pnorm_fast3.sh --stage $train_stage \
   --samples-per-iter 200000 \
   --parallel-opts "$parallel_opts" \
   --num-threads "$num_threads" \
   --minibatch-size "$minibatch_size" \
   --num-jobs-nnet 4 \
   --initial-learning-rate 0.01 --final-learning-rate 0.001 \
   --num-hidden-layers 2 \
   --pnorm-input-dim 800 --pnorm-output-dim 160 \
   --num-epochs 10 \
   --splice-width 4 \
   --cmd "$decode_cmd" \
    $datadir/vocal/ori_train_clean_utt $datadir/vocal/test_clean_utt $datadir/lang_lyric $ali $dir || exit 1
fi

if [ $stage -ge 1 ]; then
  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
    --transform-dir $mdl/decode_fmllr_test_clean_tgsmall \
    $mdl/graph_tgsmall $datadir/vocal/test_clean_utt $dir/decode_vocal_test_clean_tgsmall || exit 1;
  #steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_lyric_test_{tgsmall,tgmed} \
    #$datadir/vocal/test_clean $dir/decode_vocal_test_clean_{tgsmall,tgmed} || exit 1;
fi
: '
dir=$expdir/vocal/nnet5a_2l_tuned_exp7_3_$suffix
if [ ! -f $dir/final.mdl ]; then
  local/nnet2/train_pnorm_fast3.sh --stage $train_stage \
   --samples-per-iter 200000 \
   --parallel-opts "$parallel_opts" \
   --num-threads "$num_threads" \
   --minibatch-size "$minibatch_size" \
   --num-jobs-nnet 4 \
   --initial-learning-rate 0.01 --final-learning-rate 0.001 \
   --num-hidden-layers 2 \
   --pnorm-input-dim 800 --pnorm-output-dim 160 \
   --num-epochs 5 \
   --splice-width 4 \
   --cmd "$decode_cmd" \
    $datadir/vocal/ori_train_clean $datadir/vocal/test_clean $datadir/lang_lyric $ali $dir || exit 1
fi

if [ $stage -ge 1 ]; then
  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
    --transform-dir $mdl/decode_vocal_test_clean_tgsmall \
    $mdl/graph_tgsmall $datadir/vocal/test_clean $dir/decode_vocal_test_clean_tgsmall || exit 1;
  #steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_lyric_test_{tgsmall,tgmed} \
  #$datadir/vocal/test_clean $dir/decode_vocal_test_clean_{tgsmall,tgmed} || exit 1;
fi
'
exit 0;

