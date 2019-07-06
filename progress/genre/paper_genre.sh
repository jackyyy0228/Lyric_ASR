#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"
suffix=utt
numjob=4
stage=10
for genre in pop electronic hiphop rnb_soul rock; do 
  trainingdata=$datadir/paper/genre/$genre\_train_clean
  testingdata=$datadir/paper/test_clean_utt
  lm=$datadir/lang_lyric_exten
  mdl=$expdir/paper/genre/tri3b_$genre
  small=$mdl/decode_fmllr_test_clean_tgsmall
  result=result/genre.txt
  progress/cal_wer.sh $small >> $result
  python pyutils/cal_wer_map.py $small/utt_wer >> $result
  if [ $stage -le 0 ]; then
    tri2bexp=$expdir/paper/tri2b_utt
    ali=$expdir/paper/genre/tri2b_ali_$genre
    steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
       $trainingdata $lm $tri2bexp $ali || exit 1;
  fi
  # train LDA+MLLT+SAT
  # called tri3b
  #TODO : Train triphone with aligned model
  if [ $stage -le 1 ]; then
    ali=$expdir/paper/genre/tri2b_ali_$genre
    mdl=$expdir/paper/genre/tri3b_$genre
    steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
      $trainingdata $lm $ali $mdl || exit 1;
  fi
  if [ $stage -le 2 ]; then
    result=result/genre.txt
    mdl=$expdir/paper/genre/tri3b_$genre
    langmodel=$lm

    utils/mkgraph.sh $langmodel\_test_tgsmall \
      $mdl $mdl/graph_tgsmall
    small=$mdl/decode_fmllr_test_clean_tgsmall
    if [ ! -f $small/lat.1.gz ]; then
      steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
        $mdl/graph_tgsmall $testingdata \
        $small || exit 1;
        progress/cal_wer_genre.sh $small >> $result
        python pyutils/cal_wer_map.py $small/utt_wer >> $result
    fi
  fi
done
