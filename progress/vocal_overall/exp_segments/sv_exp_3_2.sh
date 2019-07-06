#!/bin/bash
rootdir=/data/groups/hao246
datadir=$rootdir/singing-voice-recog/data
expdir=$rootdir/singing-voice-recog/exp
mfccdir=$rootdir/singing-voice-recog/mfcc

. cmd.sh
. path.sh

echo "$0 $@"

stage=$1
numjob=8
expid=exp3

lm=$datadir/lang_lyric
testset=$datadir/vocal/test_clean
# run_5a_clean_100.sh

#TODO : Align to utterance-level file, all clips
if [ $stage -le -1 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/svmono_$expid
  ali=$expdir/vocal/svmono_ali_$expid
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train a first delta + delta-delta triphone system
# called tri1
#TODO : Train triphone with aligned model
if [ $stage -le 0 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svmono_ali_$expid
  mdl=$expdir/vocal/svtri1_$expid\_1k\_5k
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    1000 5000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 1 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svmono_ali_$expid
  mdl=$expdir/vocal/svtri1_$expid\_1p5k\_8k
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    1500 8000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 2 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svmono_ali_$expid
  mdl=$expdir/vocal/svtri1_$expid
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 3 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svmono_ali_$expid
  mdl=$expdir/vocal/svtri1_$expid\_2p2k\_12k
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2200 12000 $trainset $lm $ali $mdl || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -ge 10 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/svtri1_$expid\_1k\_5k
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  #utils/mkgraph.sh \
  #  $lm\_test_tgsmall $mdl $graph || exit 1;
  #steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
  #  $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 5 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/svtri1_$expid\_1p5k\_8k
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 6 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/svtri1_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi

#TODO : Train triphone with aligned model
if [ $stage -le 7 ]; then
  # decode using triphone model (delta+delta-delta)
  mdl=$expdir/vocal/svtri1_$expid\_2p2k\_12k
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi
