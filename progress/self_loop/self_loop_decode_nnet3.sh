#!/bin/bash

. cmd.sh
. path.sh

echo "$0 $@"


numjob=4
test_sets=paper/test_clean_utt
test_data_dir=data/${test_sets}_hires

#TODO : Train triphone with aligned model
for scale in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 ; do
    mdl=exp/nnet3/blstm/layer3_epoch7_celldim400_rp100_ld5/
    graph=exp/paper/vowel_loop/tri3b_utt2/graph_tgsmall_$scale
    
    num_jobs=6
    steps/nnet3/decode.sh --nj $num_jobs --cmd "$decode_cmd" \
      --extra-left-context 40 \
      --extra-right-context 0 \
      --frames-per-chunk 20  \
      --online-ivector-dir exp/nnet3/ivectors_paper/test_clean_utt_hires \
       $graph $test_data_dir $mdl/decode_$scale || exit 1;
done
