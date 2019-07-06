#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

if [ $# -ne 2 ]; then
  echo "Usage: $0 <stage> <level>"
  echo "e.g.: $0 3 [utt/song/singer/genre]"
  exit 1
fi

stage=$1
suffix=$2

numjob=4
trainingdata=$datadir/paper/train_clean_$suffix
testingdata=$datadir/paper/test_clean_$suffix
lm=$datadir/lang_lyric_exten

if [ $stage -le 0 ]; then
  tri2bexp=$expdir/paper/tri2b_utt
  ali=$expdir/paper/fmllr/tri2b_ali_$suffix
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
     $trainingdata $lm $tri2bexp $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le 1 ]; then
  ali=$expdir/paper/fmllr/tri2b_ali_$suffix
  mdl=$expdir/paper/fmllr/tri3b_$suffix
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainingdata $lm $ali $mdl || exit 1;
fi

if [ $stage -le 2 ]; then
  result=./paper_result2.txt
  mdl=$expdir/paper/fmllr/tri3b_$suffix
  langmodel=$lm

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

    if [ "$suffix" == "genre" ]; 
    then
      progress/cal_wer_genre.sh $small >> $result
      progress/cal_wer_genre.sh $mid >> $result
    else
      progress/cal_wer.sh $small >> $result
      progress/cal_wer.sh $mid >> $result
    fi
  fi
fi
