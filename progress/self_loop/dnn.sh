#!/bin/bash


. cmd.sh
. ./path.sh
. utils/parse_options.sh

numjob=4
lm=data/lang_lyric_exten
mdl=exp/paper/vowel_loop/tri3b_utt2
trainset=data/paper/train_clean_utt
testset=data/paper/test_clean_utt
dir=exp/paper/nnet/threads_pnorm_utt_th8_nj10_mb128_nj4_ep15
for ratio in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0; do
  result=./result/vowel_self_loop_dnn.txt
#  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" \
#    --transform-dir $mdl/decode_test_tgsmall_vowel_loop_1.0 \
#    $mdl/graph_tgsmall_$ratio $testset $dir/decode_test_clean_tgsmall_$ratio || exit 1;
  progress/cal_wer.sh $dir/decode_test_clean_tgsmall_$ratio >> $result
done
