#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <stage> "
  echo "e.g.: $0 3 "
  exit 1
fi

stage=$1
suffix=utt
numjob=4
trainingdata=$datadir/paper/train_clean_utt
testingdata=$datadir/paper/test_clean_utt
lm=$datadir/lang_lyric

#TODO : Train triphone with aligned model
for scale in 0.05 0.1 0.15 0.2 0.25 0.3; do
  if [ $stage -le 1 ]; then
    ali=$expdir/lm/tri2b_ali_lang_lyric
    mdl=$expdir/paper/selfloop/tri3b_lyric_$scale
    steps/train_sat_self_loop.sh --cmd "$train_cmd" --selfloopscale $scale \
    2500 15000 $trainingdata $lm $ali $mdl || exit 1;
  fi
  if [ $stage -le 2 ]; then
    result=./paper_scale_lyric.txt
    mdl=$expdir/paper/selfloop/tri3b_lyric_$scale
    langmodel=$lm

    utils/mkgraph.sh $langmodel\_test_tgsmall \
      $mdl $mdl/graph_tgsmall
    small=$mdl/decode_fmllr_test_clean_tgsmall
    if [ ! -f $small/lat.1.gz ]; then
      steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
        $mdl/graph_tgsmall $testingdata \
        $small || exit 1;
      progress/cal_wer.sh $small >> $result
    fi
  fi
done
