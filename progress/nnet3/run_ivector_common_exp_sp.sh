#!/bin/bash

set -e -o pipefail

# This script is called from scripts like local/nnet3/run_tdnn.sh and
# local/chain/run_tdnn.sh (and may eventually be called by more scripts).  It
# contains the common feature preparation and iVector-related parts of the
# script.  See those scripts for examples of usage.


stage=0
nj=1
train_set=data/paper/train_clean_utt   # you might set this to e.g. train.
test_sets=data/paper/test_clean_utt
gmm=paper/tri3b_utt                # This specifies a GMM-dir from the features of the type you're training the system on;
                         # it should contain alignments for 'train_set'.

num_threads_ubm=1
nnet3_affix=             # affix for exp/nnet3 directory to put iVector stuff in (e.g.
                         # in the tedlium recip it's _cleaned).
ivector_dim=50
. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

gmm_dir=exp/${gmm}
ali_dir=exp/nnet3/tri3b_ali_sp5_2
train_hires=data/sp_exp/train_5_2sp_hires
train_sp=data/sp_exp/train_5_2sp
ivectordir=exp/nnet3/sp_exp/ivectors_train_5_2sp_hires

for f in ${train_set}/feats.scp ${gmm_dir}/final.mdl; do
  if [ ! -f $f ]; then
    echo "$0: expected file $f to exist"
    exit 1
  fi
done

if [ $stage -le 2 ] && [  -f $train_hires/feats.scp ]; then
  echo "$0: data/${train_set}_sp_hires/feats.scp already exists."
  echo " ... Please either remove it, or rerun this script with stage > 2."
  exit 1
fi


if [ $stage -le 1 ]; then
  echo "$0: preparing directory for speed-perturbed data"
  utils/data/perturb_data_dir_speed_5way.sh ${train_set} $train_sp
fi
if [ $stage -le 2 ]; then
  echo "$0: creating high-resolution MFCC features"

  # this shows how you can split across multiple file-systems.  we'll split the
  # MFCC dir across multiple locations.  You might want to be careful here, if you
  # have multiple copies of Kaldi checked out and run the same recipe, not to let
  # them overwrite each other.

  utils/copy_data_dir.sh $train_sp $train_hires

  # do volume-perturbation on the training data prior to extracting hires
  # features; this helps make trained nnets more invariant to test data volume.
  utils/data/perturb_data_dir_volume.sh $train_hires

  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
    --cmd "$train_cmd" $train_hires
  steps/compute_cmvn_stats.sh $train_hires
  utils/fix_data_dir.sh $train_hires
fi


if [ $stage -le 5 ]; then
  # note, we don't encode the 'max2' in the name of the ivectordir even though
  # that's the data we extract the ivectors from, as it's still going to be
  # valid for the non-'max2' data; the utterance list is the same.

  # We now extract iVectors on the speed-perturbed training data .  With
  # --utts-per-spk-max 2, the script pairs the utterances into twos, and treats
  # each of these pairs as one speaker; this gives more diversity in iVectors..
  # Note that these are extracted 'online' (they vary within the utterance).

  # Having a larger number of speakers is helpful for generalization, and to
  # handle per-utterance decoding well (the iVector starts at zero at the beginning
  # of each pseudo-speaker).
  temp_data_root=${ivectordir}
  utils/data/modify_speaker_info.sh --utts-per-spk-max 2 \
    $train_hires ${temp_data_root}/train_sp_hires_max2

  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
    ${temp_data_root}/train_sp_hires_max2 \
    exp/nnet3/extractor $ivectordir

  # Also extract iVectors for the test data, but in this case we don't need the speed
  # perturbation (sp).
fi

if [ -f $train_sp/feats.scp ] && [ $stage -le 8 ]; then
  echo "$0: $feats already exists.  Refusing to overwrite the features "
  echo " to avoid wasting time.  Please remove the file and continue if you really mean this."
  exit 1;
fi


if [ $stage -le 6 ]; then
  echo "$0: preparing directory for low-resolution speed-perturbed data (for alignment)"
  utils/data/perturb_data_dir_speed_5way.sh \
    ${train_set} $train_sp
fi

if [ $stage -le 7 ]; then
  echo "$0: making MFCC features for low-resolution speed-perturbed data (needed for alignments)"
  steps/make_mfcc.sh --nj $nj \
    --cmd "$train_cmd" $train_sp
  steps/compute_cmvn_stats.sh $train_sp
  echo "$0: fixing input data-dir to remove nonexistent features, in case some "
  echo ".. speed-perturbed segments were too short."
  utils/fix_data_dir.sh $train_sp
fi

if [ $stage -le 8 ]; then
  if [ -f $ali_dir/ali.1.gz ]; then
    echo "$0: alignments in $ali_dir appear to already exist.  Please either remove them "
    echo " ... or use a later --stage option."
    exit 1
  fi
  echo "$0: aligning with the perturbed low-resolution data"
  steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    $train_sp data/lang_lyric_exten $gmm_dir $ali_dir
fi


exit 0;
