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
    def copy(self,song,genre):
        fileName = song.singerID + '-' + song.songID + '-' + song.clipID + '.flac'
        txtFileName = song.singerID + '-' + song.songID + '.trans.txt'
        filePath = os.path.join(self.dataPath,self.srcDir,song.singerID
                                ,song.songID,fileName)
        txtFilePath = os.path.join(self.dataPath,self.srcDir,song.singerID
                                   ,song.songID,txtFileName)
        
        fileName2 = song.singerID + '-' + genre + song.songID + '-' + song.clipID + '.flac'
        txtFileName2 = song.singerID + '-' + genre + song.songID + '.trans.txt'
        dstFileDir = os.path.join(self.dstPath,song.singerID,genre + song.songID)
        dstFilePath = os.path.join(dstFileDir,fileName2)
        dstTxtPath = os.path.join(dstFileDir,txtFileName2)
        self.check_and_mkdir(dstFileDir)
        copyfile(filePath,dstFilePath)
        with open(dstTxtPath,'a') as fp:
            lyric = self.songInfo.get_lyric(song.singerID,song.songID,song.clipID)
            lyric = lyric[10:]
            lyric = song.singerID + '-' + genre + song.songID + '-' + song.clipID + lyric
            fp.write(lyric)
    def check_and_mkdir(self,path):
        tmp = '/'
        for subdir in path.split('/'):
            tmp = os.path.join(tmp,subdir)
            if os.path.isdir(tmp) is False:
               os.mkdir(tmp)

if __name__ == '__main__':
    clf = classifier('test_clean', 'genre_test_clean_spk')
    clf.classify()
     
