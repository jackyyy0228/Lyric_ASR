#!/bin/bash
storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
expdir=/data1/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc


. cmd.sh
. path.sh



for param in `seq 1 1`; do
    scale_opts="--transition-scale=1.0 --acoustic-scale=0.07 --self-loop-scale=0.$param"
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
        --scale_opts "$scale_opts" \
        --beam 40 --retry_beam 80 \
        --boost_silence 1.0 \
        $datadir/vocal/train_clean $datadir/lang_lyric \
        $expdir/speech/tri3b $expdir/vocal/tri3b_ali_clean_a7_l$param || exit 1;
done
