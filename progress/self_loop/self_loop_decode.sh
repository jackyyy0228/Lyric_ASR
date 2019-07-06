#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <stage> "
  echo "e.g.: $0 3 "
  exit 1
fi

stage=$1
suffix=utt
numjob=4
trainingdata=$datadir/paper/train_clean_utt
testingdata=$datadir/paper/test_clean_utt
lm=$datadir/lang_lyric

#TODO : Train triphone with aligned model
for scale in 0.4 0.5 0.6 0.7 0.8 0.9 1; do
  if [ $stage -le 2 ]; then
    result=./paper_scale_lyric_decode.txt
    orimdl=$expdir/lm/tri3b_lang_lyric
    mdl=$expdir/paper/selfloop_decode/tri3b_lyric_$scale
    cp -rf $orimdl $mdl
    #rm -rf $mdl/graph_tgsmall
    langmodel=$lm
    utils/mkgraph.sh --self-loop-scale $scale $langmodel\_test_tgsmall \
      $mdl $mdl/graph_tgsmall
    small=$mdl/decode_fmllr_test_clean_tgsmall
    rm -rf $small
    steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
      $mdl/graph_tgsmall $testingdata \
      $small || exit 1;
    progress/cal_wer.sh $small >> $result
  fi
done
