#!/bin/bash
. path.sh
. cmd.sh
audio_dir=vocal_data

numjob=4
for level in utt ; do
  for part in train_clean test_clean ; do
    local/vocaldata_prep_$level.sh $audio_dir/$part data/paper/$part\_$level || exit 1;
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
      data/paper/$part\_$level exp/make_mfcc/paper/$part\_$level mfcc/paper/$part\_$level || exit 1;
    steps/compute_cmvn_stats.sh \
      data/paper/$part\_$level exp/make_mfcc/paper/$part\_$level mfcc/paper/$part\_$level || exit 1;
  done
done

if  false ; then 
  for level in genre ; do
    for part in train_clean test_clean ; do
      if [ ! -d $audio_dir/genre_$part ]; then
        echo "divide $audio_dir/genre_$part"
        python pyutils/divide_genre_set.py $part genre_$part
      fi
      local/vocaldata_prep_singer.sh $audio_dir/genre_$part data/paper/$part\_$level || exit 1;
      steps/make_mfcc.sh --cmd "$train_cmd" --nj $numjob \
        data/paper/$part\_$level exp/make_mfcc/paper/$part\_$level mfcc/paper/$part\_$level || exit 1;
      steps/compute_cmvn_stats.sh \
        data/paper/$part\_$level exp/make_mfcc/paper/$part\_$level mfcc/paper/$part\_$level || exit 1;
    done
  done
fi
