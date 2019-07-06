#!/bin/bash
storedir=/data/groups/hao246
datadir=/data/groups/hao246/singing-voice-recog/data
expdir=/data/groups/hao246/singing-voice-recog/exp
mfccdir=/data/groups/hao246/singing-voice-recog/mfcc
lyriclmdir=/data/groups/hao246/lyric_corpus/lm

. cmd.sh
. new_path.sh

# when "--stage 3" option is used below we skip the G2P steps, and use the
# lexicon we have already downloaded from openslr.org/11/
local/prepare_dict.sh --stage 1 --nj 10 --cmd "$train_cmd" \
   $lyriclmdir $datadir/local/lm $datadir/local/dict_lyric2
old_steps_and_utils/utils/prepare_lang.sh --phone-symbol-table $datadir/lang/phones.txt $datadir/local/dict_lyric_exten \
  "<UNK>" $datadir/local/lang_tmp_lyric_exten $datadir/lang_lyric_exten

local/format_lms_new.sh --src-dir $datadir/lang_lyric_exten $lyriclmdir

#utils/build_const_arpa_lm.sh $datadir/local/lm/lm_tglarge.arpa.gz \
#  $datadir/lang_nosp $datadir/lang_nosp_test_tglarge
#utils/build_const_arpa_lm.sh $datadir/local/lm/lm_fglarge.arpa.gz \
#  $datadir/lang_nosp $datadir/lang_nosp_test_fglarge


# Create ConstArpaLm format language model for full 3-gram and 4-gram LMs
#utils/build_const_arpa_lm.sh $lyriclmdir/lm_tglarge.arpa.gz \
#  $datadir/lang_nosp $datadir/lang_lyric_test_tglarge
#utils/build_const_arpa_lm.sh $lyriclmdir/lm_fglarge.arpa.gz \
#  $datadir/lang_nosp $datadir/lang_lyric_test_fglarge
