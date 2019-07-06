#!/bin/bash
for level in singer genre ; 
do
  bash progress/genre/fmllr_exp.sh -10 $level
done
