#!/bin/bash
storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
expdir=/data1/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc


. cmd.sh
. path.sh

sleep 6h
# format the data as Kaldi data directories
for part in dev-clean test-clean dev-other test-other train-clean-100; do
  # use underscore-separated names in data directories.
  local/data_prep.sh $storedir/LibriSpeech/$part $datadir/speech/$(echo $part | sed s/-/_/g) || exit 1
done

# when "--stage 3" option is used below we skip the G2P steps, and use the
# lexicon we have already downloaded from openslr.org/11/
local/prepare_dict.sh --stage 3 --nj 3 --cmd "$train_cmd" \
   $datadir/local/lm $datadir/local/lm $datadir/local/dict_nosp

utils/prepare_lang.sh $datadir/local/dict_nosp \
  "<UNK>" $datadir/local/lang_tmp_nosp $datadir/lang_nosp

local/format_lms.sh --src-dir $datadir/lang_nosp $datadir/local/lm

# Create ConstArpaLm format language model for full 3-gram
utils/build_const_arpa_lm.sh $datadir/local/lm/lm_tglarge.arpa.gz \
  $datadir/lang_nosp $datadir/lang_nosp_test_tglarge


for part in dev_clean test_clean dev_other test_other train_clean_100; do
  steps/make_mfcc.sh --cmd "$train_cmd" --nj 4 $datadir/speech/$part $expdir/make_mfcc/speech/$part $mfccdir/speech
  steps/compute_cmvn_stats.sh $datadir/speech/$part $expdir/make_mfcc/speech/$part $mfccdir/speech
done

utils/subset_data_dir.sh --shortest $datadir/speech/train_clean_100 2000 $datadir/speech/train_2kshort
utils/subset_data_dir.sh $datadir/speech/train_clean_100 5000 $datadir/speech/train_5k
utils/subset_data_dir.sh $datadir/speech/train_clean_100 10000 $datadir/speech/train_10k
