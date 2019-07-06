#!/bin/bash

# Copyright 2016 Pascal Tuan
# Apache 2.0
# Revised from Librispeech

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 [option] <src-dir> <dst-dir>"
  echo "e.g.: $0 /home/passwd12345/Desktop/vocalData/all data/vocalData-all"
  exit 1
fi

src=$1
dst=$2

# all utterances are FLAC compressed
if ! which flac >&/dev/null; then
  echo "Please install 'flac' on ALL worker nodes!"
  exit 1
fi

#TODO
spk_file=$src/../SINGERS.TXT

mkdir -p $dst || exit 1;

[ ! -d $src ] && echo "$0: no such directory $src" && exit 1;
[ ! -f $spk_file ] && echo "$0: expected file $spk_file to exist" && exit 1;

wav_scp=$dst/wav.scp; [[ -f "$wav_scp" ]] && rm $wav_scp
trans=$dst/text; [[ -f "$trans" ]] && rm $trans
utt2spk=$dst/utt2spk; [[ -f "$utt2spk" ]] && rm $utt2spk
spk2gender=$dst/spk2gender; [[ -f $spk2gender ]] && rm $spk2gender
utt2dur=$dst/utt2dur; [[ -f "$utt2dur" ]] && rm $utt2dur

for spk_dir in $(find $src -mindepth 1 -maxdepth 1 -type d | sort); do
  speaker=$(basename $spk_dir)
  if ! [ $speaker -eq $speaker ]; then
    echo "$0: unexpected subdirectory name $speaker"
    exit 1;
  fi
  #TODO

  for song_dir in $(find -L $spk_dir/ -mindepth 1 -maxdepth 1 -type d | sort); do
    song=$(basename $song_dir)
    if ! [ "$song" -eq "$song" ]; then
      echo "$0: unexpected song-subdirectory name $song"
      exit 1;
    fi

    find $song_dir/ -iname "*.flac" | sort | xargs -I% basename % .flac |\
      awk -v "dir=$song_dir" '{printf "%s flac -c -d -s %s/%s.flac |\n", $0, dir, $0}'>>$wav_scp || exit 1

    song_trans=$song_dir/${speaker}-${song}.trans.txt
    [ ! -f $song_trans ] && echo "$0: expected file $song_trans to exist" && exit 1
    cat $song_trans >> $trans

    awk -v "speaker=$speaker" '{printf "%s %s\n", $1, speaker}' \
      <$song_trans >>$utt2spk || exit 1
  done
done

spk2utt=$dst/spk2utt
old_steps_and_utils/utils/utt2spk_to_spk2utt.pl <$utt2spk >$spk2utt || exit 1

ntrans=$(wc -l <$trans)
nutt2spk=$(wc -l <$utt2spk)
! [ "$ntrans" -eq "$nutt2spk" ] && \
  echo "Inconsistent #transcripts($ntrans) and #utt2spk($nutt2spk)" && exit 1;

old_steps_and_utils/utils/data/get_utt2dur.sh $dst 1>&2 || exit 1

old_steps_and_utils/utils/validate_data_dir.sh --no-feats $dst || exit 1;

echo "$0: successfully prepared data in $dst"

exit 0
