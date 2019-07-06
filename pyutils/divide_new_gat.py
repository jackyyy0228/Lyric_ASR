import operator
import os,sys
import numpy
from song import *
from shutil import copyfile

class classifier():
    def __init__(self,srcDir,dstDir,genreFile): #srcDir = 'train_clean' or 'test_clean'
        dataPath = '/data/groups/hao246/vocal_data'
        self.dataPath = dataPath
        self.dstDir = dstDir
        self.srcDir = srcDir
        self.dstPath = dataPath + '/' + dstDir
        self.srcPath = dataPath + '/' + srcDir
        self.songInfo = songInfor()
        self.genreDict = {}
        with open('utt2genre_test','r') as fp:
            for line in fp:
                x,y,genre=line.rstrip().split()
                self.genreDict[(x,y)] = genre
    def classify(self):
        for key in self.songInfo.getClipList():
            (a,b,c) = key
            clip = self.songInfo.get(a,b,c)
            if clip.singerSet != self.srcDir:
                continue
            self.copy(clip,self.genreDict[(a,b)])
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

if __name__ == '__main__':
    dataSet = sys.argv[1]
    genreFile = sys.argv[2]
    clf = classifier(dataSet, 'new_genre_'+dataSet)
    clf.classify()
     
