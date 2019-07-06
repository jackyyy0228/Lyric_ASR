#!/bin/bash
genre=all
result=./result_all
for model_genre in all; do
  for decode_genre in nonpop nonelectronic nonrock nonhiphop nonrnb_soul; do
    echo "$model_genre model decodes $decode_genre" 
    bash progress/decode_genre.sh $model_genre $decode_genre $result
  done
done
