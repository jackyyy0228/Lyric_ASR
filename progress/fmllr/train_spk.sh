#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=-10
numjob=5
expid=exp2




#TODO : Align to utterance-level file, all clips
if [ $stage -le 6 ]; then
  trainset=$datadir/vocal_spk/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal_temp/labeled_tri2b_$expid
  ali=$expdir/vocal_temp/spk_tri2b_ali
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
     $trainset $lm $mdl $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  trainset=$datadir/vocal_spk/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal_temp/spk_tri2b_ali
  mdl=$expdir/vocal_temp/spk_tri3b
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

