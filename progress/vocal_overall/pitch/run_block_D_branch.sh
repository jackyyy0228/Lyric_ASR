. path.sh
. cmd.sh

part=$1
initleaves=$2
finalleaves=$3
numjob=$4

lm=data/lang_lyric_exten
trainset=data/paper/pitch/train_clean$part
testset=data/paper/pitch/test_clean$part

steps/train_lda_mllt.sh --cmd "$train_cmd" \
  --splice-opts "--left-context=3 --right-context=3" $initleaves $finalleaves \
  $trainset $lm exp/paper/pitch/tri1_ali$part exp/paper/pitch/branch_tri2b$part/$initleaves\_$finalleaves || exit 1;

utils/mkgraph.sh \
  $lm\_test_tgsmall exp/paper/pitch/branch_tri2b$part/$initleaves\_$finalleaves exp/paper/pitch/branch_tri2b$part/$initleaves\_$finalleaves/graph_tgsmall || exit 1;
steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
  exp/paper/pitch/branch_tri2b$part/$initleaves\_$finalleaves/graph_tgsmall $testset \
  exp/paper/pitch/branch_tri2b$part/$initleaves\_$finalleaves/decode_test_clean_tgsmall || exit 1;

grep WER exp/paper/pitch/branch_tri2b$part/$initleaves\_$finalleaves/decode_test_clean_tgsmall/wer* | utils/best_wer.sh
