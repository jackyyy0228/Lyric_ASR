#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=6
expid=exp3


#TODO : Align to utterance-level file, all clips
if [ $stage -le 6 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/svtri2b_svtri1_1k_5k_$expid
  ali=$expdir/vocal/svtri2b_svtri1_1k_5k_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    --use-graphs true $trainset $lm $mdl $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri2b_svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri3b_svtri1_1k_5k_$expid
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

lm=$datadir/lang_lyric
testset=$datadir/vocal/test_clean

#TODO : Train triphone with aligned model
if [ $stage -le 12 ]; then
  mdl=$expdir/vocal/svtri3b_svtri1_1k_5k_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 13 ]; then
  mdl=$expdir/vocal/svtri2b_svtri1_1k_5k_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_fmllr_vocal_test_clean
  #utils/mkgraph.sh \
  #  $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi
