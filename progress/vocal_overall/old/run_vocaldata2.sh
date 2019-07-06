#!/bin/bash
storedir=/data/datasets/hao246
datadir=/data/datasets/hao246/singing-voice-recog/data
expdir=/data/datasets/hao246/singing-voice-recog/exp
mfccdir=/data/datasets/hao246/singing-voice-recog/mfcc


. cmd.sh
. path.sh

stage=7

if [ $stage -le 0 ]; then
    for part in train_clean test_clean train_other test_other; do
        local/vocaldata_prep.sh $storedir/vocal_data/$part $datadir/vocal/$part || exit 1;
        steps/make_mfcc.sh --cmd "$train_cmd" --nj 10 $datadir/vocal/$part $expdir/make_mfcc/vocal/$part $mfccdir/vocal
        steps/compute_cmvn_stats.sh $datadir/vocal/$part $expdir/make_mfcc/vocal/$part $mfccdir/vocal
    done
fi

if [ $stage -le 1 ]; then
    # train a monophone system
    steps/train_mono.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vmono || exit 1;
    steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/all $datadir/lang_nosp $expdir/vocal/vmono $expdir/vocal/vmono_ali_all
fi

if [ $stage -le 2 ]; then
    # train a first delta + delta-delta triphone system
    steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vmono $expdir/vocal/vmono_ali
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
        2000 10000 $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vmono_ali $expdir/vocal/vtri1 || exit 1;
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/all $datadir/lang_nosp $expdir/vocal/vtri1 $expdir/vocal/vtri1_ali_all || exit 1;
fi

if [ $stage -le 3 ]; then
    steps/align_si.sh --nj 10 --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vtri1 $expdir/vocal/vtri1_ali || exit 1;
    # train an LDA+MLLT system.
    steps/train_lda_mllt.sh --cmd "$train_cmd" \
        --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vtri1_ali $expdir/vocal/vtri2b || exit 1;
    steps/align_si.sh  --nj 10 --cmd "$train_cmd" --use-graphs true --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vtri2b $expdir/vocal/vtri2b_ali || exit 1;
    # Train tri3b, which is LDA+MLLT+SAT on 10k utts
    steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vtri2b_ali $expdir/vocal/vtri3b || exit 1;
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_nosp \
        $expdir/vocal/vtri3b $expdir/vocal/vtri3b_ali || exit 1;
fi

if [ $stage -le 4 ]; then
    utils/subset_data_dir.sh --shortest $datadir/vocal/train_clean 200 $datadir/vocal/train_200short
    # train a monophone system
    steps/train_mono.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/train_200short $datadir/lang_nosp $expdir/vocal/vmono_200short || exit 1;
    steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vmono_200short $expdir/vocal/vmono_ali
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
        2000 10000 $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/vmono_ali $expdir/vocal/vtri1 || exit 1;
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/all $datadir/lang_nosp $expdir/vocal/vtri1 $expdir/vocal/vtri1_ali_all || exit 1;
fi

if [ $stage -le 5 ]; then
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/all $datadir/lang_nosp \
        $expdir/speech/tri3b $expdir/vocal/tri3b_ali_all || exit 1;
    # train another LDA+MLLT+SAT system
    steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
        $datadir/vocal/train_clean $datadir/lang_nosp \
        $expdir/vocal/tri3b_ali_clean $expdir/vocal/svtri4b || exit 1;
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
        $datadir/vocal/all $datadir/lang_nosp $expdir/vocal/svtri4b $expdir/vocal/svtri4b_ali_all || exit 1;
fi

if [ $stage -le 6 ]; then
    # train a first delta + delta-delta triphone system
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
        2000 10000 $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/tri3b_ali_clean $expdir/vocal/svtri1 || exit 1;
    steps/align_si.sh --nj 10 --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/svtri1 $expdir/vocal/svtri1_ali || exit 1;
    # train an LDA+MLLT system.
    steps/train_lda_mllt.sh --cmd "$train_cmd" \
        --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/svtri1_ali $expdir/vocal/svtri2b || exit 1;
    #this one
    steps/align_si.sh  --nj 10 --cmd "$train_cmd" --use-graphs true --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/svtri2b $expdir/vocal/svtri2b_ali || exit 1;
    # Train tri3b, which is LDA+MLLT+SAT on 10k utts
    steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
        $datadir/vocal/train_clean $datadir/lang_nosp $expdir/vocal/svtri2b_ali $expdir/vocal/svtri3b || exit 1;
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_nosp \
        $expdir/vocal/svtri3b $expdir/vocal/svtri3b_ali || exit 1;
fi

if [ $stage -le 7 ]; then
    # train a first delta + delta-delta triphone system
    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
        2000 10000 $datadir/vocal/train_clean $datadir/lang_lyric $expdir/vocal/tri3b_ali_clean $expdir/vocal/svtri1_lyric || exit 1;
    steps/align_si.sh --nj 10 --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_lyric $expdir/vocal/svtri1_lyric $expdir/vocal/svtri1_lyric_ali || exit 1;
    # train an LDA+MLLT system.
    steps/train_lda_mllt.sh --cmd "$train_cmd" \
        --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
        $datadir/vocal/train_clean $datadir/lang_lyric $expdir/vocal/svtri1_lyric_ali $expdir/vocal/svtri2b_lyric || exit 1;
    steps/align_si.sh  --nj 10 --cmd "$train_cmd" --use-graphs true --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_lyric $expdir/vocal/svtri2b_lyric $expdir/vocal/svtri2b_lyric_ali || exit 1;
    # Train tri3b, which is LDA+MLLT+SAT on 10k utts
    steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
        $datadir/vocal/train_clean $datadir/lang_lyric $expdir/vocal/svtri2b_lyric_ali $expdir/vocal/svtri3b_lyric || exit 1;
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" --beam 40 --retry_beam 80 \
        $datadir/vocal/train_clean $datadir/lang_lyric \
        $expdir/vocal/svtri3b_lyric $expdir/vocal/svtri3b_lyric_ali || exit 1;
fi
