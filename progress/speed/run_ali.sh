
#!/bin/bash
storedir=/data/groups/hao246
datadir=$storedir/singing-voice-recog/data
expdir=$storedir/singing-voice-recog/exp
mfccdir=$storedir/singing-voice-recog/mfcc


storePath=$storedir/vocal_data/genre/
trainingdata=$datadir/vocal/train_clean
testingdata=$datadir/vocal/test_clean
langmodel=$datadir/lang_lyric
nj=4
stage=0
. cmd.sh
. path.sh
if [ $stage -le 0 ]; then
    tri3bexp=$expdir/genre/map/svtri3b_svtri1_1k_5k_exp3/
    tri3balitrain=$expdir/speed/tri3b_ali_train
    tri3balitest=$expdir/speed/tri3b_ali_test
    steps/align_si.sh --nj $nj --cmd "$train_cmd" --beam 40 --retry_beam 300 \
        $trainingdata $langmodel $tri3bexp $tri3balitrain || exit 1;
    for i in $tri3balitrain/ali.*.gz; do
      ali-to-phones --ctm-output $tri3balitrain/final.mdl "ark:gunzip -c $i |"  ${i%.gz}.ctm;
    done
    cat $tri3balitrain/*.ctm > train_ali.ctm

    steps/align_si.sh --nj $nj --cmd "$train_cmd" --beam 40 --retry_beam 300 \
        $testingdata $langmodel $tri3bexp $tri3balitest || exit 1;
    for i in $tri3balitest/ali.*.gz; do
      ali-to-phones --ctm-output $tri3balitest/final.mdl "ark:gunzip -c $i |"  ${i%.gz}.ctm;
    done
    cat $tri3balitest/*.ctm > test_ali.ctm
fi
