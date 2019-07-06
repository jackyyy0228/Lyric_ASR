#Usage:
#searchEngine = songInfor()
#clipInfor = searchEngine.get(singerID,songID,clipID)
#All ID is integer
import sys 
import numpy as np
class songInfor():
    def __init__(self):
        import os 
        self.dataDir = '/data/groups/hao246/vocal_data'
        werPath = '/data/groups/hao246/singing-voice-recog/exp/speech/tri4b/decode_tglarge_vocal_all/utt_wer'
        dataDir = self.dataDir
        self.singers = {}
        with open(os.path.join(dataDir,'SINGERS.TXT'),'r') as srtxt:
            for line in srtxt:
                if line.startswith(('#',';')):
                    continue
                token = self.splitTxt(line)
                self.singers[token[0]] = (token[1],token[2])
        self.sets = {}
        with open(os.path.join(dataDir,'SETS.TXT'),'r') as sttxt:
            for line in sttxt:
                if line.startswith('t'):
                    line.rstrip()
                    now = line.split()[0]
                else:
                    token = line.split()
                    for i in range(len(token)):
                        self.sets[token[i]] = now
        self.songs = {}
        with open(os.path.join(dataDir,'SONGS.TXT'),'r') as sgtxt:
            for line in sgtxt:
                if line.startswith(('#',';')):
                    continue
                token = self.splitTxt(line)
                a,b = token[0].split('-')
                songGenre = []
                for word in token[1].split():
                    songGenre.append(word)
                songName  = token[2]
                self.songs[(a,b)] = (songGenre,songName)
        self.clips = {}
        with open(os.path.join(dataDir,'CLIPS.TXT')) as cltxt:
            for line in cltxt:
                if line.startswith(('#',';')):
                    continue
                token = line.split()
                a,b,c = token[0].split('-')
                self.clips[(a,b,c)] = (float(token[2]),token[4],token[6])
        self.wers = {}
        with open(werPath,'r') as wertxt:
            for line in wertxt:
                if line.startswith('0'):
                    key,wer=line.split()[0],line.split()[2]
                    singerID,songID,clipID = key.split('-')
                    self.wers[(singerID,songID,clipID)] = float(wer)
        
    def get(self,singerID,songID,clipID):
        if type(singerID) is int:
            singerID = self.intToTxt(singerID,3)
        if type(songID) is int:
            songID = self.intToTxt(songID,1)
        if type(clipID) is int:
            clipID = self.intToTxt(clipID,4)
        if (singerID,songID,clipID) not in self.clips:
            print('there is no %s-%s-%s' % (singerID,songID,clipID))
            return
        singerName = self.singers[singerID][0]
        singerSex = self.singers[singerID][1]
        singerSet = self.sets[singerID]
        songGenre = self.songs[(singerID,songID)][0]
        songName = self.songs[(singerID,songID)][1]
        clipSec = self.clips[(singerID,songID,clipID)][0]
        clipSpeed = self.clips[(singerID,songID,clipID)][1]
        clipHarmony = self.clips[(singerID,songID,clipID)][2]
        clipWER = self.wers[(singerID,songID,clipID)]
        return song(singerID,songID,clipID,
                    singerName,singerSex,singerSet,songGenre,songName,
                    clipSec,clipSpeed,clipHarmony,clipWER)
    def get_singer(self,singerID):
        if type(singerID) is int:
            singerID = self.intToTxt(singerID,3)
        singerName = self.singers[singerID][0]
        singerSex = self.singers[singerID][1]
        singerSet = self.sets[singerID]
        wer = []
        sec = []
        for clip in self.getClipList():
            a,b,c = clip
            if a == singerID:
                wer.append(self.wers[(a,b,c)])
                sec.append(self.clips[(a,b,c)][0])
        mean_wer = np.mean(wer)
        sum_sec = np.sum(sec)
        return song(singerID,0,0,singerName,singerSex,singerSet,0,0,sum_sec,0,0,mean_wer)
    def get_song(self,singerID,songID):
        if type(singerID) is int:
            singerID = self.intToTxt(singerID,3)
        if type(songID) is int:
            songID = self.intToTxt(songID,1)
        singerName = self.singers[singerID][0]
        singerSex = self.singers[singerID][1]
        singerSet = self.sets[singerID]
        songGenre = self.songs[(singerID,songID)][0]
        songName = self.songs[(singerID,songID)][1]
        wer = []
        sec = []
        for clip in self.getClipList():
            a,b,c = clip
            if a == singerID and b == songID:
                wer.append(self.wers[(a,b,c)])
                sec.append(self.clips[(a,b,c)][0])
        mean_wer = np.mean(wer)
        sum_sec = np.sum(sec)
        return song(singerID,songID,0,singerName,singerSex,singerSet,songGenre,songName,sum_sec,0,0,mean_wer)
    def intToTxt(self,x,digit):
        temp = str(x)
        for idx in range(digit - len(temp)):
            temp = '0' + temp
        return temp
    def getClipList(self):
        return list(self.clips.keys())
    def getSongList(self):
        return list(self.songs.keys())
    def getSingerList(self):
        return list(self.singers.keys())
    def splitTxt(self,line):
        tokens = line.split()
        nowid = 0
        now = ''
        result = []
        for token in  tokens:
            if token == '|':
                nowid += 1
                if len(now) > 0:
                    result.append(now)
                now = ''
            else:
                if now == '':
                    now = token 
                else:
                    now = now + ' ' + token
        result.append(now)
        return result
    def get_lyric(self,singerID,songID,clipID):
        import os,sys
        fileName = singerID + '-' + songID + '.trans.txt'
        dstPath = os.path.join(self.dataDir,'all',singerID,songID,fileName)
        if(singerID,songID,clipID) == ('086','1','0001'):
            return "IF THERE'S A QUESTION OF MY HEART YOU'VE GOT IT IT DON'T BELONG TO ANYONE BUT YOU IF THERE'S A QUESTION OF MY LOVE YOU'VE GOT IT BABY DON'T WORRY I'VE GOT PLANS FOR YOU YEAH BABY I'VE BEEN MAKING PLANS OF LOVE BABY I'VE BEEN MAKING PLANS FOR YOU YEAH BABY I'VE BEEN MAKING PLANS BABY I'VE BEEN MAKING PLANS FOR YOU\n"
        with open(dstPath,'r') as fp:
            for line in fp:
                if line.startswith(singerID + '-' + songID + '-' + clipID):
                    return line
        print('No such file :',dstPath)
class song():
    def __init__(self,singerID,songID,clipID,
                    singerName,singerSex,singerSet,songGenre,songName,
                    clipSec,clipSpeed,clipHarmony,clipWER):
        self.singerID = singerID
        self.singerName = singerName
        self.singerSex = singerSex
        self.singerSet = singerSet
        self.songID = songID
        self.songGenre = songGenre
        self.songName = songName
        self.clipID = clipID
        self.clipSec = clipSec
        self.clipSpeed = clipSpeed
        self.clipHarmony = clipHarmony
        self.clipWER = clipWER
if __name__ == '__main__':
    clf = songInfor()
    trc = 0
    tro = 0
    tc = 0
    to = 0
    d = {}
    for x in clf.getSingerList():
        song2 = clf.get_singer(x)
        d[x] = song2.clipWER
    import operator
    for x,value in sorted(d.items(),key=operator.itemgetter(1)):
        print(x,value)
        
