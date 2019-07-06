. path.sh
. cmd.sh

name=$1
sname=$2

for part in train_clean test_clean; do

  data=data/paper/pitch/$part\_utt_$sname
  dir=exp/paper/pitch/exten_feats/$part\_utt_$name

  ori_feats="ark,s,cs:apply-cmvn $cmvn_opts --utt2spk=ark:$data/JOB/utt2spk scp:$data/JOB/cmvn.scp scp:$data/JOB/feats.scp ark:- | add-deltas ark:- ark:- |"

  for n in $(seq 4); do
    copy-feats ark,t:my_exten_pitch_feats_$part.$n.txt ark:$dir/sub/my_exten_pitch_$part\_utt_$name.$n.ark
  done

  pitch_feats="ark,s,cs:exp/paper/exten_feats/sub/my_exten_pitch_feats.JOB.ark |"

  $cmd JOB=1:4 $dir/log/make_exten_pitch.JOB.log \
    paste-feats --length-tolerance=$paste_length_tolerance "$ori_feats" "$pitch_feats" ark:- \| \
    copy-feats --compress=$compress ark:- \
      ark:$dir/log/raw_exten_pitch.JOB.ark || exit 1;
