#!/bin/bash
storedir=/data/datasets/hao246
datadir=/data/datasets/hao246/singing-voice-recog/data
expdir=/data/datasets/hao246/singing-voice-recog/exp
mfccdir=/data/datasets/hao246/singing-voice-recog/mfcc

. cmd.sh
. path.sh

#progress/train_mono.sh --boost-silence 1.0 --nj 10 --cmd "$train_cmd" \
#    $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vmono_sil_1_0 || exit 1;
progress/train_mono.sh --boost-silence 1.5 --nj 6 --cmd "$train_cmd" \
    $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vmono_sil_1_5 || exit 1;
progress/train_mono.sh --boost-silence 1.5 --nj 6 --cmd "$train_cmd" \
    $datadir/vocal/train_clean $datadir/lang_lyric $expdir/vocal/vmono_sil_1_5_lyric || exit 1;
