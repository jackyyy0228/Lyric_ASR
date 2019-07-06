#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=8
expid=exp3

# train a monophone system
# called mono
#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le -2 ]; then
  trainset=$datadir/vocal/words_train
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/labeled_mono_only_words
  steps/train_mono.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl || exit 1;
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le -1 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/labeled_mono_only_words
  ali=$expdir/vocal/labeled_mono_ali_exp2
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train a first delta + delta-delta triphone system
# called tri1
#TODO : Train triphone with aligned model
if [ $stage -le 0 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/labeled_mono_ali_exp2
  mdl=$expdir/vocal/labeled_tri1_$expid\_1k\_5k
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    1000 5000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 1 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/labeled_mono_ali_exp2
  mdl=$expdir/vocal/labeled_tri1_$expid\_1p5k\_8k
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    1500 8000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 2 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/labeled_mono_ali_exp2
  mdl=$expdir/vocal/labeled_tri1_$expid\_2p2k\_12k
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2200 12000 $trainset $lm $ali $mdl || exit 1;
fi
