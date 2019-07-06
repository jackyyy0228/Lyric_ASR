. cmd.sh
. path.sh

lm=data/lang_lyric
ali=exp/vocal/svtri3b_svtri1_1k_5k_ali_exp3
mdl=exp/vocal/svtri3b_svtri1_1k_5k_exp3
name=svtri3b_svtri1_1k_5k_exp3
# phone-level
for i in $ali/ali.*.gz; do
  ali-to-phones --ctm-output $ali/final.mdl "ark:gunzip -c $i |" ${i%.gz}.ctm;
done
cat $ali/*.ctm > all_phone_ali.ctm
