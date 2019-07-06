import sys
from song import *
soClass = songInfor()
gen = ['POP','ELECTRONIC','ROCK','HIPHOP','RNB_SOUL']
count = [0.0,0.0,0.0,0.0,0.0]
total = 0.0
for (singerID,songID) in soClass.getSongList():
    song = soClass.get_song(singerID,songID)
    if song.singerSet == 'train_clean':
        total += song.clipSec
        for genre in song.songGenre:
            for idx,y in enumerate(gen):
                if y == genre:
                    count[idx] += song.clipSec
print(total/60)
for idx,genre in enumerate(gen):
    print('{:s} {:f} {:f}'.format(genre,count[idx]/60,count[idx]/total))
