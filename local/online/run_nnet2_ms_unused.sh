
if [ $stage -le 10 ]; then
  # If this setup used PLP features, we'd have to give the option --feature-type plp
  # to the script below.
  steps/online/nnet2/prepare_online_decoding.sh --mfcc-config conf/mfcc.conf \
    data/lang exp/speech/nnet2_online/extractor "$dir" ${dir}_online || exit 1;
fi

if [ $stage -le 11 ]; then
  # do the actual online decoding with iVectors, carrying info forward from 
  # previous utterances of the same speaker.
  for test in test_clean test_other dev_clean dev_other; do
    (
    steps/online/nnet2/decode.sh --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
      exp/speech/tri6b/graph_tgsmall data/speech/$test ${dir}_online/decode_${test}_tgsmall || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tgmed} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,tgmed}  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,tglarge} || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,fglarge} || exit 1;
    ) &
  done
  wait
fi

if [ $stage -le 12 ]; then
  # this version of the decoding treats each utterance separately
  # without carrying forward speaker information.
  for test in test_clean test_other dev_clean dev_other; do
    (
    steps/online/nnet2/decode.sh --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
      --per-utt true exp/speech/tri6b/graph_tgsmall data/speech/$test ${dir}_online/decode_${test}_tgsmall_utt || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tgmed} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,tgmed}_utt  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,tglarge}_utt || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,fglarge}_utt || exit 1;
    ) &
  done
  wait
fi

if [ $stage -le 13 ]; then
  # this version of the decoding treats each utterance separately
  # without carrying forward speaker information, but looks to the end
  # of the utterance while computing the iVector (--online false)
  for test in test_clean test_other dev_clean dev_other; do
    (
    steps/online/nnet2/decode.sh --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
      --per-utt true --online false exp/speech/tri6b/graph_tgsmall data/speech/$test \
        ${dir}_online/decode_${test}_tgsmall_utt_offline || exit 1;
    steps/lmrescore.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tgmed} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,tgmed}_utt_offline  || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,tglarge}_utt_offline || exit 1;
    steps/lmrescore_const_arpa.sh \
      --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
      data/speech/$test ${dir}_online/decode_${test}_{tgsmall,fglarge}_utt_offline || exit 1;
    ) &
  done
  wait
fi

if [ $stage -le 14 ]; then
  # Creates example data dir.
  local/prepare_example_data.sh data/test_clean/ data/test_clean_example

  # Copies example decoding script to current directory.
  cp local/decode_example.sh .

  other_files=data/local/lm/lm_tgsmall.arpa.gz
  other_files="$other_files decode_example.sh"
  other_dirs=data/test_clean_example/

  dist_file=librispeech_`basename ${dir}_online`.tgz
  utils/prepare_online_nnet_dist_build.sh \
    --other-files "$other_files" --other-dirs "$other_dirs" \
    data/lang ${dir}_online $dist_file

  rm -rf decode_example.sh
  echo "NOTE: If you would like to upload this build ($dist_file) to kaldi-asr.org please check the process at http://kaldi-asr.org/uploads.html"
fi

exit 0;
###### Comment out the "exit 0" above to run the multi-threaded decoding. #####

if [ $stage -le 15 ]; then
  # Demonstrate the multi-threaded decoding.
  test=dev_clean
  steps/online/nnet2/decode.sh --threaded true \
    --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
    --per-utt true exp/speech/tri6b/graph_tgsmall data/speech/$test \
    ${dir}_online/decode_${test}_tgsmall_utt_threaded || exit 1;
fi

if [ $stage -le 16 ]; then
  # Demonstrate the multi-threaded decoding with endpointing.
  test=dev_clean
  steps/online/nnet2/decode.sh --threaded true --do-endpointing true \
    --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
    --per-utt true exp/speech/tri6b/graph_tgsmall data/speech/$test \
    ${dir}_online/decode_${test}_tgsmall_utt_threaded_ep || exit 1;
fi

if [ $stage -le 17 ]; then
  # demonstrate the multi-threaded decoding with silence excluded
  # from ivector estimation.
  test=dev_clean
  steps/online/nnet2/decode.sh --threaded true  --silence-weight 0.0 \
    --config conf/decode.config --cmd "$decode_cmd" --nj $numjob \
    --per-utt true exp/speech/tri6b/graph_tgsmall data/speech/$test \
    ${dir}_online/decode_${test}_tgsmall_utt_threaded_sil0.0 || exit 1;
fi

exit 0;
