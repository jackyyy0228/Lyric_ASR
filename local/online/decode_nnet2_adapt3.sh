#!/bin/bash

# note: see the newer, better script run_nnet2_wsj_joint.sh

# This script assumes you have previously run the WSJ example script including
# the optional part local/online/run_online_decoding_nnet2.sh.  It builds a
# neural net for online decoding on top of the network we previously trained on
# WSJ, by keeping everything but the last layer of that network and then
# training just the last layer on our data.  We then train the whole thing.

stage=0
set -e

train_stage=-10
use_gpu=false
numjob=12
. cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if $use_gpu; then
  if ! cuda-compiled; then
    cat <<EOF && exit 1 
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA 
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.  Otherwise, call this script with --use-gpu false
EOF
  fi
  parallel_opts="-l gpu=1" 
  num_threads=1
  minibatch_size=512
  dir=exp/vocal/nnet2_online/nnet_a
  trainfeats=exp/vocal/nnet2_online/speech_activations_train
  # later we'll change the script to download the trained model from kaldi-asr.org.
  srcdir=../../wsj/s5/exp/nnet2_online/nnet_a_gpu_online
else
  # Use 4 nnet jobs just like run_4d_gpu.sh so the results should be
  # almost the same, but this may be a little bit slow.
  num_threads=16
  minibatch_size=128
  parallel_opts="-pe smp $num_threads" 
  dir=exp/vocal/nnet2_online/nnet_a3
  trainfeats=exp/vocal/nnet2_online/activations_train_from_speech_to_vocal
  testfeats=exp/vocal/nnet2_online/activations_test_from_speech_to_vocal
  srcdir=exp/speech/nnet2_online/nnet_ms_a_online
fi

if [ $stage -le 9 ]; then
  steps/online/nnet2/prepare_online_decoding.sh --iter 2 \
    data/lang_lyric $srcdir/ivector_extractor \
    ${dir}_combined ${dir}_combined_2_online || exit 1;
  # do the online decoding on top of the retrained _combined_online model, and
  # also the per-utterance version of the online decoding.
  steps/online/nnet2/decode.sh --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
    exp/vocal/svtri3b_svtri1_1k_5k_exp3/graph_tgsmall data/vocal/test_clean ${dir}_combined_2_online/decode &
  steps/online/nnet2/decode.sh --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
    --per-utt true exp/vocal/svtri3b_svtri1_1k_5k_exp3/graph_tgsmall data/vocal/test_clean ${dir}_combined_2_online/decode_per_utt || exit 1;
  wait
fi



exit 0;
