#!/bin/bash
storedir=/data/groups/hao246
datadir=$storedir/singing-voice-recog/data
expdir=$storedir/singing-voice-recog/exp
mfccdir=$storedir/singing-voice-recog/mfcc

echo "$0 $@"



stage=$1

storePath=$storedir/vocal_data/genre/
trainingdata=$datadir/vocal/train_clean
testingdata=$datadir/vocal/test_clean
langmodel=$datadir/lang_lyric
prefix=sv
#Model trained by totally vocal data : v
#Model trained by speech and adapted by vocal data : sv
#Model trained by speech or vocal  and adapted by genre data : gv
suffix=$genre
nj=8

. cmd.sh
. path.sh


if [ $stage -le 0 ]; then
    tri4bexp=$expdir/speech/tri4b
    tri4baliexp=$expdir/vocal/speech_tri4b_ali_vocal
    vocalexp=$expdir/genre/map/svtri3b_svtri1_1k_5k_exp3
    mapexp=$expdir/vocal/speech_tri4b_map_vocal
    
    steps/align_si.sh --nj $nj --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $trainingdata $langmodel $tri4bexp $tri4baliexp || exit 1;
    cp $vocalexp/ali.*.gz $tri4baliexp/
    steps/train_map.sh --cmd "$train_cmd"  \
        $trainingdata $langmodel $tri4baliexp $mapexp || exit 1;
fi

if [ $stage -le 1 ]; then
  result=./result.txt
  mapexp=$expdir/vocal/speech_tri4b_map_vocal

  utils/mkgraph.sh $langmodel\_test_tgsmall \
    $mapexp $mapexp/graph_tgsmall
  small=$mapexp/decode_fmllr_test_clean_tgsmall
  mid=$mapexp/decode_fmllr_test_clean_tgmed
  if [ ! -f $small/lat.1.gz ]; then
    steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
      $mapexp/graph_tgsmall $testingdata \
      $small || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $langmodel\_test_{tgsmall,tgmed} \
      $testingdata $small $mid  || exit 1;
    progress/cal_wer.sh $small >> $result
    progress/cal_wer.sh $mid >> $result
  fi
fi
