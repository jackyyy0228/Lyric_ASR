. path.sh
. cmd.sh

part=$1
numjob=$2

lm=data/lang_lyric_exten
trainset=data/paper/pitch/train_clean$part
testset=data/paper/pitch/test_clean$part

steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
  $trainset $lm exp/paper/pitch/tri1$part exp/paper/pitch/tri1_ali$part || exit 1;
steps/train_lda_mllt.sh --cmd "$train_cmd" \
  --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
  $trainset $lm exp/paper/pitch/tri1_ali$part exp/paper/pitch/tri2b$part || exit 1;
utils/mkgraph.sh \
  $lm\_test_tgsmall exp/paper/pitch/tri2b$part exp/paper/pitch/tri2b$part/graph_tgsmall || exit 1;
steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
  exp/paper/pitch/tri2b$part/graph_tgsmall $testset \
  exp/paper/pitch/tri2b$part/decode_test_clean_tgsmall || exit 1;

grep WER exp/paper/pitch/tri2b$part/decode_test_clean_tgsmall/wer* | utils/best_wer.sh
