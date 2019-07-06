#!/bin/bash

# this script contains some common (shared) parts of the run_nnet*.sh scripts.

. cmd.sh


stage=0
numjob=6
trainset=data/paper/train_clean_utt
mdl=exp/paper/tri3b_utt
ubm=exp/paper/nnet_ivec_online/diag_ubm
extractor=exp/paper/nnet_ivec_online/extractor
ivec_train=exp/paper/nnet_ivec_online/ivec_train
ivec_test=exp/paper/nnet_ivec_online/ivec_test

set -e
. cmd.sh
. ./path.sh
. ./utils/parse_options.sh


if [ $stage -le 4 ]; then
  mkdir -p exp/paper/nnet_ivec
  steps/online/nnet2/train_diag_ubm.sh --cmd "$train_cmd" --nj $numjob --num-frames 200000 \
    $trainset 256 $mdl $ubm
fi

if [ $stage -le 5 ]; then
  steps/online/nnet2/train_ivector_extractor.sh --cmd "$train_cmd" --nj $numjob \
    --ivector-dim 50 \
    $trainset $ubm $extractor || exit 1;
fi

if [ $stage -le 7 ]; then
  # We extract iVectors on all the train data, which will be what we train the
  # system on.  With --utts-per-spk-max 2, the script.  pairs the utterances
  # into twos, and treats each of these pairs as one speaker.  Note that these
  # are extracted 'online'.

  # having a larger number of speakers is helpful for generalization, and to
  # handle per-utterance decoding well (iVector starts at zero).
  steps/online/nnet2/copy_data_dir.sh --utts-per-spk-max 2 data/paper/train_clean_utt data/paper/train_clean_utt_max2
  
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjob \
    data/paper/train_clean_utt_max2 $extractor $ivec_train || exit 1;
  
  steps/online/nnet2/copy_data_dir.sh --utts-per-spk-max 2 data/paper/test_clean_utt data/paper/test_clean_utt_max2
  
  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $numjob \
    data/paper/test_clean_utt_max2 $extractor $ivec_test || exit 1;
fi

exit 0;
