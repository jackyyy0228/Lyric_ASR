import os,sys
import matplotlib.pyplot as plt
from song import *
from shutil import copyfile

def read_cmt(cmtFile):
    d = {}
    with open(sys.argv[1],'r') as fp:
        for line in fp:
            line.rstrip()
            key = line.split()[0]
            dur = float(line.split()[3])
            x,y,z = key.split('-')
            if (x,y,z) in d:
                d[(x,y,z)].append(dur)
            else:
                d[(x,y,z)] = [dur]
    return d
def classify_speed(d,thd = 0.2):
    train_fast = []
    train_slow = []
    test_fast = []
    test_slow = []
    clf = songInfor()
    for key,dur in d.items():
        x,y,z = key
        s = clf.get(x,y,z)
        leng = s.clipSec
        n_phoneme = len(dur)
        time = leng / n_phoneme
        #print('{:s}-{:s}-{:s} {:f}'.format(x,y,z,leng / n_phoneme) )
        if time < thd:
            if s.singerSet == 'train_clean':
                train_fast.append((x,y,z))
            elif s.singerSet == 'test_clean':
                test_fast.append((x,y,z))
        else :
            if s.singerSet == 'train_clean':
                train_slow.append((x,y,z))
            elif s.singerSet == 'test_clean':
                test_slow.append((x,y,z))
    return (train_fast,train_slow,test_fast,test_slow)
def draw_set_speed(d,title):
    clf = songInfor()
    dl = []
    for key,dur in d.items():
        x,y,z = key
        s = clf.get(x,y,z)
        leng = s.clipSec
        n_phoneme = len(dur)
        speed = leng / n_phoneme
        dl.append(speed)
        #print('{:s}-{:s}-{:s} {:f}'.format(x,y,z,leng / n_phoneme) )
    plt.plot(range(len(dl)),sorted(dl))
    plt.xlabel('clip')
    plt.ylabel('average length of a phoneme')
    plt.title(title)
    plt.plot()
    plt.show()

def draw_clip_speed(d,graphDir):
    if not os.path.isdir(graphDir):
        os.mkdir(graphDir)
    for key,dur in d.items():
        x,y,z = key
        title = '{:s}-{:s}-{:s}'.format(x,y,z)
        #dur = sorted(dur)
        plt.plot(range(len(dur)),dur)
        plt.title(title)
        plt.xlabel('phoneme')
        plt.ylabel('length of a phoneme (s)')
        avg = np.mean(dur)
        avgl = [avg for i in range(len(dur))]
        plt.plot(range(len(dur)),avgl,color='r')
        plt.savefig(os.path.join(graphDir,title + '.png'))
        plt.clf()
    return;




class classifier():
    def __init__(self,dstDir):
        dataPath = '/data/groups/hao246/vocal_data'
        self.dataPath = dataPath
        self.dstDir = dstDir
        self.dstPath = dataPath + '/' + dstDir
        self.songInfo = songInfor()
    def classify(self,songList):
        sec = 0
        for song in songList:
            clip = self.songInfo.get(song[0],song[1],song[2])
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
        lyric = ''
        with open(txtFilePath,'r') as fp:
            for line in fp:
                key = line.split()[0]
                x,y,z = key.split('-')
                if (x,y,z) == (song.singerID,song.songID,song.clipID):
                    lyric = line
                    break
        with open(dstTxtPath,'a') as fp:
            fp.write(lyric)
    def check_and_mkdir(self,path):
        tmp = '/'
        for subdir in path.split('/'):
            tmp = os.path.join(tmp,subdir)
            if os.path.isdir(tmp) is False:
               os.mkdir(tmp)
if __name__ == '__main__':
    d = read_cmt(sys.argv[1])
    train_fast,train_slow,test_fast,test_slow = classify_speed(d,0.15)
    def _clf(dstDir,songList):
        clf = classifier(dstDir)
        clf.classify(songList)
    _clf('train_fast',train_fast)
    _clf('train_slow',train_slow)
    _clf('test_fast',test_fast)
    _clf('test_slow',test_slow)
