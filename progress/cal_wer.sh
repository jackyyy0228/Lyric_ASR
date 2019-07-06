#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <decode-folder>"
  echo "e.g.: $0 /data/datasets/hao246/singing-voice-recog/exp/speech/tri4b/decode_nosp_tgmed_vocal_test_clean"
  echo "The result file is decodePath/utt_wer"
  exit 1
fi


. path.sh
decodePath=$1
#get best WER in exp/decode folder
grep WER $decodePath/wer* > $decodePath/WER
wer=`python pyutils/show_wer.py $decodePath/WER`
echo $decodePath $wer
bestPathFile=$decodePath/scoring/log/best_path.`python pyutils/get_best_wer.py $decodePath/WER`.log
#echo $bestPathFile
#compare ref.txt(correct lyric) with hyp.txt(exp result)
python pyutils/extract_utt.py $bestPathFile $decodePath
compute-wer2 ark,t:$decodePath/ref.txt ark,t:$decodePath/hyp.txt > $decodePath/utt_wer
