. path.sh
. cmd.sh

: '
progress/vocal_overall/train_sat_2_level.sh --cmd "$train_cmd" 2500 15000 \
  data/vocal/uttadp_train_clean data/lang_lyric \
  exp/vocal/tri3b_ali_all_clean_utt exp/vocal/test_level || exit 1;
utils/mkgraph.sh \
  data/lang_lyric_test_tgsmall exp/vocal/test_level \
  exp/vocal/test_level/graph_tgsmall || exit 1;
'
progress/vocal_overall/decode_fmllr_2_level.sh --nj 1 --cmd "$decode_cmd" \
  exp/vocal/test_level/graph_tgsmall data/vocal/uttadp_test_clean \
  exp/vocal/test_level/decode_test_clean_tgsmall || exit 1;
