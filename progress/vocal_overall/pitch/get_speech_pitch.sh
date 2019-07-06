. path.sh
. cmd.sh

for part in test_clean; do
  utils/copy_data_dir.sh data/speech/$part data/speech/$part\_pitch || exit 1;
  steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj 4 \
    --pitch-config conf/pitch.conf \
    --pitch-postprocess-config conf/speech_pitch_postprocess.conf \
    data/speech/$part\_pitch exp/make_mfcc/speech/$part\_pitch mfcc/speech/$part\_pitch || exit 1;
#  steps/compute_cmvn_stats.sh \
#    data/speech/$part\_pitch exp/make_mfcc/speech/$part\_pitch mfcc/speech/$part\_pitch || exit 1;
done

  for n in $(seq 4); do
    copy-feats ark:mfcc/speech/test_clean_pitch/raw_mfcc_pitch_test_clean_pitch.$n.ark ark,t:tmp_speech_mfcc_pitch.$n.txt
  done
