#!/bin/bash
. ./cmd.sh
. ./path.sh

data=data/paper
for dir in train_clean_utt test_clean_utt;do
  fbank=$data/${dir}_fbank_mel_bin40
  utils/copy_data_dir.sh $data/$dir $fbank || exit 1; 
  rm $fbank/{cmvn,feats}.scp
  steps/make_fbank.sh --nj 8 --cmd "$train_cmd" \
     $fbank $fbank/log $fbank/data || exit 1;
  steps/compute_cmvn_stats.sh $fbank $fbank/log $fbank/data || exit 1;
  cp conf/fbank.conf $fbank/fbank.conf
done

