#!/bin/bash
storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
expdir=/data1/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc


. cmd.sh
. path.sh


# Now we compute the pronunciation and silence probabilities from training $datadir,
# and re-create the lang directory.
steps/get_prons.sh --cmd "$train_cmd" \
  $datadir/speech/train_clean_100 $datadir/lang_nosp $expdir/speech/tri4b
utils/dict_dir_add_pronprobs.sh --max-normalize true \
  $datadir/local/dict_nosp \
  $expdir/speech/tri4b/pron_counts_nowb.txt $expdir/speech/tri4b/sil_counts_nowb.txt \
  $expdir/speech/tri4b/pron_bigram_counts_nowb.txt $datadir/local/dict || exit 1

utils/prepare_lang.sh $datadir/local/dict \
  "<SPOKEN_NOISE>" $datadir/local/lang_tmp $datadir/lang
local/format_lms.sh --src-dir $datadir/lang $datadir/local/lm

utils/build_const_arpa_lm.sh \
  $datadir/local/lm/lm_tglarge.arpa.gz $datadir/lang $datadir/lang_test_tglarge || exit 1;
