#!/bin/bash

datadir=/data/datasets/hao246/singing-voice-recog/data
expdir=/data/datasets/hao246/singing-voice-recog/exp
nnet2expdir=/data/datasets/hao246/singing-voice-recog/exp

. cmd.sh
. path.sh

stage=3

# phone-level
if [ $stage -le 1 ]; then
    for i in $expdir/vocal/nnet5a_ali/ali.*.gz; do
        ali-to-phones --ctm-output $expdir/vocal/nnet5a_ali/final.mdl ark:"gunzip -c %i|" -> ${i%.gz}.ctm;
    done
    cat $expdir/vocal/nnet5a_ali/*.gz.ctm > all_phone_ali.ctm
fi

# word-level
if [ $stage -le 2 ]; then
    for p in `seq 1 9`; do
        part="tri3b_ali_clean_a7_l$p"
        steps/get_train_ctm.sh --cmd "$train_cmd" $datadir/vocal/train_clean $datadir/lang $expdir/vocal/$part
        cp $expdir/vocal/$part/ctm ../vocal_ali/ctm/ctm-tri3b-clean-a7-l$p
    done
fi

if [ $stage -le 3 ]; then
    #for part in vmono vtri1 vtri2b vtri3b svtri1b svtri2b svtri3b svtri4b svtri1_lyric svtri2b_lyric svtri3b_lyric; do
    #for part in vmono_sil_1_0 vmono_sil_1_5 vmono_sil_1_5_lyric; do
    #for part in svtri1_ali svtri1_lyric_ali svtri2b_ali svtri2b_lyric_ali svtri3b_ali svtri3b_lyric_ali; do
    #for part in mono_ali tri1_ali tri2b_ali tri3b_ali tri4b_ali nnet5a_ali; do
    for part in labeled_mono_ali; do
        steps/get_train_ctm.sh --cmd "$train_cmd" $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/$part
        cp $expdir/vocal/$part/ctm vocal_ali/test_sil_ctm/words/ctm-$part
    done
    python3 vocal_ali/WCAA.py --data-dir=vocal_ali/labeledData --model-dir=vocal_ali/test_sil_ctm/words --output-dir=vocal_ali/test_result
fi
#steps/get_train_ctm.sh --cmd "$train_cmd" $datadir/vocal/all $datadir/lang $expdir/vocal/nnet5a_ali
