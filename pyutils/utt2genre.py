from song import *
import math
clf = songInfor()
songList = []
genreList = ['ELECTRONIC','POP','ROCK','RNB_SOUL','HIPHOP']
for x,y in clf.getSongList():
    z = 0
    for genre in sorted(clf.get_song(x,y).songGenre):
        for idx,ref in enumerate(genreList):
            if ref == genre : 
                z += 1*math.pow(10,idx)
    songList.append(int(z))
genreDict = {key:value for value,key in enumerate(set(songList))}

for x,y in clf.getSongList():
    t = 0
    S = clf.get_song(x,y)
    if S.singerSet != sys.argv[1]:
        continue
    for genre in sorted(S.songGenre):
        for idx,ref in enumerate(genreList):
            if ref == genre : 
                t += 1*math.pow(10,idx)
    t = int(t)
    print("{:s} {:s} {:d}".format(x,y, genreDict[t]))
