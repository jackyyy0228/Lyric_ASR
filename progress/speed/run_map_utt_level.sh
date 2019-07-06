#!/bin/bash
storedir=/data/groups/hao246
datadir=$storedir/singing-voice-recog/data
expdir=$storedir/singing-voice-recog/exp
mfccdir=$storedir/singing-voice-recog/mfcc

echo "$0 $@"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <stage>"
  echo "e.g.: $0 3 "
  exit 1
fi


stage=$1
genre=$2

storePath=$storedir/vocal_data/speed
traindata=$datadir/speed/train_
testdata=$datadir/speed/test_
langmodel=$datadir/lang_lyric
prefix=v
#Model trained by totally vocal data : v
#Model trained by speech and adapted by vocal data : sv
#Model trained by speech or vocal  and adapted by genre data : gv
nj=4

. cmd.sh
. path.sh
if [ $stage -le -3 ]; then
  for cleanset in train_fast train_slow test_fast test_slow 
  do
    audio=$storedir/vocal_data/$cleanset
    trainset=$datadir/speed/$cleanset  #here
    results=$expdir/make_mfcc/speed/$cleanset
    mfcc=$mfccdir/speed
    local/uttadp_data_prep.sh $audio $trainset || exit 1;
    old_steps_and_utils/steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj \
      $trainset $results $mfcc || exit 1;
    old_steps_and_utils/steps/compute_cmvn_stats.sh \
      $trainset $results $mfcc || exit 1;
  done
fi

trainclean=$datadir/vocal/uttadp_train_clean
testclean=$datadir/vocal/uttadp_test_clean
if [ $stage -le -2 ]; then
  tri2bexp=$expdir/speed/tri2b_song_level
  lm=$datadir/lang_lyric
  ali=$expdir/speed/tri2b_ali
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
     $trainclean $lm $tri2bexp $ali || exit 1;
fi

# train LDA+MLLT+SAT
# called tri3b
#TODO : Train triphone with aligned model
if [ $stage -le -1 ]; then
  tri2bexp=$expdir/speed/tri2b_song_level
  lm=$datadir/lang_lyric
  ali=$expdir/speed/tri2b_ali
  mdl=$expdir/speed/tri3b_utt
  steps/train_sat.sh --cmd "$train_cmd" 2500 15000 \
    $trainclean $lm $ali $mdl || exit 1;
fi
# adapting fast and slow data 
if [ $stage -le 0 ]; then
    for suffix in fast slow 
    do
      tri3bexp=$expdir/speed/tri3b_utt
      tri3baliexp=$expdir/speed/tri3b_ali_$suffix
      mapexp=$expdir/speed/tri4b_map_utt_$suffix
      trainingdata=$traindata$suffix

      steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" --beam 40 --retry_beam 80 \
          $trainingdata $langmodel $tri3bexp $tri3baliexp || exit 1;
      steps/train_map.sh --cmd "$train_cmd"  \
          $trainingdata $langmodel $tri3baliexp $mapexp || exit 1;
    done
fi

#decode using three model: map_fast map_slow tri3b(original)
if [ $stage -le 1 ]; then
  result=./result.txt
  for model in fast slow 
  do
    mapexp=$expdir/speed/tri4b_map_utt_$model
    if [ $model == ori ]; then
      mapexp=$expdir/speed/tri3b_utt
      testingdata=$testclean
      utils/mkgraph.sh $langmodel\_test_tgsmall \
        $mapexp $mapexp/graph_tgsmall
      small=$mapexp/decode_fmllr_test_$suffix\_tgsmall
      mid=$mapexp/decode_fmllr_test_$suffix\_tgmed
      if [ ! -f $small/lat.1.gz ]; then
        steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
          $mapexp/graph_tgsmall $testingdata \
          $small || exit 1;
        steps/lmrescore.sh --cmd "$decode_cmd" $langmodel\_test_{tgsmall,tgmed} \
          $testingdata $small $mid  || exit 1;
        progress/cal_wer.sh $small >> $result
        progress/cal_wer.sh $mid >> $result
      fi
    fi
    for suffix in fast slow 
    do
      testingdata=$testdata$suffix
      utils/mkgraph.sh $langmodel\_test_tgsmall \
        $mapexp $mapexp/graph_tgsmall
      small=$mapexp/decode_fmllr_test_$suffix\_tgsmall
      mid=$mapexp/decode_fmllr_test_$suffix\_tgmed
      if [ ! -f $small/lat.1.gz ]; then
        steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
          $mapexp/graph_tgsmall $testingdata \
          $small || exit 1;
        steps/lmrescore.sh --cmd "$decode_cmd" $langmodel\_test_{tgsmall,tgmed} \
          $testingdata $small $mid  || exit 1;
        progress/cal_wer.sh $small >> $result
        progress/cal_wer.sh $mid >> $result
      fi
    done
  done
fi
