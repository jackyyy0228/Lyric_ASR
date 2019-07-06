#!/bin/bash
storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
expdir=/data1/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc
nnet2expdir=/data/hao246/singing-voice-recog/exp


. cmd.sh
. path.sh

stage=1

if [ $stage -ge 1 ]; then
  for test in all; do
    steps/decode_fmllr.sh --nj 10 --cmd "$decode_cmd" \
      $expdir/speech/tri4b/graph_tgsmall $datadir/vocal/$test \
      $expdir/speech/tri4b/decode_tgsmall_vocal_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tgmed} \
      $datadir/vocal/$test $expdir/speech/tri4b/decode_{tgsmall,tgmed}_vocal_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tglarge} \
      $datadir/vocal/$test $expdir/speech/tri4b/decode_{tgsmall,tglarge}_vocal_$test || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,fglarge} \
      $datadir/vocal/$test $expdir/speech/tri4b/decode_{tgsmall,fglarge}_vocal_$test || exit 1;
  done
  for test in all; do
    steps/nnet2/decode.sh --nj 10 --cmd "$decode_cmd" \
        --transform-dir $expdir/speech/tri4b/decode_tgsmall_vocal_$test \
        $expdir/speech/tri4b/graph_tgsmall $datadir/vocal/$test $nnet2expdir/speech/nnet5a_clean_100_gpu/decode_tgsmall_vocal_$test || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tgmed} \
        $datadir/vocal/$test $nnet2expdir/speech/nnet5a_clean_100_gpu/decode_{tgsmall,tgmed}_vocal_$test  || exit 1;
    steps/lmrescore_const_arpa.sh \
        --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,tglarge} \
        $datadir/vocal/$test $nnet2expdir/speech/nnet5a_clean_100_gpu/decode_{tgsmall,tglarge}_vocal_$test || exit 1;
    steps/lmrescore_const_arpa.sh \
        --cmd "$decode_cmd" $datadir/lang_test_{tgsmall,fglarge} \
        $datadir/vocal/$test $nnet2expdir/speech/nnet5a_clean_100_gpu/decode_{tgsmall,fglarge}_vocal_$test || exit 1;
  done
fi
