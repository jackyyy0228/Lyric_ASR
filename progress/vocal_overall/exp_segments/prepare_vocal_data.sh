#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=-1
numjob=10

# run_5a_clean_100.sh

#TODO : Split word-level labeled file
if [ $stage -le -1 ]; then
  audio=$rootdir/vocal_data/train_clean
  trainset=$datadir/vocal/ori_train_clean
  results=$expdir/make_mfcc/vocal/ori_train_clean
  mfcc=$mfccdir/vocal
  local/vocaldata_prep.sh $audio $trainset || exit 1;
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
fi
