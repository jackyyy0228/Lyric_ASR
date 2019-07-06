. path.sh
. cmd.sh

part=$1
numjob=$2

lm=data/lang_lyric_exten
trainset=data/paper/pitch/train_clean$part
testset=data/paper/pitch/test_clean$part


steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
  $trainset $lm exp/paper/pitch/branch_tri2b$part/1600_8000 exp/paper/pitch/tri2b_ali$part || exit 1;
steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
  $trainset $lm exp/paper/pitch/tri2b_ali$part exp/paper/pitch/tri3b$part || exit 1;
utils/mkgraph.sh \
  $lm\_test_tgsmall exp/paper/pitch/tri3b$part exp/paper/pitch/tri3b$part/graph_tgsmall || exit 1;
steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
  exp/paper/pitch/tri3b$part/graph_tgsmall $testset \
  exp/paper/pitch/tri3b$part/decode_test_clean_tgsmall || exit 1;

grep WER exp/paper/pitch/tri3b$part/decode_test_clean_tgsmall/wer* | utils/best_wer.sh
