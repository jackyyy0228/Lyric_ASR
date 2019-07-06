import sys
from song import *
if len(sys.argv) != 2:
    print('Usage : {:s} decodePath/utt_wer'.format(sys.argv[0]))
    sys.exit(1)

uwPath = sys.argv[1]
genreList = ['POP','ELECTRONIC','ROCK','RNB_SOUL','HIPHOP']
class clipWER():
    def __init__(self):
        self.genreWER=[]
        for i in range(5):
            self.genreWER.append((0,0))
        self.sI=songInfor()
        self.wrong=0.0
        self.total=0.0
    def add(self,key,wrong,total):
        song = self.sI.get(key[0],key[1],key[2])
        self.wrong+=wrong
        self.total+=total
        for idx,genre in enumerate(genreList):
            if genre in song.songGenre:
                x,y = self.genreWER[idx]
                x += wrong
                y += total
                self.genreWER[idx] = (x,y)
    def get_wer(self):
        print(sys.argv[1])
        print('Total : {:.4f}'.format(self.wrong/self.total))
        for idx,genre in enumerate(genreList):
            x,y = self.genreWER[idx]
            wer= float(x) / y
            print('{:15s} : {:.4f}'.format(genreList[idx],wer))

clipwer=clipWER()
with open(uwPath,'r') as uf:
    for line in uf:
        if line.startswith('%') or line.startswith('S'):
            continue
        token = line.split()
        key,wrong,total = token[0],int(token[4]),token[6]
        total = int(total[:-1])
        singerID,songID,clipID = key.split('-')
        keyDict = (singerID,songID,clipID)
        clipwer.add(keyDict,wrong,total)
    clipwer.get_wer() 

