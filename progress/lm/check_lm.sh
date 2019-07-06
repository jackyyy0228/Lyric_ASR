#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

lm=$datadir/$2

trainingdata=$datadir/paper/train_clean_utt
testingdata=$datadir/paper/test_clean_utt
numjob=4

mkdir -p $expdir/paper/lm

for lm in lang_lyric lang_lyric_exten lang_nosp;
do
  result=./paper_lm_result.txt
  langmodel=$datadir/$lm
  orimdl=$expdir/paper/tri3b_utt
  mdl=$expdir/paper/lm/tri3b_utt_$lm
  cp -rf $orimdl $mdl
  rm -rf $mdl/graph_tgsmall

  utils/mkgraph.sh $langmodel\_test_tgsmall \
    $mdl $mdl/graph_tgsmall
  small=$mdl/decode_fmllr_test_clean_tgsmall
  mid=$mdl/decode_fmllr_test_clean_tgmed
  if [ ! -f $small/lat.1.gz ]; then
    steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
      $mdl/graph_tgsmall $testingdata \
      $small || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $langmodel\_test_{tgsmall,tgmed} \
      $testingdata $small $mid  || exit 1;
    progress/cal_wer.sh $small >> $result
    progress/cal_wer.sh $mid >> $result
  fi
done
