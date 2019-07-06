#!/bin/bash
audio_dir=vocal_data
lm=data/lang_lyric_exten
trainset=data/paper/train_clean_utt
testset=data/paper/test_clean_utt
stage=4
numjob=4

. path.sh
. cmd.sh
. utils/parse_options.sh

if [ $stage -le 0 ]; then
  progress/prepare_data.sh
fi

if [ $stage -le 1 ]; then
  # Block B
  mono=exp/paper/mono_utt
  steps/train_mono.sh \
    --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mono || exit 1;
  utils/mkgraph.sh --mono \
    $lm\_test_tgsmall $mono $mono/graph_tgsmall || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $mono/graph_tgsmall $testset \
    $mono/decode_test_clean_tgsmall || exit 1;
fi

if [ $stage -le 2 ]; then
  # Block C
  mono=exp/paper/mono_utt
  mono_ali=exp/paper/mono_ali_utt
  tri1=exp/paper/tri1_utt
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $mono $mono_ali || exit 1;
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    1000 5000 $trainset $lm $mono_ali $tri1 || exit 1;
  utils/mkgraph.sh \
    $lm\_test_tgsmall $tri1 $tri1/graph_tgsmall || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $tri1/graph_tgsmall $testset $tri1/decode_test_clean_tgsmall || exit 1;
fi

if [ $stage -le 3 ]; then
  # Block D
  tri1=exp/paper/tri1_utt
  tri1_ali=exp/paper/tri1_ali_utt
  tri2=exp/paper/tri2b_utt
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $tri1 $tri1_ali || exit 1;
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm $tri1_ali $tri2 || exit 1;
  utils/mkgraph.sh \
    $lm\_test_tgsmall $tri2 $tri2/graph_tgsmall || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    $tri2/graph_tgsmall $testset $tri2/decode_test_clean_tgsmall || exit 1;
fi

if [ $stage -le 4 ]; then
  tri2=exp/paper/tri2b_utt
  tri2_ali=exp/paper/tri2b_ali_utt
  tri3=exp/paper/tri3b_utt
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm $tri2 $tri2_ali || exit 1;
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm $tri2_ali $tri3 || exit 1;
  utils/mkgraph.sh \
    $lm\_test_tgsmall $tri3 $tri3/graph_tgsmall || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    $tri3/graph_tgsmall $testset $tri3/decode_test_clean_tgsmall || exit 1;
fi

if [ $stage -le 5 ]; then
  #BLSTM
  bash progress/nnet3/run_blstm_wsj.sh 10 500 125 2
fi

if [ $stage -le 6 ]; then
  #TDNN-LSTM:
  bash progress/nnet3/run_tdnn_lstm_1a_wsj.sh 10 130 65
fi



