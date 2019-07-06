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

lm=$datadir/lang_lyric
testset=$datadir/vocal/test_clean
# run_5a_clean_100.sh

# train a monophone system
# called mono
#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le 0 ]; then
  trainset=$datadir/vocal/words_train
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/stri4b_ali_only_words_exp2
  mdl=$expdir/vocal/svmono_only_words_$expid
  progress/vocal_overall/train_mono_apply_ali.sh \
    --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le 1 ]; then
  # decode using monophone model
  mdl=$expdir/vocal/svmono_only_words_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  #utils/mkgraph.sh --mono \
  #  $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result || exit 1;
fi

# train a monophone system
# called mono
#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le 2 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/stri4b_ali_exp1
  mdl=$expdir/vocal/svmono_$expid
  progress/vocal_overall/train_mono_apply_ali.sh \
    --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train monophone with lebeled words, with phone-level equal-aligned
if [ $stage -le 3 ]; then
  # decode using monophone model
  mdl=$expdir/vocal/svmono_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh --mono \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result || exit 1;
fi
