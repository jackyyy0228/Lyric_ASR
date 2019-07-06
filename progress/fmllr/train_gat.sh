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
'''
if [ $stage -le 0 ]; then
  trainset=$datadir/vocal/words_train
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal_temp/labeled_mono_only_words
  steps/train_mono.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl || exit 1;
fi
if [ $stage -le 2 ]; then
  trainset=$datadir/vocal/genre_train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal_temp/labeled_mono_only_words
  ali=$expdir/vocal_temp/labeled_mono_ali_$expid
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi
if [ $stage -le 3 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal_temp2/labeled_mono_ali_$expid
  mdl=$expdir/vocal_temp2/labeled_tri1_$expid
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 $trainset $lm $ali $mdl || exit 1;
fi
if [ $stage -le 4 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal_temp/labeled_tri1_$expid
  ali=$expdir/vocal_temp/labeled_tri1_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi
if [ $stage -le 5 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal_temp/labeled_tri1_ali_$expid
  mdl=$expdir/vocal_temp/labeled_tri2b_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi
'''
#TODO : Align to utterance-level file, all clips
if [ $stage -le 6 ]; then
  trainset=$datadir/vocal/genre_train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal_temp/labeled_tri2b_$expid
  ali=$expdir/vocal_temp/gat_tri2b_ali
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
     $trainset $lm $mdl $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  trainset=$datadir/vocal/genre_train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal_temp/gat_tri2b_ali
  mdl=$expdir/vocal_temp/gat_tri3b
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

