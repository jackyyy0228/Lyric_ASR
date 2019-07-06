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
                singerID,songID,clipID = key.split('-')
                lyric = searchEngine.get_lyric(singerID,songID,clipID)
                ref.append(lyric)
                break
with open(dstDir+ '/ref.txt','w') as fp :
    for line in ref:
        fp.write(line)
with open(dstDir+ '/hyp.txt','w') as fp :
    for line in hyp:
        fp.write(line)

            

