. path.sh
. cmd.sh
audio_dir=../vocal_data

numjob=4
# run librispeech/s5/run.sh to tri4b
# prepare data
: '
for part in train_clean test_clean; do
  local/vocaldata_prep.sh $audio_dir/$part data/paper/$part\_song || exit 1;
  steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
    data/paper/$part\_song exp/make_mfcc/paper/$part\_song mfcc/paper/$part\_song || exit 1;
  steps/compute_cmvn_stats.sh \
    data/paper/$part\_song exp/make_mfcc/paper/$part\_song mfcc/paper/$part\_song || exit 1;
done

for part in train_clean test_clean; do
  utils/copy_data_dir.sh data/paper/$part\_utt data/paper/$part\_utt_dur_0_pitch_1 || exit 1;
  steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $numjob \
    --mfcc-config conf/mfcc.conf \
    --pitch-postprocess-config conf/pitch_postprocess.conf \
    data/paper/$part\_utt_dur_0_pitch_1 exp/make_mfcc/paper/$part\_utt_dur_0_pitch_1 mfcc/paper/$part\_utt_dur_0_pitch_1 || exit 1;
  steps/compute_cmvn_stats.sh \
    data/paper/$part\_utt_dur_0_pitch_1 exp/make_mfcc/paper/$part\_utt_dur_0_pitch_1 mfcc/paper/$part\_utt_dur_0_pitch_1 || exit 1;
done
'

for part in train_clean test_clean; do
  #utils/copy_data_dir.sh data/paper/$part\_utt data/paper/$part\_utt_pitch_10 || exit 1;
  steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $numjob \
    --pitch-postprocess-config conf/pitch_postprocess.conf \
    data/paper/pitch/$part\_utt_pitch_2 exp/make_mfcc/paper/pitch/$part\_utt_pitch_2 mfcc/paper/pitch/$part\_utt_pitch_2 || exit 1;
  steps/compute_cmvn_stats.sh \
    data/paper/pitch/$part\_utt_pitch_2 exp/make_mfcc/paper/pitch/$part\_utt_pitch_2 mfcc/paper/pitch/$part\_utt_pitch_2 || exit 1;
done
: '
for part in train_clean test_clean; do
  for n in $(seq 4); do
    cat mfcc/paper/$part\_utt_pitch_2/raw_mfcc_pitch_$part\_utt_pitch_2.$n.scp || exit 1;
  done > data/paper/$part\_utt_pitch_2/feats.scp
  steps/compute_cmvn_stats.sh \
    data/paper/$part\_utt_pitch_2 exp/make_mfcc/paper/$part\_utt_pitch_2 mfcc/paper/$part\_utt_pitch_2 || exit 1;
done
'

# (option) 3 iters : features add pitch, zcr, or none
# 2 iters : song, utt

lm=data/lang_lyric_exten
#lm=data/lang_lyric
: '
for part in _utt_pitch_2; do

  #trainset=data/paper/train_clean$part
  #testset=data/paper/test_clean$part
  
  #local/train_mono_pitch.sh \
  #  --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
  #  $trainset $lm exp/paper/comp_pitch/mono$part\_exten_pitch || exit 1;

  #local/align_si_pitch.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
  #  $trainset $lm exp/paper/comp_pitch/mono$part\_exten_pitch exp/paper/comp_pitch/mono_ali$part\_exten_pitch || exit 1;

  #local/train_deltas_pitch.sh --boost-silence 1.25 --cmd "$train_cmd" \
  #  1000 5000 $trainset $lm exp/paper/comp_pitch/mono_ali$part\_exten_pitch exp/paper/comp_pitch/tri1$part\_exten_pitch || exit 1;

  #local/align_si_pitch.sh --nj $numjob --cmd "$train_cmd" \
  #  $trainset $lm exp/paper/comp_pitch/tri1$part\_exten_pitch exp/paper/comp_pitch/tri1_ali$part\_exten_pitch || exit 1;

  #local/train_lda_mllt_pitch.sh --cmd "$train_cmd" \
  #  --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
  #  $trainset $lm exp/paper/comp_pitch/tri1_ali$part\_exten_pitch exp/paper/comp_pitch/tri2b$part\_exten_pitch || exit 1;

  #utils/mkgraph.sh \
  #  $lm\_test_tgsmall exp/paper/comp_pitch/tri2b$part\_exten_pitch exp/paper/comp_pitch/tri2b$part\_exten_pitch/graph_tgsmall || exit 1;
  #local/decode_pitch.sh --nj $numjob --cmd "$decode_cmd" \
  #  exp/paper/comp_pitch/tri2b$part\_exten_pitch/graph_tgsmall $testset \
  #  exp/paper/comp_pitch/tri2b$part\_exten_pitch/decode_test_clean_tgsmall || exit 1;
done 
for part in _utt_pitch_2; do

  trainset=data/paper/train_clean$part
  testset=data/paper/test_clean$part
 
  # Block B
  steps/train_mono.sh \
    --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm exp/paper/comp_pitch/mono$part || exit 1;
  #utils/mkgraph.sh --mono \
  #  $lm\_test_tgsmall exp/paper/comp_pitch/mono$part exp/paper/comp_pitch/mono$part/graph_tgsmall || exit 1;
  #steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
  #  exp/paper/comp_pitch/mono$part/graph_tgsmall $testset \
  #  exp/paper/comp_pitch/mono$part/decode_test_clean_tgsmall || exit 1;
 
  # Block C
  steps/align_si.sh --boost-silence 1.25 --nj $numjob --cmd "$train_cmd" \
    $trainset $lm exp/paper/comp_pitch/mono$part exp/paper/comp_pitch/mono_ali$part || exit 1;
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    1000 5000 $trainset $lm exp/paper/comp_pitch/mono_ali$part exp/paper/comp_pitch/tri1$part || exit 1;
  #utils/mkgraph.sh \
  #  $lm\_test_tgsmall exp/paper/comp_pitch/tri1$part exp/paper/comp_pitch/tri1$part/graph_tgsmall || exit 1;
  #steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
  #  exp/paper/comp_pitch/tri1$part/graph_tgsmall $testset \
  #  exp/paper/comp_pitch/tri1$part/decode_test_clean_tgsmall || exit 1;

  # Block D
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm exp/paper/comp_pitch/tri1$part exp/paper/comp_pitch/tri1_ali$part || exit 1;
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
    $trainset $lm exp/paper/comp_pitch/tri1_ali$part exp/paper/comp_pitch/tri2b$part || exit 1;
  utils/mkgraph.sh \
    $lm\_test_tgsmall exp/paper/comp_pitch/tri2b$part exp/paper/comp_pitch/tri2b$part/graph_tgsmall || exit 1;
  steps/decode.sh --nj $numjob --cmd "$decode_cmd" \
    exp/paper/comp_pitch/tri2b$part/graph_tgsmall $testset \
    exp/paper/comp_pitch/tri2b$part/decode_test_clean_tgsmall || exit 1;
  
done

'
# best tri2b as base model : tri2b_utt
# 4 iters : compare utt, song, singer, genre
: '
lm=data/lang_lyric_exten

for part in _utt_pitch; do

  trainset=data/paper/train_clean$part
  testset=data/paper/test_clean$part
  
  # steps/align_si.sh
  steps/align_si.sh --nj $numjob --cmd "$train_cmd" \
    $trainset $lm exp/paper/tri2b$part exp/paper/tri2b_ali$part || exit 1;
  # steps/align_fmllr.sh
  # steps/align_fmllr.sh --nj $numjob --cmd "$train_cmd" \
  #   $trainset $lm exp/paper/tri2b_utt exp/paper/tri2b_fmllr_ali$part || exit 1;
  # steps/train_sat.sh
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainset $lm exp/paper/tri2b_ali$part exp/paper/tri3b$part || exit 1;

  utils/mkgraph.sh \
    $lm\_test_tgsmall exp/paper/tri3b$part exp/paper/tri3b$part/graph_tgsmall || exit 1;
  steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
    exp/paper/tri3b$part/graph_tgsmall $testset \
    exp/paper/tri3b$part/decode_test_clean_tgsmall || exit 1;
done
'
: '
# baseline
lm=data/lang_nosp
testset=data/paper/test_clean_utt

utils/mkgraph.sh \
  $lm\_test_tgsmall exp/speech/tri4b exp/speech/tri4b/graph_paper_ls_tgsmall || exit 1;
steps/decode_fmllr.sh --nj $numjob --cmd "$decode_cmd" \
  exp/speech/tri4b/graph_paper_ls_tgsmall $testset \
  exp/speech/tri4b/decode_paper_vocal_test_clean_utt_tgsmall || exit 1;


# best tri3b as base model
# 4 iters : compare utt, song, singer, genre
# steps/align_fmllr.sh

# progress/vocal_overall/gpu_pnorm3.sh
## steps/nnet2/multisplice
## steps/nnet2/conv
# progress/vocal_overall/gpu_ivec_pnorm3.sh
# local/online/run_nnet_adapt3.sh

lm=data/lang_lyric_exten
dir=exp/paper/nnet/threads_pnorm_utt_th8_nj10_mb128_nj4_1k_ep15
steps/lmrescore.sh --cmd "$decode_cmd" $lm\_test_{tgsmall,tgmed} \
  data/paper/test_clean_utt $dir/decode_test_clean_{tgsmall,tgmed} || exit 1;
'
