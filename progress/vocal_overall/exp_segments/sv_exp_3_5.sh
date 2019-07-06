#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=10
expid=exp3

#TODO : Align to utterance-level file, all clips
if [ $stage -le 1 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/svtri3b_svtri1_1k_5k_$expid
  ali=$expdir/vocal/svtri3b_svtri1_1k_5k_ali_$expid
  steps/align_fmllr.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

if [ $stage -le 2 ]; then
  progress/vocal_overall/nnet2_vocal.sh $numjob $mdl $ali
fi
