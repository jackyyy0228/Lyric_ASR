#!/bin/bash


# run_tdnn_lstm_1a.sh is a TDNN+LSTM system.  Compare with the TDNN
# system in run_tdnn_1a.sh.  Configuration is similar to
# the same-named script run_tdnn_lstm_1a.sh in
# egs/tedlium/s5_r2/local/nnet3/tuning.

# It's a little better than the TDNN-only script on dev93, a little
# worse on eval92.

# steps/info/nnet3_dir_info.pl exp/nnet3/tdnn_lstm1a_sp
# exp/nnet3/tdnn_lstm1a_sp: num-iters=102 nj=3..10 num-params=8.8M dim=40+100->3413 combine=-0.55->-0.54 loglike:train/valid[67,101,combined]=(-0.63,-0.55,-0.55/-0.71,-0.63,-0.63) accuracy:train/valid[67,101,combined]=(0.80,0.82,0.82/0.76,0.78,0.78)



# local/nnet3/compare_wer.sh --looped --online exp/nnet3/tdnn1a_sp exp/nnet3/tdnn_lstm1a_sp 2>/dev/null
# local/nnet3/compare_wer.sh --looped --online exp/nnet3/tdnn1a_sp exp/nnet3/tdnn_lstm1a_sp
# System                tdnn1a_sp tdnn_lstm1a_sp
#WER dev93 (tgpr)                9.18      8.54
#             [looped:]                    8.54
#             [online:]                    8.57
#WER dev93 (tg)                  8.59      8.25
#             [looped:]                    8.21
#             [online:]                    8.34
#WER dev93 (big-dict,tgpr)       6.45      6.24
#             [looped:]                    6.28
#             [online:]                    6.40
#WER dev93 (big-dict,fg)         5.83      5.70
#             [looped:]                    5.70
#             [online:]                    5.77
#WER eval92 (tgpr)               6.15      6.52
#             [looped:]                    6.45
#             [online:]                    6.56
#WER eval92 (tg)                 5.55      6.13
#             [looped:]                    6.08
#             [online:]                    6.24
#WER eval92 (big-dict,tgpr)      3.58      3.88
#             [looped:]                    3.93
#             [online:]                    3.88
#WER eval92 (big-dict,fg)        2.98      3.38
#             [looped:]                    3.47
#             [online:]                    3.53
# Final train prob        -0.7200   -0.5492
# Final valid prob        -0.8834   -0.6343
# Final train acc          0.7762    0.8154
# Final valid acc          0.7301    0.7849


set -e -o pipefail

# First the options that are passed through to run_ivector_common.sh
# (some of which are also used in this script directly).
stage=9
nj=4
train_set=paper/train_clean_utt
test_sets=paper/test_clean_utt
gmm=paper/tri3b_utt        # this is the source gmm-dir that we'll use for alignments; it
                 # should have alignments for the specified training data.
num_threads_ubm=1
nnet3_affix=       # affix for exp dirs, e.g. it was _cleaned in tedlium.

# Options which are not passed through to run_ivector_common.sh
affix=wsj_1a  #affix for TDNN+LSTM directory e.g. "1a" or "1b", in case we change the configuration.
common_egs_dir=
reporting_email=

# LSTM options
train_stage=-10
label_delay=5

# training chunk-options
chunk_width=40,30,20
chunk_left_context=40
chunk_right_context=0

# training options
srand=0
remove_egs=true

#decode options
test_online_decoding=false  # if true, it will run the last decoding stage.

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

#tune
epoch=$1
lstmdim=$2
rpdim=$3

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

progress/nnet3/run_ivector_common_wsj.sh \
  --stage $stage --nj $nj \
  --train-set $train_set --gmm $gmm \
  --ivector-dim 50 \
  --num-threads-ubm $num_threads_ubm \
  --nnet3-affix "$nnet3_affix"



gmm_dir=exp/${gmm}
ali_dir=exp/nnet3/tri3b_ali_sp
lang=data/lang_lyric_exten
dir=exp/nnet3/lstm/layer4_epoch${epoch}_lstmdim${lstmdim}_rpdim${rpdim}
train_data_dir=data/${train_set}_sp_hires
train_ivector_dir=exp/nnet3/ivectors_${train_set}_sp_hires

for f in $train_data_dir/feats.scp $train_ivector_dir/ivector_online.scp \
    $gmm_dir/graph_tgsmall/HCLG.fst \
    $ali_dir/ali.1.gz $gmm_dir/final.mdl; do
  [ ! -f $f ] && echo "$0: expected file $f to exist" && exit 1
done

if [ $stage -le 12 ]; then
  mkdir -p $dir
  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $ali_dir/tree |grep num-pdfs|awk '{print $2}')

  mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig
  input dim=50 name=ivector
  input dim=40 name=input

  # please note that it is important to have input layer with the name=input
  # as the layer immediately preceding the fixed-affine-layer to enable
  # the use of short notation for the descriptor
  fixed-affine-layer name=lda input=Append(-2,-1,0,1,2,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat delay=$label_delay

  # the first splicing is moved before the lda layer, so no splicing here
  fast-lstmp-layer name=lstm1 cell-dim=$lstmdim recurrent-projection-dim=$rpdim non-recurrent-projection-dim=$rpdim decay-time=20 delay=-3
  fast-lstmp-layer name=lstm2 cell-dim=$lstmdim recurrent-projection-dim=$rpdim non-recurrent-projection-dim=$rpdim decay-time=20 delay=-3
  fast-lstmp-layer name=lstm3 cell-dim=$lstmdim recurrent-projection-dim=$rpdim non-recurrent-projection-dim=$rpdim decay-time=20 delay=-3
  fast-lstmp-layer name=lstm4 cell-dim=$lstmdim recurrent-projection-dim=$rpdim non-recurrent-projection-dim=$rpdim decay-time=20 delay=-3


  output-layer name=output input=lstm4 output-delay=$label_delay dim=$num_targets max-change=1.5

EOF
  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi


if [ $stage -le 13 ]; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
     /export/b0{3,4,5,6}/$USER/kaldi-data/egs/tedlium-$(date +'%m_%d_%H_%M')/s5_r2/$dir/egs/storage $dir/egs/storage
  fi

  steps/nnet3/train_rnn.py --stage=$train_stage \
    --cmd="$decode_cmd" \
    --feat.online-ivector-dir=$train_ivector_dir \
    --feat.cmvn-opts="--norm-means=false --norm-vars=false" \
    --trainer.srand=$srand \
    --trainer.max-param-change=2.0 \
    --trainer.num-epochs=$epoch \
    --trainer.deriv-truncate-margin=10 \
    --trainer.samples-per-iter=20000 \
    --trainer.optimization.num-jobs-initial=2 \
    --trainer.optimization.num-jobs-final=2 \
    --trainer.optimization.initial-effective-lrate=0.0003 \
    --trainer.optimization.final-effective-lrate=0.00003 \
    --trainer.optimization.shrink-value 0.99 \
    --trainer.rnn.num-chunk-per-minibatch=128,64 \
    --trainer.optimization.momentum=0.5 \
    --egs.chunk-width=$chunk_width \
    --egs.chunk-left-context=$chunk_left_context \
    --egs.chunk-right-context=$chunk_right_context \
    --egs.chunk-left-context-initial=0 \
    --egs.chunk-right-context-final=0 \
    --egs.dir="$common_egs_dir" \
    --cleanup.remove-egs=$remove_egs \
    --use-gpu=true \
    --feat-dir=$train_data_dir \
    --ali-dir=$ali_dir \
    --lang=$lang \
    --reporting.email="$reporting_email" \
    --dir=$dir  || exit 1;
fi

if [ $stage -le 14 ]; then
  frames_per_chunk=$(echo $chunk_width | cut -d, -f1)
  rm $dir/.error 2>/dev/null || true

  for data in $test_sets; do
    (
      frames_per_chunk=$(echo $chunk_width | cut -d, -f1)
      nj=$(wc -l <data/${data}_hires/spk2utt)
      graph_dir=$gmm_dir/graph_tgsmall
      steps/nnet3/decode.sh \
        --extra-left-context $chunk_left_context \
        --extra-right-context $chunk_right_context \
        --extra-left-context-initial 0 \
        --extra-right-context-final 0 \
        --frames-per-chunk $frames_per_chunk \
        --nj $nj --cmd "$decode_cmd"  --num-threads 4 \
        --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${data}_hires \
        $graph_dir data/${data}_hires ${dir}/decode_tgsmall || exit 1
    ) || touch $dir/.error &
  done
  wait
  [ -f $dir/.error ] && echo "$0: there was a problem while decoding" && exit 1
fi

if [ $stage -le 15 ]; then
  # 'looped' decoding.
  # note: you should NOT do this decoding step for setups that have bidirectional
  # recurrence, like BLSTMs-- it doesn't make sense and will give bad results.
  # we didn't write a -parallel version of this program yet,
  # so it will take a bit longer as the --num-threads option is not supported.
  # we just hardcode the --frames-per-chunk option as it doesn't have to
  # match any value used in training, and it won't affect the results (unlike
  # regular decoding).
  rm $dir/.error 2>/dev/null || true

  for data in $test_sets; do
    (
      nj=$(wc -l <data/${data}_hires/spk2utt)
      graph_dir=$gmm_dir/graph_tgsmall
      steps/nnet3/decode_looped.sh \
        --frames-per-chunk 30 \
        --nj $nj --cmd "$decode_cmd" \
        --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${data}_hires \
        $graph_dir data/${data}_hires ${dir}/decode_looped || exit 1
    ) || touch $dir/.error &
  done
  wait
  [ -f $dir/.error ] && echo "$0: there was a problem while decoding" && exit 1
fi
