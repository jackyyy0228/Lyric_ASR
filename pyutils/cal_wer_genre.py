import sys

if len(sys.argv) != 2:
    print('Usage : {:s} decodePath/utt_wer'.format(sys.argv[0]))
    sys.exit(1)

uwPath = sys.argv[1]
class clipWER():
    def __init__(self):
        self.sd={}
    def add(self,key,wrong,total):
        if key in self.sd:
            x,y,z = self.sd[key]
            x += wrong
            y += total
            z += 1
            self.sd[key] = (x,y,z)
        else:
            self.sd[key] = (float(wrong),float(total),1)
    def get_avg_wer(self):
        wrong = 0.0
        total = 0.0
        for key,value in self.sd.items():
            x,y,z = value
            wrong += x/z
            total += y/z
        return wrong / total
    def get_wer(self):
        wrong = 0.0
        total = 0.0
        for key,value in self.sd.items():
            x,y,z = value
            wrong += x
            total += y
        return wrong / total

clipwer=clipWER()
with open(uwPath,'r') as uf:
    for line in uf:
        if line.startswith('%') or line.startswith('S'):
            continue
        token = line.split()
        key,wrong,total = token[0],int(token[4]),token[6]
        total = int(total[:-1])
        genreID,temp,clipID = key.split('-')
        singerID,songID = temp[:3],temp[3]
        keyDict = (singerID,songID,clipID)
        clipwer.add(keyDict,wrong,total)
print('ori: {:.2f}'.format(100*clipwer.get_wer()))
print('avg: {:.2f}'.format(100*clipwer.get_avg_wer()))
        

