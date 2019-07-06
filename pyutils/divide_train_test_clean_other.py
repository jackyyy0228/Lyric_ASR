import operator
import os,sys
from song import *
from shutil import copyfile
from divide_genre import *
def cal_singer(werList):
    D = {}
    S = {}
    Du = {}
    searchEngine = songInfor()
    for si,so,cl,wer in werList:
        songIn = searchEngine.get(si,so,cl)
        if si in D:
            D[si] += wer
            S[si] += 1
            Du[si]+= songIn.clipSec
        else:
            D[si] = wer
            S[si] = 1
            Du[si] = songIn.clipSec
    result = {}
    for key in D:
        result[key] = (D[key] / S[key] , Du[key] )
    return result
def classify_by_singer():#old version
    dataPath = '/data1/hao246/vocal_data'
    decodePath = '/data/datasets/hao246/singing-voice-recog/exp/speech/tri4b/decode_tglarge_vocal_all'
    dataPath = '/data1/groups/vocal_data'
    decodePath = '/data/groups/hao246/singing-voice-recog/exp/speech/tri4b/decode_tglarge_vocal_all'
    werPath = decodePath + '/' + 'utt_wer'
    werList = read_wer(werPath)
    searchEngine = songInfor()
    singerWER = cal_singer(werList)
    trainClean = []#12629sec
    trainOther = ['056','017','038','068','083','088','073']#2343sec
    testClean = []#6219sec
    testOther = ['039','071','016','044']#1221sec
    i,summ = 0,0
#    print  '{:>5}  {:>10}  {:>35} {:>10} {:>10} {:>10} {:>10}'.format('idx','singerID','singerName','singerSex','length','cumulation','%WER')
    for key,(value,length) in sorted(singerWER.items(), key=operator.itemgetter(1)):
        song = searchEngine.get_singer(key)
        value = "%.2f" % value
        print(value)
        continue
        length = "%.2f" % length
        summ += float(length)
        if summ < 15000 and song.singerID not in trainOther:
            trainClean.append(song.singerID)
        if summ >= 15000 and song.singerID not in testOther:
            testClean.append(song.singerID)
#       print  '{:>5}  {:>10}  {:>35} {:>10} {:>10} {:>10} {:>10}'.format(i,song.singerID,song.singerName,song.singerSex,length,summ,value)
        #i+= 1
        dataDir = '/data/groups/hao246/vocal_data'
        with open(os.path.join(dataDir,'SETS.TXT'),'w') as fp:
            for target,Name in zip([trainClean,trainOther,testClean,testOther],['train_clean','train_other','test_clean','test_other']):
                fp.write(Name + '\n')
                for si in target:
                    fp.write(si + ' ')
                fp.write('\n')
        '''
    for target,Name in zip([trainClean,trainOther,testClean,testOther],['train_clean','train_other','test_clean','test_other']):
        classifier1 = classifier(Name)
        songList = []
        for si,so,cl,wer in werList:
            if si in target:
                songList.append((si,so,cl))
        classifier1.classify(songList)
        '''
classify_by_singer()
