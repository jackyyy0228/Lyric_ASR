import operator
import os,sys
import numpy
from song import *
from shutil import copyfile

genreAnalyze = ['POP','ELECTRONIC','HIPHOP','ROCK','RNB_SOUL']
genreDict = {'POP' : 1,'ELECTRONIC' : 2,'HIPHOP':3 ,'ROCK' : 4,'RNB_SOUL' :5 }
class classifier():
    def __init__(self,srcDir,dstDir): #srcDir = 'train_clean' or 'test_clean'
        dataPath = '/data/groups/hao246/vocal_data'
        self.dataPath = dataPath
        self.dstDir = dstDir
        self.srcDir = srcDir
        self.dstPath = dataPath + '/' + dstDir
        self.srcPath = dataPath + '/' + srcDir
        self.songInfo = songInfor()
    def classify(self):
        for key in self.songInfo.getClipList():
            (a,b,c) = key
            clip = self.songInfo.get(a,b,c)
            if clip.singerSet != self.srcDir:
                continue
            for genre in clip.songGenre:
                if genre in genreAnalyze:
                    genre = genreDict[genre]
                    self.copy(clip,str(genre))
        for dirPath, dirNames, fileNames in os.walk(self.dstPath):
            for f in fileNames:
                txt =  os.path.join(dirPath, f)
                if f.endswith('.txt'):
                    self.sortTxt(txt)

    def copy(self,song,genre):
        fileName = song.singerID + '-' + song.songID + '-' + song.clipID + '.flac'
        txtFileName = song.singerID + '-' + song.songID + '.trans.txt'
        filePath = os.path.join(self.dataPath,self.srcDir,song.singerID
                                ,song.songID,fileName)
        txtFilePath = os.path.join(self.dataPath,self.srcDir,song.singerID
                                   ,song.songID,txtFileName)
        
        songName2 = str(song.singerID) + str(song.songID)
        fileName2 = genre + '-' + songName2 + '-' + song.clipID + '.flac'
        txtFileName2 = genre + '-' + songName2 + '.trans.txt'
        dstFileDir = os.path.join(self.dstPath,genre,songName2)
        dstFilePath = os.path.join(dstFileDir,fileName2)
        dstTxtPath = os.path.join(dstFileDir,txtFileName2)
        self.check_and_mkdir(dstFileDir)
        copyfile(filePath,dstFilePath)
        with open(dstTxtPath,'a') as fp:
            lyric = self.songInfo.get_lyric(song.singerID,song.songID,song.clipID)
            lyric = lyric[10:]
            lyric = genre + '-' + songName2 + '-' + song.clipID + lyric
            fp.write(lyric)
    def check_and_mkdir(self,path):
        tmp = '/'
        for subdir in path.split('/'):
            tmp = os.path.join(tmp,subdir)
            if os.path.isdir(tmp) is False:
               os.mkdir(tmp)
    def sortTxt(self,txt):
        T = []
        with open(txt,'r') as fp:
            for line in fp:
                key = line.split()[0]
                T.append((key,line))
        T = sorted(T, key = lambda x :x[0])
        with open(txt,'w') as fp:
            for key,line in T:
                fp.write(line)
            


if __name__ == '__main__':
    clf = classifier(sys.argv[1], sys.argv[2])
    clf.classify()
     
