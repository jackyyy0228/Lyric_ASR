#!/bin/bash
for x in $1/*/decode* ;
do
  grep WER $x/wer* | utils/best_wer.sh;
done
