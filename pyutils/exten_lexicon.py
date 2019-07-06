import os,sys,math
def check_vowel(phone):
    if phone.startswith(('A','E','I','O','U')):
        return True
    else:
        return False
def exten(oriDir,srcDir):
    lxcr = os.path.join(oriDir,'lexicon.txt')
    lxcpr = os.path.join(oriDir,'lexiconp.txt')
    lxcw = os.path.join(srcDir,'lexicon.txt')
    lxcpw = os.path.join(srcDir,'lexiconp.txt')
    if os.path.isfile(lxcw):
        print(lxcw,'exists')
        return;
    summ =0
    with open(lxcr,'r') as fr, open(lxcw,'w') as fw:
        for line in fr:
            line = line.rstrip()
            word = line.split()[0]
            phones = line.split()[1:]
            cnt = 0
                
            seqs = gen_seqs(word,phones)
            for seq in seqs:
                fw.write(seq+'\n')
    with open(lxcpr,'r') as fr, open(lxcpw,'w') as fw:
        for line in fr:
            line = line.rstrip()
            word = line.split()[0] + ' ' + line.split()[1]
            phones = line.split()[2:]
            seqs = gen_seqs(word,phones)
            for seq in seqs:
                fw.write(seq+'\n')

def gen_seqs(word,phones):
    seqs = [word]
    cnt = 0
    for phone in phones:
        if check_vowel(phone):
            cnt += 1
    if cnt >3:
        for phone in phones:
            seqs[0] = seqs[0] + ' ' + phone
        return seqs
    for phone in phones:
        for idx,seq in enumerate(seqs):
            seq = seq + ' ' + phone
            seqs[idx] = seq
        if check_vowel(phone):
            temp = list(seqs)
            for idx,seq in enumerate(temp):
                seq = seq + ' ' + phone
                temp[idx] = seq
            seqs = seqs + temp
    return seqs



if __name__ == '__main__':
    oriDir = sys.argv[1]
    srcDir = sys.argv[2]
    exten(oriDir,srcDir)
