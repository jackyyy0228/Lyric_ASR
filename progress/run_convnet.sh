#!/bin/bash

# 2015 Xingyu Na
# This script runs on the full training set, using ConvNet setup on top of
# fbank features, on GPU. The ConvNet has four hidden layers, two convolutional
# layers and two affine transform layers with ReLU nonlinearity.
# Convolutional layer [1]:
#   convolution1d, input feature dim is 36, filter dim is 7, output dim is
#   30, 128 filters are used
#   maxpooling, 3-to-1 maxpooling, input dim is 30, output dim is 10
# Convolutional layer [2]:
#   convolution1d, input feature dim is 10, filter dim is 4, output dim is
#   7, 256 filters are used
# Affine transform layers [3-4]:
#   affine transform with ReLU nonlinearity.

temp_dir=
hiddensize=$1
numf1=$2
numf2=$3
epoch=$4
dir=exp/nnet2_cnn/mel40/wo_mixup/epoch${epoch}_hidden_size_${hiddensize}_numf1_${numf1}_numf2_${numf2}_lr0.0005
stage=-5
train_original=data/paper/train_clean_utt
test_original=data/paper/test_clean_utt
trainset=data/paper/train_clean_utt_fbank_mel_bin40
testset=data/paper/test_clean_utt_fbank_mel_bin40
egs_dir=exp/nnet2_cnn/egs
. ./cmd.sh
. ./path.sh

. utils/parse_options.sh

parallel_opts="--gpu 1"  # This is suitable for the CLSP network, you'll
                         # likely have to change it.

# Make the FBANK features

( 
  if [ ! -f $dir/final.mdl ]; then
    steps/nnet2/train_convnet_accel3.sh --parallel-opts "$parallel_opts" \
      --cmd "$decode_cmd" --stage $stage \
      --num-threads 1 --minibatch-size 512 \
      --samples-per-iter 300000 \
      --num-epochs $epoch --delta-order 2 \
      --initial-effective-lrate 0.0005 --final-effective-lrate 0.00001 \
      --num-jobs-initial 2 --num-jobs-final 2 --splice-width 5 \
      --hidden-dim $hiddensize --num-filters1 $numf1 --patch-dim1 8 --pool-size 3 \
      --num-filters2 $numf2 --patch-dim2 4 \
      --egs_dir $egs_dir --cleanup false \
      $trainset data/lang_lyric_exten exp/paper/tri3b_ali_utt $dir || exit 1;
  fi
  cp $egs_dir/cmvn_opts $dir/
  cp $egs_dir/delta_order $dir/
  steps/nnet2/decode.sh --cmd "$decode_cmd" --nj 4 \
    --config conf/decode.config \
    exp/paper/tri3b_utt/graph_tgsmall $testset \
    $dir/decode || exit 1;
)
