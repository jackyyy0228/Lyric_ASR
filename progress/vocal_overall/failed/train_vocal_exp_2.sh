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
expid=exp2

# run_5a_clean_100.sh

#TODO : Split word-level labeled file
if [ $stage -le -1 ]; then
  audio=$rootdir/vocal_data/words/words_train
  trainset=$datadir/vocal/words_train
  results=$expdir/make_mfcc/vocal/words_train
  mfcc=$mfccdir/vocal
  local/vocaldata_prep.sh $audio $trainset || exit 1;
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
fi

# train a monophone system
# called mono
#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le 0 ]; then
  trainset=$datadir/vocal/words_train
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/labeled_mono_only_words
  steps/train_mono.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl || exit 1;
fi

# Spit data into 30utts, 100utts subsets
if [ $stage -le -2 ]; then
  audio=$rootdir/vocal_data/train_clean
  trainset=$datadir/vocal/train_clean
  results=$expdir/make_mfcc/vocal/train_clean
  mfcc=$mfccdir/vocal
  local/vocaldata_prep.sh $audio $trainset || exit 1;
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;

  utils/subset_data_dir.sh $datadir/vocal/train_clean 30 $datadir/vocal/train_clean_30utts
  utils/subset_data_dir.sh $datadir/vocal/train_clean 100 $datadir/vocal/train_clean_100utts
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le 2 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/labeled_mono_only_words
  ali=$expdir/vocal/labeled_mono_ali_$expid
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train a first delta + delta-delta triphone system
# called tri1
#TODO : Train triphone with aligned model
if [ $stage -le 3 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/labeled_mono_ali_$expid
  mdl=$expdir/vocal/labeled_tri1_$expid
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le 4 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/labeled_tri1_$expid
  ali=$expdir/vocal/labeled_tri1_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train an LDA+MLLT system
# called tri2b
#TODO : Train triphone with aligned model
if [ $stage -le 5 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/labeled_tri1_ali_$expid
  mdl=$expdir/vocal/labeled_tri2b_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le 6 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/labeled_tri2b_$expid
  ali=$expdir/vocal/labeled_tri2b_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    --use-graphs true $trainset $lm $mdl $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/labeled_tri2b_ali_$expid
  mdl=$expdir/vocal/labeled_tri3b_$expid
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le 8 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/labeled_tri3b_$expid
  ali=$expdir/vocal/labeled_tri3b_ali_$expid
  steps/align_fmllr.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train LDA+MLLT+SAT
# on the whole utterances
# called tri4b
#TODO : Train triphone with aligned model
if [ $stage -le 9 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/labeled_tri3b_ali_$expid
  mdl=$expdir/vocal/labeled_tri4b_$expid
  steps/train_sat.sh --cmd "$train_cmd" 4200 40000 \
    $trainset $lm $ali $mdl || exit 1;
fi
