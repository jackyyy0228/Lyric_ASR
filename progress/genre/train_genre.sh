#!/bin/bash
storedir=/data/groups/hao246
datadir=$storedir/singing-voice-recog/data
expdir=$storedir/singing-voice-recog/exp
mfccdir=$storedir/singing-voice-recog/mfcc

if [ $# -ne 2 ]; then
  echo "Usage: $0 <stage> <genre>"
  echo "e.g.: $0 3 pop"
  exit 1
fi

stage=$1
genre=$2

storePath=$storedir/vocal_data/genre/
trainingdata=$datadir/genre/$genre\_train_clean
testingdata=$datadir/genre/$genre\_test_clean
langmodel=$datadir/lang_lyric
prefix=v
#Model trained by totally vocal data : v
#Model trained by speech and adapted by vocal data : sv
#Model trained by speech or vocal  and adapted by genre data : gv
suffix=$genre
nj=3

. cmd.sh
. path.sh
if [ $genre == "all" ]; then
  trainingdata=$datadir/vocal/train_clean
fi

echo "Running $0 $genre"

if [ $stage -le 0 ]; then
    for part in $genre\_train_clean $genre\_test_clean ; do
        echo "preparing mfcc of $part"
        audio=$storePath/$part
        mfcc=$datadir/genre/$part
        makemfccexp=$expdir/make_mfcc/genre/$part
        mfccdir=$mfccdir/genre
        local/vocaldata_prep.sh $audio $mfcc || exit 1;
        old_steps_and_utils/steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj $mfcc $makemfccexp $mfccdir
        old_steps_and_utils/steps/compute_cmvn_stats.sh $mfcc $makemfccexp $mfccdir
    done
fi

if [ $stage -le 1 ]; then
    # train a monophone system
    echo "training monophone model"
    monoexp=$expdir/genre/$prefix\mono_$suffix
    sialiexp=$expdir/genre/$prefix\mono_ali_$suffix
    steps/train_mono.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
        $trainingdata $langmodel $monoexp || exit 1;
fi

if [ $stage -le 2 ]; then
    # train a first delta + delta-delta triphone system
    echo "training monophone model"
    monoexp=$expdir/genre/$prefix\mono_$suffix
    monoaliexp=$expdir/genre/$prefix\mono_ali_$suffix
    tri1exp=$expdir/genre/$prefix\tri1_$suffix
    steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
        $trainingdata $langmodel $monoexp $monoaliexp
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
        2000 10000 $trainingdata $langmodel $monoaliexp $tri1exp || exit 1;
fi

if [ $stage -le 3 ]; then
    tri1exp=$expdir/genre/$prefix\tri1_$suffix
    tri1aliexp=$expdir/genre/$prefix\tri1_ali_$suffix
    tri2bexp=$expdir/genre/$prefix\tri2b_$suffix
    tri2baliexp=$expdir/genre/$prefix\tri2b_ali_$suffix
    tri3bexp=$expdir/genre/$prefix\tri3b_$suffix
    tri3baliexp=$expdir/genre/$prefix\tri3b_ali_$suffix

    steps/align_si.sh --nj $nj --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $trainingdata $langmodel $tri1exp $tri1aliexp || exit 1;
    # train an LDA+MLLT system.
    steps/train_lda_mllt.sh --cmd "$train_cmd" \
        --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
        $trainingdata $langmodel $tri1aliexp $tri2bexp || exit 1;
    steps/align_si.sh  --nj $nj --cmd "$train_cmd" --use-graphs true --beam 40 --retry_beam 80 \
        $trainingdata $langmodel $tri2bexp $tri2baliexp || exit 1;
    # Train tri3b, which is LDA+MLLT+SAT on 10k utts
    steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
        $trainingdata $langmodel $tri2baliexp $tri3bexp || exit 1;
    steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $trainingdata $langmodel $tri3bexp $tri3baliexp || exit 1;
fi
