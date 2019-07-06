#!/bin/bash
storedir=/data1/hao246
datadir=/data1/hao246/singing-voice-recog/data
expdir=/data1/hao246/singing-voice-recog/exp
nnet2expdir=/data/hao246/singing-voice-recog/exp
mfccdir=/data1/hao246/singing-voice-recog/mfcc


. cmd.sh
. path.sh

stage=3
# audio alignment
# using speech lm
# for auto-claculate the velocity of a clip

# format the data as Kaldi data directories
if [ $stage -le 1 ]; then
    local/vocaldata_prep.sh $storedir/vocal_data/all $datadir/vocal/all || exit 1;

    steps/make_mfcc.sh --cmd "$train_cmd" --nj 10 $datadir/vocal/all $expdir/make_mfcc/vocal/all $mfccdir/vocal
    steps/compute_cmvn_stats.sh $datadir/vocal/all $expdir/make_mfcc/vocal/all $mfccdir/vocal
fi

if [ $stage -ge 3 ]; then
    # use monophone model, trained on 2k utterance
    #steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
    #    $datadir/vocal/all $datadir/lang_nosp $expdir/speech/mono $expdir/vocal/mono_ali || exit 1;

    # use delta + delta-delta triphone system, trained on 5k utterance
    #steps/align_si.sh --nj 10 --cmd "$train_cmd" \
    #    $datadir/vocal/all $datadir/lang_nosp $expdir/speech/tri1 $expdir/vocal/tri1_ali || exit 1;

    # use an LDA+MLLT system, trained on 10k utterance
    #steps/align_si.sh  --nj 10 --cmd "$train_cmd" \
    #  $datadir/vocal/all $datadir/lang_nosp $expdir/speech/tri2b $expdir/vocal/tri2b_ali || exit 1;

    # use an LDA+MLLT+SAT system, trained on 10k utterance
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
      $datadir/vocal/all $datadir/lang_nosp \
      $expdir/speech/tri3b $expdir/vocal/tri3b_ali || exit 1;

    # use an LDA+MLLT+SAT system, trained on 100 hours speech
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
      $datadir/vocal/all $datadir/lang $expdir/speech/tri4b $expdir/vocal/tri4b_ali || exit 1;
fi

if [ $stage -ge 5 ]; then
    steps/nnet2/align.sh --nj 10 --cmd "$train_cmd" \
      $datadir/vocal/all $datadir/lang $nnet2expdir/speech/nnet5a_clean_100_gpu $expdir/vocal/nnet5a_ali || exit 1;
fi
