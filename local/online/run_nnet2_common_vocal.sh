#!/bin/bash

# this script contains some common (shared) parts of the run_nnet*.sh scripts.

. cmd.sh


stage=0
numjob=12

set -e
. cmd.sh
. ./path.sh
. ./utils/parse_options.sh


if [ $stage -le 4 ]; then
  mkdir -p exp/vocal/nnet2_online
  # To train a diagonal UBM we don't need very much data, so use a small subset
  # (actually, it's not that small: still around 100 hours).
  steps/online/nnet2/train_diag_ubm.sh --cmd "$train_cmd" --nj $numjob --num-frames 700000 \
    data/vocal/ori_train_clean 256 exp/vocal/svtri3b_svtri1_1k_5k_exp3 exp/vocal/nnet2_online/diag_ubm
fi

if [ $stage -le 5 ]; then
  # iVector extractors can in general be sensitive to the amount of data, but
  # this one has a fairly small dim (defaults to 100) so we don't use all of it,
  # we use just the 60k subset (about one fifth of the data, or 200 hours).
  steps/online/nnet2/train_ivector_extractor.sh --cmd "$train_cmd" --nj $numjob \
    data/vocal/ori_train_clean exp/vocal/nnet2_online/diag_ubm exp/vocal/nnet2_online/extractor || exit 1;
fi

if [ $stage -le 6 ]; then
  ivectordir=exp/vocal/nnet2_online/ivectors_train_clean
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $ivectordir/storage ]; then
    utils/create_split_dir.pl /export/b0{1,2,3,4}/$USER/kaldi-data/egs/librispeech-$(date +'%m_%d_%H_%M')/s5/$ivectordir/storage $ivectordir/storage
  fi
  # We extract iVectors on all the train data, which will be what we train the
  # system on.  With --utts-per-spk-max 2, the script.  pairs the utterances
  # into twos, and treats each of these pairs as one speaker.  Note that these
  # are extracted 'online'.

  # having a larger number of speakers is helpful for generalization, and to
  # handle per-utterance decoding well (iVector starts at zero).
  steps/online/nnet2/copy_data_dir.sh --utts-per-spk-max 2 data/vocal/ori_train_clean data/vocal/train_clean_max2
  
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjob \
    data/vocal/train_clean_max2 exp/vocal/nnet2_online/extractor $ivectordir || exit 1;
fi

if [ $stage -le 7 ]; then
  ivectordir=exp/vocal/nnet2_online/ivectors_all_clean
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $ivectordir/storage ]; then
    utils/create_split_dir.pl /export/b0{1,2,3,4}/$USER/kaldi-data/egs/librispeech-$(date +'%m_%d_%H_%M')/s5/$ivectordir/storage $ivectordir/storage
  fi
  # We extract iVectors on all the train data, which will be what we train the
  # system on.  With --utts-per-spk-max 2, the script.  pairs the utterances
  # into twos, and treats each of these pairs as one speaker.  Note that these
  # are extracted 'online'.

  # having a larger number of speakers is helpful for generalization, and to
  # handle per-utterance decoding well (iVector starts at zero).
  steps/online/nnet2/copy_data_dir.sh --utts-per-spk-max 2 data/vocal/all_clean data/vocal/all_clean_max2
  
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjob \
    data/vocal/all_clean_max2 exp/vocal/nnet2_online/extractor $ivectordir || exit 1;
fi

exit 0;
