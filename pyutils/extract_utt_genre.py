import sys
from song import *
bestPathFile = sys.argv[1]
dstDir = sys.argv[2]

with open(bestPathFile,'r') as fp:
    ref = []
    hyp = []
    searchEngine = songInfor()
    for line in fp:
        for idx in range(6):
            if line.startswith(str(idx)):
                key = line.split()[0]
                hyp.append(line)
                genreID,temp,clipID = key.split('-')
                singerID = temp[:3]
                songID = temp[3]
                lyric = searchEngine.get_lyric(str(singerID),str(songID),str(clipID))
                temp,lyric = lyric.split(' ',1)
                ref.append(key + ' ' + lyric)
                break
with open(dstDir+ '/ref.txt','w') as fp :
    for line in ref:
        fp.write(line)
with open(dstDir+ '/hyp.txt','w') as fp :
    for line in hyp:
        fp.write(line)

            

