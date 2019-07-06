#!bin/bash

. ./cmd.sh

#steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
#  data/train_si284 data/lang exp/tri4b exp/tri4b_ali_si284 || exit 1;
# Train and test MMI, and boosted MMI, on tri4b (LDA+MLLT+SAT on
# all the data).  Use 30 jobs.
local/run_mmi_tri4b.sh

# These demonstrate how to build a sytem usable for online-decoding with the nnet2 setup.
# (see local/run_nnet2.sh for other, non-online nnet2 setups).
local/online/run_nnet2.sh
local/online/run_nnet2_baseline.sh
local/online/run_nnet2_discriminative.sh

# Demonstration of RNNLM rescoring on TDNN models. We comment this out by
# default.
# local/run_rnnlms.sh


#local/run_nnet2.sh

# You probably want to run the sgmm2 recipe as it's generally a bit better:
local/run_sgmm2.sh

# We demonstrate MAP adaptation of GMMs to gender-dependent systems here.  This also serves
# as a generic way to demonstrate MAP adaptation to different domains.
# local/run_gender_dep.sh

# You probably want to run the hybrid recipe as it is complementary:
local/nnet/run_dnn.sh

# The following demonstrate how to re-segment long audios.
# local/run_segmentation.sh

# The next two commands show how to train a bottleneck network based on the nnet2 setup,
# and build an SGMM system on top of it.
#local/run_bnf.sh
#local/run_bnf_sgmm.sh


# You probably want to try KL-HMM
#local/run_kl_hmm.sh

# Getting results [see RESULTS file]
# for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done


# KWS setup. We leave it commented out by default

# $duration is the length of the search collection, in seconds
#duration=`feat-to-len scp:data/test_eval92/feats.scp  ark,t:- | awk '{x+=$2} END{print x/100;}'`
#local/generate_example_kws.sh data/test_eval92/ data/kws/
#local/kws_data_prep.sh data/lang_test_bd_tgpr/ data/test_eval92/ data/kws/
#
#steps/make_index.sh --cmd "$decode_cmd" --acwt 0.1 \
#  data/kws/ data/lang_test_bd_tgpr/ \
#  exp/tri4b/decode_bd_tgpr_eval92/ \
#  exp/tri4b/decode_bd_tgpr_eval92/kws
#
#steps/search_index.sh --cmd "$decode_cmd" \
#  data/kws \
#  exp/tri4b/decode_bd_tgpr_eval92/kws
#
# If you want to provide the start time for each utterance, you can use the --segments
# option. In WSJ each file is an utterance, so we don't have to set the start time.
#cat exp/tri4b/decode_bd_tgpr_eval92/kws/result.* | \
#  utils/write_kwslist.pl --flen=0.01 --duration=$duration \
#  --normalize=true --map-utter=data/kws/utter_map \
#  - exp/tri4b/decode_bd_tgpr_eval92/kws/kwslist.xml

# # A couple of nnet3 recipes:
# local/nnet3/run_tdnn_baseline.sh  # designed for exact comparison with nnet2 recipe
# local/nnet3/run_tdnn.sh  # better absolute results
# local/nnet3/run_lstm.sh  # lstm recipe
# bidirectional lstm recipe
# local/nnet3/run_lstm.sh --affix bidirectional \
#	                  --lstm-delay " [-1,1] [-2,2] [-3,3] " \
#                         --label-delay 0 \
#                         --cell-dim 640 \
#                         --recurrent-projection-dim 128 \
#                         --non-recurrent-projection-dim 128 \
#                         --chunk-left-context 40 \
#                         --chunk-right-context 40
