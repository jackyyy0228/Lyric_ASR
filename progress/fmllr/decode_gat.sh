#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=7
numjob=5
expid=exp2

lm=$datadir/lang_lyric
testset=$datadir/vocal/genre_test_clean





#TODO : Train triphone with aligned model
'''
if [ $stage -le 7 ]; then
  mdl=$expdir/vocal_temp/gat_tri3b
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_genre_test_clean
  testset=$datadir/vocal/genre_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  progress/cal_wer.sh $result\_tgsmall >> re.txt
  progress/cal_wer.sh $result\_tgmed >> re.txt
fi
'''
for cleanset in genre_test_clean_spk
do
  audio=$rootdir/vocal_data/$cleanset
  trainset=$datadir/vocal/$cleanset
  results=$expdir/make_mfcc/vocal/$cleanset
  mfcc=$mfccdir/vocal
  local/vocaldata_prep_spk.sh $audio $trainset || exit 1;
  old_steps_and_utils/steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  old_steps_and_utils/steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
done

for cleanset in genre_test_clean_spk
do
  audio=$rootdir/vocal_data/$cleanset
  trainset=$datadir/vocal/genre_test_clean_song
  results=$expdir/make_mfcc/vocal/genre_test_clean_song
  mfcc=$mfccdir/vocal
  local/vocaldata_prep.sh $audio $trainset || exit 1;
  old_steps_and_utils/steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  old_steps_and_utils/steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
done

if [ $stage -le 7 ]; then
  mdl=$expdir/vocal_temp/spk_tri3b
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_genre_test_clean_spk
  testset=$datadir/vocal/genre_test_clean_spk
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  progress/cal_wer.sh $result\_tgsmall >> re.txt
  progress/cal_wer.sh $result\_tgmed >> re.txt
fi

#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  mdl=$expdir/vocal/labeled_tri3b_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_genre_test_clean_song
  testset=$datadir/vocal/genre_test_clean_song
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
  progress/cal_wer.sh $result\_tgsmall >> re.txt
  progress/cal_wer.sh $result\_tgmed >> re.txt
fi
