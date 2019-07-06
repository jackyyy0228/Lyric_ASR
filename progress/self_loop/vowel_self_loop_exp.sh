#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"



numjob=4
trainingdata=$datadir/paper/train_clean_utt
testingdata=$datadir/paper/test_clean_utt
lm=$datadir/lang_lyric_exten

mdl=$expdir/paper/vowel_loop/tri3b_utt2
rm -rf $mdl/final.mdl


#for ratio in 0.1 0.2 0.3 0.4 0.5 ; do
for ratio in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0; do
#for ratio in 0.1 0.2 0.3 0.5 0.6 0.7 0.8 0.9 1.00 1.05 1.1 1.15 1.2 ; do
  #result=./result/vowel_self_loop_state12.txt
  langmodel=$lm
#  gmm-add-vowel-loop $mdl/35.mdl $ratio $datadir/lang_lyric_exten/phones.txt \
#    $mdl/35_state12_$ratio.mdl
  rm -rf $mdl/final.mdl
  ln -s $mdl/35_$ratio.mdl $mdl/final.mdl

  rm -rf $mdl/graph_tgsmall
  utils/mkgraph.sh $langmodel\_test_tgsmall \
    $mdl $mdl/graph_tgsmall_$ratio
#  small=$mdl/decode_test_tgsmall_vowel_loop_state12_$ratio
#  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
#    $mdl/graph_tgsmall $testingdata \
#    $small || exit 1;
#    progress/cal_wer.sh $small >> $result
done
ln -s $mdl/35.mdl $mdl/final.mdl 
rm -rf $mdl/graph_tgsmall
#utils/mkgraph.sh $lm\_test_tgsmall \
#  $mdl $mdl/graph_tgsmall
