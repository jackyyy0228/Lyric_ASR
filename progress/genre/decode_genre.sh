#!/bin/bash
storedir=/data/groups/hao246
datadir=$storedir/singing-voice-recog/data
expdir=$storedir/singing-voice-recog/exp
mfccdir=$storedir/singing-voice-recog/mfcc

if [ $# -ne 3 ]; then
  echo "Usage: $0 <trainingmodel-genre> <decode-genre> <resultFile>"
  echo "e.g.: $0 pop nonpop ./result.txt"
  exit 1
fi

tgenre=$1
dgenre=$2
result=$3

storePath=$storedir/vocal_data/genre/
trainingdata=$datadir/genre/$tgenre\_train_clean
testing=$datadir/genre/$dgenre
langmodel=$datadir/lang_lyric
prefix=v

#Model trained by totally vocal data : v
#Model trained by speech and adapted by vocal data : sv
#Model trained by speech or vocal  and adapted by genre data : gv
suffix=$tgenre
nj=3
. cmd.sh
. path.sh

stage=1

if [ $stage -ge 1 ]; then
  tri3bexp=$expdir/genre/$prefix\tri3b_$suffix

  utils/mkgraph.sh $langmodel\_test_tgsmall \
    $tri3bexp $tri3bexp/graph_tgsmall
  for tests in test_clean; do
    testingdata=$testing\_$tests
    if [ $dgenre == "all" ]; then
      testingdata=$datadir/vocal/$tests
    fi
    echo $testingdata
    small=$tri3bexp/decode_tgsmall_$dgenre\_$tests
    mid=$tri3bexp/decode_tgmed_$dgenre\_$tests
    if [ ! -f $small/lat.1.gz ]; then
      steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
        $tri3bexp/graph_tgsmall $testingdata \
        $small || exit 1;
      steps/lmrescore.sh --cmd "$decode_cmd" $langmodel\_test_{tgsmall,tgmed} \
        $testingdata $small $mid  || exit 1;
      progress/cal_wer.sh $small >> $result
      progress/cal_wer.sh $mid >> $result
    fi
  done
fi
