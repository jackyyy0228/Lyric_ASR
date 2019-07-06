#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=0
suffix=utt

numjob=4
trainingdata=$datadir/paper/train_clean_$suffix
testingdata=$datadir/paper/test_clean_$suffix
lm=$datadir/lang_lyric_exten

if [ $stage -le 0 ]; then
  tri3bexp=$expdir/paper/fmllr/tri3b_utt
  ali=$expdir/paper/fmllr/tri3b_ali_utt
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
     $trainingdata $lm $tri3bexp $ali || exit 1;
fi
