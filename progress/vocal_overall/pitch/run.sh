#sleep 30m

progress/vocal_overall/pitch/prepare_data.sh kaldi_pitch2 || exit 1;

progress/vocal_overall/pitch/run_block_B.sh _utt_kaldi_pitch2 4 || exit 1;
