#!/bin/bash

# this script is a modified version of run_tdnn_5g.sh. It uses
# the new transition model and the python version of training scripts.

#ToDo: ivector


set -e

# configs for 'chain'
stage=0
train_stage=-15
get_egs_stage=-10
dir=exp/paper/nnet3/tdnn_5n

# training options
num_epochs=12
initial_effective_lrate=0.005
final_effective_lrate=0.0005
leftmost_questions_truncate=-1
max_param_change=2.0
final_layer_normalize_target=0.5
num_jobs_initial=2
num_jobs_final=4
minibatch_size=128
frames_per_eg=150
remove_egs=false

# End configuration section.
echo "$0 $@"  # Print the command line for logging

. cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

# The iVector-extraction and feature-dumping parts are the same as the standard
# nnet2 setup, and you can skip them by setting "--stage 4" if you have already
# run those things.

ali_dir=exp/paper/tri3b_ali_utt
trainingdata=data/paper/train_clean_utt
testingdata=data/paper/test_clean_utt
lang_ori=data/lang_lyric_exten
lang_new=data/lang_lyric_exten_5n
treedir=exp/paper/nnet3/tri4_5n_tree

#steps/align_si.sh --nj 4 --cmd "$train_cmd" \
#  $trainingdata $lang_ori exp/paper/tri3b_utt exp/paper/tri3b_ali_utt || exit 1;

tri3b=exp/paper/tri3b_utt
tri3b_lats=exp/paper/nnet3/tri3b_utt_lats

ivec_extractor=exp/paper/nnet_ivec_online/extractor
ivec_train=exp/paper/nnet_ivec_online/ivec_train
ivec_test=exp/paper/nnet_ivec_online/ivec_test

if [ $stage -le 3 ]; then
  progress/nnet3/run_ivector_common.sh --stage $stage --extractor $ivec_extractor \
    --ivec_train $ivec_train --ivec_test $ivec_test || exit 1;
fi
if [ $stage -le 4 ]; then
  # Get the alignments as lattices (gives the chain training more freedom).
  # use the same num-jobs as the alignments
  nj=$(cat $ali_dir/num_jobs) || exit 1;
  steps/align_fmllr_lats.sh --nj $nj --cmd "$train_cmd" $trainingdata \
    $lang_ori $tri3b $tri3b_lats
  rm $tri3b_lats/fsts.*.gz # save space
fi

if [ $stage -le 5 ]; then
  # Create a version of the lang/ directory that has one state per phone in the
  # topo file. [note, it really has two states.. the first one is only repeated
  # once, the second one has zero or more repeats.]
  rm -rf $lang_new
  cp -r $lang_ori $lang_new
  silphonelist=$(cat $lang_new/phones/silence.csl) || exit 1;
  nonsilphonelist=$(cat $lang_new/phones/nonsilence.csl) || exit 1;
  # Use our special topology... note that later on may have to tune this
  # topology.
  steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >$lang_new/topo
fi


if [ $stage -le 6 ]; then
  # Build a tree using our new topology.
  steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 \
    --leftmost-questions-truncate $leftmost_questions_truncate \
    --cmd "$train_cmd" 1200 $trainingdata $lang_new $ali_dir $treedir
fi

if [ $stage -le 7 ]; then
  mkdir -p $dir
  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $tri3b/tree |grep num-pdfs|awk '{print $2}')

  mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig
  input dim=50 name=ivector
  input dim=13 name=input

  # please note that it is important to have input layer with the name=input
  # as the layer immediately preceding the fixed-affine-layer to enable
  # the use of short notation for the descriptor
  fixed-affine-layer name=lda input=Append(-2,-1,0,1,2,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat

  # the first splicing is moved before the lda layer, so no splicing here
  # relu-renorm-layer name=tdnn1 dim=450
  relu-renorm-layer name=tdnn1 dim=450 input=Append(-1,0,1)
  relu-renorm-layer name=tdnn2 dim=450 input=Append(-2,-1,0,1)
  relu-renorm-layer name=tdnn3 dim=450 input=Append(-3,0,3)
  relu-renorm-layer name=tdnn4 dim=450 input=Append(-6,3,0)
  relu-renorm-layer name=tdnn5 dim=450 
  output-layer name=output dim=$num_targets max-change=1.5 
EOF
  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs
fi


if [ $stage -le 8 ]; then
 steps/nnet3/chain/train.py --stage $train_stage \
    --cmd "$decode_cmd" \
    --feat.online-ivector-dir $ivec_train \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.00005 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=200" \
    --egs.dir "$common_egs_dir" \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width $frames_per_eg \
    --trainer.num-chunk-per-minibatch $minibatch_size \
    --trainer.frames-per-iter 1000000 \
    --trainer.num-epochs $num_epochs \
    --trainer.optimization.num-jobs-initial $num_jobs_initial \
    --trainer.optimization.num-jobs-final $num_jobs_final \
    --trainer.optimization.initial-effective-lrate $initial_effective_lrate \
    --trainer.optimization.final-effective-lrate $final_effective_lrate \
    --trainer.max-param-change $max_param_change \
    --cleanup.remove-egs true \
    --feat-dir $trainingdata \
    --tree-dir $treedir \
    --lat-dir $tri3b_lats \
    --dir $dir
fi


if [ $stage -le 10 ]; then
  # Note: it might appear that this $lang directory is mismatched, and it is as
  # far as the 'topo' is concerned, but this script doesn't read the 'topo' from
  # the lang directory.
  utils/mkgraph.sh --self-loop-scale 1.0 $lang_oir $dir $dir/graph
  steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
    --scoring-opts "--min-lmwt 1" \
    --nj 10 --cmd "$decode_cmd" \
    --online-ivector-dir $ivec_test \
    $dir/graph $testingdata $dir/decode || exit 1;
fi
wait;
exit 0;
