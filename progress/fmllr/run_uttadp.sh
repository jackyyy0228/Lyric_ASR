#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=-8
numjob=1 
expid=exp2
trainingdata=$datadir/vocal/uttadp_train_clean
testingdata=$datadir/vocal/uttadp_test_clean


for cleanset in train_clean test_clean 
do
  audio=$rootdir/vocal_data/$cleanset
  trainset=$datadir/vocal/uttadp_$cleanset
  results=$expdir/make_mfcc/vocal/uttadp_$cleanset
  mfcc=$mfccdir/vocal
  local/uttadp_data_prep.sh $audio $trainset || exit 1;
  old_steps_and_utils/steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    $trainset $results $mfcc || exit 1;
  old_steps_and_utils/steps/compute_cmvn_stats.sh \
    $trainset $results $mfcc || exit 1;
done


#TODO : Align to utterance-level file, all clips
if [ $stage -le 6 ]; then
  tri2bexp=$expdir/vocal/svtri2b_svtri1_1k_5k_exp3/
  lm=$datadir/lang_lyric
  ali=$expdir/genre/new_gat/tri2b_ali_utt
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
     $trainingdata $lm $tri2bexp $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  tri2bexp=$expdir/vocal/svtri2b_svtri1_1k_5k_exp3/
  lm=$datadir/lang_lyric
  ali=$expdir/genre/new_gat/tri2b_ali_utt
  mdl=$expdir/genre/new_gat/tri3b_utt
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainingdata $lm $ali $mdl || exit 1;
fi

if [ $stage -le 8 ]; then
  result=./result.txt
  mdl=$expdir/genre/new_gat/tri3b_utt
  langmodel=$datadir/lang_lyric

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
fi
