
# train a monophone system
# with few data, in this case, 5 min words ( 11 clips )
# speech counterpart is 2k
# called mono
# ...
# train a first delta + delta-delta triphone system
# on a subset of few utterance, maybe 30 clip
# speech counterpart is 5k
# called tri1
# ...
# train an LDA+MLLT system
# on a subset of more utterance, maybe 100 clip
# speech counterpart is 10k
# called tri2b
# ...
# train LDA+MLLT+SAT
# on the same utterances, the 100 clips used in tri2b
# speech counterpart is 10k
# called tri3b
# ...
# train LDA+MLLT+SAT
# on the whole utterances
# called tri4b
# ...
# run_5a_clean_100.sh
