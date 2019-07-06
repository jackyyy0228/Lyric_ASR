import sys

if __name__ == '__main__':
    ori='/data/groups/hao246/singing-voice-recog/data/vocal/genre_test_clean/utt2spk'
    if sys.argv[1] == 'spk':
        datadir = '/data/groups/hao246/singing-voice-recog/data/vocal/genre_test_clean_spk'
        dic = {}
        with open(ori,'r') as fpr:
            for line in fpr:
                key = line.split()[0]
                spk = key[2:5]
                dic[key] = spk
        with open(datadir+'/utt2spk','w') as fpw:
            for (key,spk) in sorted(dic.iteritems(), key=lambda(k,v): (v,k)):
                fpw.write("%s %s\n" % (key, spk))

    elif sys.argv[1] == 'song':
        datadir = '/data/groups/hao246/singing-voice-recog/data/vocal/genre_test_clean_song' 
        dic = {}
        with open(ori,'r') as fpr:
            for line in fpr:
                key = line.split()[0]
                spk = key[2:6]
                dic[key] = spk
        with open(datadir+'/utt2spk','w') as fpw:
            for (key,spk) in sorted(dic.iteritems(), key=lambda(k,v): (v,k)):
                fpw.write("%s %s\n" % (key, spk))
