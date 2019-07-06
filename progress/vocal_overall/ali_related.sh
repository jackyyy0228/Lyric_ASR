. cmd.sh
. path.sh

#lm=data/lang_lyric
#ali=exp/vocal/svtri3b_svtri1_1k_5k_all_clean_ali_exp3
#mdl=exp/vocal/svtri3b_svtri1_1k_5k_exp3
#name=svtri3b_svtri1_1k_5k_exp3
ali=$1
name=$2

: '
# show alignment
for i in $ali/ali.*.gz; do
  show-alignments $lm/phones.txt $mdl/final.mdl "ark:gunzip -c $i |" > ${i%.gz}.show;
done

# phone-level
for i in $ali/ali.*.gz; do
  ali-to-phones --ctm-output $ali/final.mdl "ark:gunzip -c $i |" -> ${i%.gz}.ctm;
done

# word-level
steps/get_train_ctm.sh --cmd "$train_cmd" data/vocal/ori_train_clean data/lang_lyric $ali
cp $ali/ctm vocal_ali/ctm_gmm/ctm-$name

# evaluate
python vocal_ali/WCAA.py --data-dir=vocal_ali/labeledData --model-dir=vocal_ali/ctm_gmm --output-dir=vocal_ali/result_gmm
cat $ali/ali.*.ctm > $ali/all_phone_ali.ctm

# praat
for part in 004-1-0003 009-4-0001 025-1-0001 \
  027-1-0003 047-3-0007 049-1-0002 \
  061-2-0004 069-1-0008 077-1-0012 \
  081-1-0001 084-1-0002 085-1-0002 087-1-0004; do
  python vocal_ali/createTextgrid.py $ali/ctm $name $part
done
for part in 028-3-0001 029-1-0001 \
  028-3-0004 029-1-0004 ; do
  python vocal_ali/createTextgrid.py $ali/ctm $name $part
done
'

: '
steps/get_train_ctm.sh --cmd "$train_cmd" data/vocal/all_clean data/lang_lyric $ali
for part in 002-1-0001 007-1-0002 022-1-0007 \
  031-3-0003 036-1-0003 062-1-0005 \
  067-1-0002 089-1-0006; do
  python vocal_ali/createTextgrid.py $ali/ctm $name $part
done
'
steps/get_train_ctm.sh --cmd "$train_cmd" data/paper/train_clean_utt data/lang_lyric $ali
for part in 004-1-0003 009-4-0001 025-1-0001 \
  027-1-0003 047-3-0007 049-1-0002 \
  061-2-0004 069-1-0008 077-1-0012 \
  081-1-0001 084-1-0002 085-1-0002 087-1-0004; do
  python vocal_ali/createTextgrid.py $ali/ctm $name $part
done
