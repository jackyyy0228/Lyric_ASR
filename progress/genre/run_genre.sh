#!/bin/bash
'''
for genre in hiphop; do
  echo "preparing $genre data"
  bash progress/train_genre.sh 1 $genre > genre_exp/train/$genre.log 
done
'''
result=./result_genre

for model_genre in rnb_soul; do
  for decode_genre in  rnb_soul; do
    echo "$model_genre model decodes $decode_genre" 
    bash progress/decode_genre.sh $model_genre $decode_genre $result # >> genre_exp/decode/$model_genre\_$decode_genre.log
  done
done
