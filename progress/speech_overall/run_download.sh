#!/bin/bash
datadir=/data1/hao246
if [ -f $datadir ]; then mkdir $datadir; fi
data_url=www.openslr.org/resources/12
lm_url=www.openslr.org/resources/11

. path.sh
. cmd.sh

#for part in dev-clean test-clean dev-other test-other train-clean-100; do
#  local/download_and_untar.sh $datadir $data_url $part
#done

#local/download_lm.sh $lm_url ./lm || exit 1

for part in dev-clean test-clean dev-other test-other train-clean-100; do
  local/data_prep.sh $datadir/LibriSpeech/$part data/$(echo $part | sed s/-/_/g) || exit 1
done

local/prepare_dict.sh --stage 3 --nj 4 --cmd "$train_cmd" \
   data/local/lm data/local/lm data/local/dict_nosp || exit 1

utils/prepare_lang.sh data/local/dict_nosp \
  "<SPOKEN_NOISE>" data/local/lang_tmp_nosp data/lang_nosp || exit 1;

local/format_lms.sh --src-dir data/lang_nosp data/local/lm || exit 1
