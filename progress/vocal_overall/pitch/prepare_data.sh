. path.sh
. cmd.sh

name=$1

for part in train_clean test_clean; do

  
  if [ -d data/paper/pitch/$part\_utt_$name ]; then
    echo "directory data/paper/pitch/$part\_utt_$name already exists!"
    exit 1;
  fi

  utils/copy_data_dir.sh data/paper/pitch/$part\_utt_pitch_2 data/paper/pitch/$part\_utt_$name || exit 1;
  cp -r mfcc/paper/pitch/$part\_utt_pitch_2 mfcc/paper/pitch/$part\_utt_$name
  rm mfcc/paper/pitch/$part\_utt_$name/*
  
  for n in $(seq 4); do
    copy-feats ark,t:r_tmp_mfcc_pitch_2_$part.$n.txt ark,scp:mfcc/paper/pitch/$part\_utt_$name/raw_mfcc_pitch_$part\_utt_$name.$n.ark,mfcc/paper/pitch/$part\_utt_$name/raw_mfcc_pitch_$part\_utt_$name.$n.scp
  done
  
  for n in $(seq 4); do
    cat mfcc/paper/pitch/$part\_utt_$name/raw_mfcc_pitch_$part\_utt_$name.$n.scp || exit 1;
  done > data/paper/pitch/$part\_utt_$name/feats.scp
  
  steps/compute_cmvn_stats.sh \
    data/paper/pitch/$part\_utt_$name exp/make_mfcc/paper/pitch/$part\_utt_$name mfcc/paper/pitch/$part\_utt_$name || exit 1;

done

echo "The data is stored in data/paper/pitch/$part\_utt_$name"
