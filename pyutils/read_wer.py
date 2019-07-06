import numpy as np
import sys,os
from song import *
class counter():
    def __init__(self,genre, same):
        self.genre = genre
        self.same = same
        self.total = 0.0
        self.err = 0.0
    def update(self,err,total):
        self.err += err
        self.total += total
    def get_wer(self):
        return 100 * self.err/self.total
    def print_wer(self):
        genre = self.genre
        if self.same == False:
            genre = 'NON' + genre
        print('{:15s} : {:.2f}% [ {:d} / {:d} ]'.format(genre,self.get_wer(),
                                                        int(self.err),int(self.total)))
    def check(self,genreList):
        if self.same == True:
            return (self.genre in genreList)
        else:
            return (self.genre not in genreList)
class genreCounter():
    def __init__(self,genreList = ['POP','ELECTRONIC','ROCK','HIPHOP','RNB_SOUL']):
        self.gd = []
        self.total = 0.0
        self.err = 0.0
        for genre in genreList:
            self.gd.append( counter(genre,True))
            self.gd.append( counter(genre,False))
    def update(self,genreList,err,total):
        self.err += err
        self.total += total
        for counter in self.gd:
            if counter.check(genreList):
                counter.update(err,total)
    def get_wer(self):
        return 100 * self.err/self.total
    def print_wer(self):
        for counter in self.gd:
            counter.print_wer()
        print('{:15s} : {:.2f}% [ {:d} / {:d} ]'.format('TOTAL',self.get_wer(),
                                                        int(self.err),int(self.total)))

if __name__ == '__main__':
    decodePath = sys.argv[1]
    werPath = os.path.join(decodePath,'utt_wer')
    E = songInfor()
    G = genreCounter()
    with open(werPath,'r') as wertxt:
        for line in wertxt:
            if line.startswith('0'):
                key,wer,err,total=line.split()[0],line.split()[2],line.split()[4],line.split()[6]
                total = int(total.rstrip(']'))
                err = int(err)
                singerID,songID,clipID = key.split('-')
                clip = E.get(singerID,songID,clipID)
                G.update(clip.songGenre,err,total)  

    G.print_wer()


