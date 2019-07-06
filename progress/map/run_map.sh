#!bin/bash
for genre in pop electronic hiphop rnb_soul rock ;
do
  bash progress/genre/run_map.sh -10 $genre
done
