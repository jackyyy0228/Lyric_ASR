import sys
from song import *
soClass = songInfor()
print('{:3s} {:10s} {:15s} {:40s} {:5s} {:5s}'.format('ID','ID','Set','Genre','sec','wer'))
for (singerID,songID) in soClass.getSongList():
    song = soClass.get_song(singerID,songID)
    if song.singerSet != 'test_clean':
        continue
    x = ''
    for genre in song.songGenre:
        x = x + genre + ' '
    print('{:.3s} {:.10s} {:.15s} {:40s} {:.2f} {:.2f}'.format(song.singerID,song.songID,song.singerSet,x,song.clipSec,song.clipWER))
