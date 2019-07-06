#Usage:
#divide genre:
#python divide_genre.py 1 POP
#divide nongenre:
#python divide_genre.py 0 POP
#Classifier = classifier()
#Classifier.classify(songList)
#songList = [(singerID,songID,clipID)]
import operator
import os,sys
import numpy
from song import *
from shutil import copyfile
class classifier():
    def __init__(self,dstDir):
        dataPath = '/data/groups/hao246/vocal_data'
        self.dataPath = dataPath
        self.dstDir = dstDir
        self.dstPath = dataPath + '/' + dstDir
    def classify(self,songList):
        songClass = songInfor()
        sec = 0
        for song in songList:
            clip = songClass.get(song[0],song[1],song[2])
            sec += clip.clipSec
            self.copy(clip)
        print('{:10s} : {:.2f} (s)'.format(self.dstDir, sec))
    def copy(self,song):
        fileName = song.singerID + '-' + song.songID + '-' + song.clipID + '.flac'
        txtFileName = song.singerID + '-' + song.songID + '.trans.txt'
        filePath = os.path.join(self.dataPath,'all',song.singerID,song.songID,fileName)
        txtFilePath = os.path.join(self.dataPath,'all',song.singerID,song.songID,txtFileName)
        dstFileDir = os.path.join(self.dstPath,song.singerID,song.songID)
        dstFilePath = os.path.join(dstFileDir,fileName)
        dstTxtPath = os.path.join(dstFileDir,txtFileName)
        self.check_and_mkdir(dstFileDir)
        copyfile(filePath,dstFilePath)
        if os.path.isfile(dstTxtPath) is False:
            copyfile(txtFilePath,dstTxtPath)
    def check_and_mkdir(self,path):
        tmp = '/'
        for subdir in path.split('/'):
            tmp = os.path.join(tmp,subdir)
            if os.path.isdir(tmp) is False:
               os.mkdir(tmp)
def divide_genre(genre):
    #Usage : divide_genre('POP')
    genre = genre.upper()
    songInfo = songInfor()
    dicts = {}
    sec = {}
    for key in songInfo.getClipList():
        (a,b,c) = key
        clip = songInfo.get(a,b,c)
        if genre in clip.songGenre:
            if clip.singerSet in dicts:
                dicts[clip.singerSet].append((clip.singerID,clip.songID,clip.clipID))
                sec[clip.singerSet] += clip.clipSec
            else :
                dicts[clip.singerSet] = [(clip.singerID,clip.songID,clip.clipID)]
                sec[clip.singerSet] = clip.clipSec
    for key,clipList in dicts.items():
        if key == 'train_clean' or key == 'test_clean':
            clf = classifier('genre/'+ genre.lower() +  '_' + key)
            clf.classify(clipList)
def divide_nongenre(genre):
    #Usage : divide_genre('POP')
    songInfo = songInfor()
    dicts = {}
    sec = {}
    for key in songInfo.getClipList():
        (a,b,c) = key
        clip = songInfo.get(a,b,c)
        if genre not in clip.songGenre:
            if clip.singerSet in dicts:
                dicts[clip.singerSet].append((clip.singerID,clip.songID,clip.clipID))
                sec[clip.singerSet] += clip.clipSec
            else :
                dicts[clip.singerSet] = [(clip.singerID,clip.songID,clip.clipID)]
                sec[clip.singerSet] = clip.clipSec
    for key,clipList in dicts.items():
        if key == 'train_clean' or key == 'test_clean':
            #print(key)
            #for clip in clipList:
            #    clip = songInfo.get(clip[0],clip[1],clip[2])
            #    print(clip.songGenre)
            clf = classifier('genre/non'+ genre.lower() +  '_' + key)
            clf.classify(clipList)
if __name__ == '__main__':
    if sys.argv[1] == '1':
        divide_genre(sys.argv[2])
    else:
        divide_nongenre(sys.argv[2])
        
