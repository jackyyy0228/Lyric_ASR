#/bin/bash

# This is p-norm neural net training, with the "fast" script, on top of adapted
# 40-dimensional features.

stage=1
train_stage=-10
use_gpu=false
numjob=4
lm=data/lang_lyric_exten
mdl=exp/paper/fmllr/tri3b_utt
ali=exp/paper/nnet/tri3b_ali_all_clean_utt
trainset=data/paper/train_clean_utt
testset=data/paper/test_clean_utt
start=`date +%s`
dir=exp/paper/nnet_valid/threads_pnorm_utt_400_80_valid10e5
. cmd.sh
. ./path.sh
. utils/parse_options.sh
for iter in 5 10 15 20 25 final ; do
  if [ ! -d $mdl/graph_tgsmall ]; then
    utils/mkgraph.sh $lm\_test_tgsmall $mdl $mdl/graph_tgsmall || exit 1;
  fi
  steps/nnet2/decode.sh --nj $numjob --cmd "$decode_cmd" --iter $iter \
    --transform-dir $mdl/decode_fmllr_test_clean_tgsmall \
    $mdl/graph_tgsmall $testset $dir/decode_test_clean_tgsmall_$iter || exit 1;
done

end=`date +%s`

runtime=$((end-start))
