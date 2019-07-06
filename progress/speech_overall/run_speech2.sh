#!/bin/bash
storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
expdir=/data1/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc


. cmd.sh
. path.sh

stage=0

if [ $stage -ge 1 ]; then
  utils/mkgraph.sh \
    $datadir/lang_test_tgsmall $expdir/tri4b $expdir/tri4b/graph_tgsmall || exit 1;
  for test in test_clean test_other dev_clean dev_other; do
    steps/decode_fmllr.sh --nj 2 --cmd "$decode_cmd" \
      $expdir/tri4b/graph_tgsmall $datadir/speech/$test \
      $expdir/tri4b/decode_tgsmall_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tgmed} \
      $datadir/speech/$test $expdir/tri4b/decode_{tgsmall,tgmed}_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tglarge} \
      $datadir/speech/$test $expdir/tri4b/decode_{tgsmall,tglarge}_$test || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,fglarge} \
      $datadir/speech/$test $expdir/tri4b/decode_{tgsmall,fglarge}_$test || exit 1;
  done
fi

utils/build_const_arpa_lm.sh \
  $datadir/local/lm/lm_fglarge.arpa.gz $datadir/lang $datadir/lang_test_fglarge || exit 1;

# align train_clean_100 using the tri4b model
#steps/align_fmllr.sh --nj 3 --cmd "$train_cmd" \
#  $datadir/speech/train_clean_100 $datadir/lang $expdir/speech/tri4b $expdir/speech/tri4b_ali_clean_100 || exit 1;

# if you want at this point you can train and test NN model(s) on the 100 hour
# subset
local/nnet2/run_5a_clean_100.sh || exit 1
