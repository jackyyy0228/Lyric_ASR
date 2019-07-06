#!/bin/bash
storedir=/data/groups/hao246
datadir=$storedir/singing-voice-recog/data
expdir=$storedir/singing-voice-recog/exp
mfccdir=$storedir/singing-voice-recog/mfcc

echo "$0 $@"


storePath=$storedir/vocal_data/genre/
trainingdata=$datadir/paper/train_clean_utt
testingdata=$datadir/paper/test_clean_utt
langmodel=$datadir/lang_lyric_exten
#Model trained by totally vocal data : v
#Model trained by speech and adapted by vocal data : sv
#Model trained by speech or vocal  and adapted by genre data : gv
nj=4

. cmd.sh
. path.sh

#to get the result of 5 genre in tri3b_utt
result=./paper_map_result.txt
mapexp=$expdir/paper/map/tri3b_utt
small=$mapexp/decode_fmllr_test_clean_tgsmall
mid=$mapexp/decode_fmllr_test_clean_tgmed

utils/mkgraph.sh $langmodel\_test_tgsmall \
  $mapexp $mapexp/graph_tgsmall
steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
  $mapexp/graph_tgsmall $testingdata \
  $small || exit 1;
steps/lmrescore.sh --cmd "$decode_cmd" $langmodel\_test_{tgsmall,tgmed} \
  $testingdata $small $mid  || exit 1;
progress/cal_wer.sh $small >> $result
python pyutils/cal_wer_map.py $small/utt_wer >> $result
progress/cal_wer.sh $mid >> $result
python pyutils/cal_wer_map.py $mid/utt_wer >> $result
