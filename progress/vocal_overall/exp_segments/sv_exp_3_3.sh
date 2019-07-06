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

#TODO : Align to utterance-level file, all clips
if [ $stage -le 0 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/svtri1_$expid\_1k\_5k
  ali=$expdir/vocal/svtri1_1k_5k_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

#TODO : Align to utterance-level file, all clips
if [ $stage -le 1 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  mdl=$expdir/vocal/svtri1_$expid
  ali=$expdir/vocal/svtri1_ali_$expid
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mdl $ali || exit 1;
fi

# train an LDA+MLLT system
# called tri2b
#TODO : Train triphone with aligned model
if [ $stage -le 2 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri2b_2k_10k_svtri1_1k_5k_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2000 10000 \
    $trainset $lm $ali $mdl || exit 1;
fi

# train an LDA+MLLT system
# called tri2b
#TODO : Train triphone with aligned model
if [ $stage -le 3 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri2b_svtri1_1k_5k_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

# train an LDA+MLLT system
# called tri2b
#TODO : Train triphone with aligned model
if [ $stage -le 4 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri2b_1p5k_8k_svtri1_1k_5k_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 1500 8000 \
    $trainset $lm $ali $mdl || exit 1;
fi

# train an LDA+MLLT system
# called tri2b
#TODO : Train triphone with aligned model
if [ $stage -le 5 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri1_1k_5k_ali_$expid
  mdl=$expdir/vocal/svtri2b_2k_10k_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2000 10000 \
    $trainset $lm $ali $mdl || exit 1;
fi

# train an LDA+MLLT system
# called tri2b
#TODO : Train triphone with aligned model
if [ $stage -le 6 ]; then
  trainset=$datadir/vocal/train_clean
  lm=$datadir/lang_lyric
  ali=$expdir/vocal/svtri1_ali_$expid
  mdl=$expdir/vocal/svtri2b_$expid
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm $ali $mdl || exit 1;
fi

lm=$datadir/lang_lyric
testset=$datadir/vocal/test_clean

#TODO : Train triphone with aligned model
if [ $stage -le 10 ]; then
  # decode using triphone model (lda+mllt)
  mdl=$expdir/vocal/svtri2b_2k_10k_svtri1_1k_5k_$expid
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
if [ $stage -le 11 ]; then
  # decode using triphone model (lda+mllt)
  mdl=$expdir/vocal/svtri2b_svtri1_1k_5k_$expid
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
if [ $stage -le 12 ]; then
  # decode using triphone model (lda+mllt)
  mdl=$expdir/vocal/svtri2b_1p5k_8k_svtri1_1k_5k_$expid
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
if [ $stage -le 13 ]; then
  # decode using triphone model (lda+mllt)
  mdl=$expdir/vocal/svtri2b_2k_10k_$expid
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
if [ $stage -le 14 ]; then
  # decode using triphone model (lda+mllt)
  mdl=$expdir/vocal/svtri2b_$expid
  graph=$mdl/graph_tgsmall
  result=$mdl/decode_vocal_test_clean
  utils/mkgraph.sh \
    $lm\_test_tgsmall $mdl $graph || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $graph $testset $result\_tgsmall || exit 1;
  steps/lmrescore.sh --cmd "$decode_cmd" \
    $lm\_test_{tgsmall,tgmed} $testset $result\_{tgsmall,tgmed} || exit 1;
fi
