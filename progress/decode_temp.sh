#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"


suffix=utt

numjob=4
trainingdata=$datadir/paper/train_clean_$suffix
testingdata=$datadir/paper/test_clean_$suffix
lm=$datadir/lang_lyric_exten


# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
for model in mono_utt ; do
  result=./result/train_flow.txt
  mdl=$expdir/paper/$model
  langmodel=$lm
  utils/mkgraph.sh --mono $langmodel\_test_tgsmall \
    $mdl $mdl/graph_tgsmall
  small=$mdl/decode_fmllr_test_clean_tgsmall
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $mdl/graph_tgsmall $testingdata \
    $small || exit 1;
    progress/cal_wer.sh $small >> $result
done
