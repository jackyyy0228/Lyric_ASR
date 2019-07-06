#!/bin/bash
numjob=4
lm=data/lang_lyric_exten
trainset=data/paper/train_clean_utt_fbank_mel_bin40
testset=data/paper/test_clean_utt_fbank_mel_bin40
egs_dir=exp/paper/nnet_fbank/egs/egs
exp_dir=exp/paper/nnet_fbank/layer7_400_100_epoch17_melbin_40/
mdl=$exp_dir/final.mdl

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;
. ./cmd.sh

bash steps/nnet2/train_more.sh \
  --num_epochs 5 \
  $mdl $egs_dir $exp_dir

tri=exp/paper/fmllr/tri3b_utt
utils/mkgraph.sh $lm\_test_tgsmall $tri $tri/graph_tgsmall || exit 1;
steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
  --feat-type "raw" \
  $tri/graph_tgsmall $testset $exp_dir/decode_test_clean_tgsmall_train_more || exit 1;
