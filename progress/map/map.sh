#!/bin/bash
storedir=/data/groups/hao246
datadir=$storedir/singing-voice-recog/data
expdir=$storedir/singing-voice-recog/exp
mfccdir=$storedir/singing-voice-recog/mfcc

echo "$0 $@"

if [ $# -ne 2 ]; then
  echo "Usage: $0 <stage> <genre>"
  echo "e.g.: $0 3 pop"
  exit 1
fi


stage=$1
genre=$2

storePath=$storedir/vocal_data/genre/
trainingdata=$datadir/paper/genre/$genre\_train_clean
testingdata=$datadir/paper/test_clean_utt
langmodel=$datadir/lang_lyric_exten
#Model trained by totally vocal data : v
#Model trained by speech and adapted by vocal data : sv
#Model trained by speech or vocal  and adapted by genre data : gv
suffix=$genre
nj=4

. cmd.sh
. path.sh

if [ $stage -le 0 ]; then
  python pyutils/divide_genre.py 1 $genre
  for part in train_clean test_clean ; do
    local/vocaldata_prep_utt.sh $storePath/$genre\_$part data/paper/genre/$genre\_$part || exit 1;
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj \
      data/paper/genre/$genre\_$part exp/make_mfcc/paper/genre/$genre\_$part mfcc/paper/genre/$genre\_$part || exit 1;
    steps/compute_cmvn_stats.sh \
      data/paper/genre/$genre\_$part exp/make_mfcc/paper/genre/$genre\_$part mfcc/paper/genre/$genre\_$part || exit 1;
  done
fi

if [ $stage -le 1 ]; then
    oldtri3bexp=$expdir/paper/tri3b_utt
    tri3bexp=$expdir/paper/map/tri3b_utt
    if [ ! -d $tri3bexp ] ; then
      cp -rf $oldtri3bexp $tri3bexp
    fi
    tri3baliexp=$expdir/paper/map/tri3b_ali_$suffix
    mapexp=$expdir/paper/map/tri4b_map_$suffix
    steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $trainingdata $langmodel $tri3bexp $tri3baliexp || exit 1;
    steps/train_map.sh --cmd "$train_cmd"  \
        $trainingdata $langmodel $tri3baliexp $mapexp || exit 1;
fi

if [ $stage -le 2 ]; then
  result=./paper_map_result.txt
  mapexp=$expdir/paper/map/tri4b_map_$suffix

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
    python pyutils/cal_wer_map.py $small/utt_wer >> $result
    progress/cal_wer.sh $mid >> $result
    python pyutils/cal_wer_map.py $mid/utt_wer >> $result
  fi
fi
