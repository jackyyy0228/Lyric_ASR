import os
import copy
import numpy as np
import re
import argparse

_tag = re.compile(r'\d+-\d+-\d+')

def calc_accuracy(h, r):
    
    LEFT = 0
    UP = 1
    UPLEFT = 2

    prev = np.empty([len(h)+1, len(r)+1], dtype=int)
    stat = copy.deepcopy(prev)
    error = copy.deepcopy(prev)
    SID = [0, 0, 0]

    for i in range(0, len(h)+1):
        stat[i][0] = 0
        error[i][0] = i
    for j in range(0, len(r)+1):
        stat[0][j] = 0
        error[0][j] = j

    for i in range(1, len(h)+1):
        for j in range(1, len(r)+1):
            if (h[i-1] == r[j-1]):
                stat[i][j] = stat[i-1][j-1] + 1
                error[i][j] = error[i-1][j-1]
                prev[i][j] = UPLEFT
            else:
                S = error[i-1][j-1] + 1
                I = error[i-1][j] + 1
                D = error[i][j-1] + 1
                error[i][j] = int(np.min([S, I, D]))
                SID[np.argmin([S, I, D])] += 1
                if (stat[i-1][j] < stat[i][j-1]):
                    stat[i][j] = stat[i][j-1]
                    prev[i][j] = LEFT
                else:
                    stat[i][j] = stat[i-1][j]
                    prev[i][j] = UP

    acc_num = stat[len(h)][len(r)]
    error_num = error[len(h)][len(r)]
    
    (i, j) = (len(h), len(r))
    common_seq = []
    
    while True:
        if i < 1 or j < 1:
            break
        if prev[i][j] == UPLEFT:
            common_seq.append(r[j-1])
            (i, j) = (i-1, j-1)
        elif prev[i][j] == UP:
            (i, j) = (i-1, j)
        elif prev[i][j] == LEFT:
            (i, j) = (i, j-1)

    common_seq = list(reversed(common_seq))
    print('common :')
    print(' '.join([token for token in common_seq]))
    
    return acc_num, error_num, SID[0], SID[1], SID[2]


parser = argparse.ArgumentParser()
parser.add_argument("--best-path", type=str, default=None)
FLAGS = parser.parse_args()

if not (os.path.exists(FLAGS.best_path)):
    raise ValueError("data direstory %s not found.", FLAGS.best_path)

lexicon = {}
with open('data/lang_lyric/phones/align_lexicon.txt','r') as f:
    for _, line in enumerate(f):
        word, _, phones = line.split(' ', 2)
        word = word.strip()
        phones = phones.split()
        lexicon[word] = phones
print('finish reading lexicon')

ans_dict = {}
with open('data/paper/test_clean_utt/text','r') as f:
    for _, line in enumerate(f):
        utt, ans = line.split(' ', 1)
        utt = utt.strip()
        ans = ans.strip()
        ans_dict[utt] = ans

total_num = 0
total_oov = 0
total_acc_num = 0
total_err_num = 0
total_sub_num = 0
total_ins_num = 0
total_del_num = 0
total_ref_num = 0

store = False

with open(FLAGS.best_path, 'r') as f, open('utt_wer', 'w') as fout:
    for _, line in enumerate(f):
        if store:
            result = line.strip()
            store = False
        else:
            if line[0] == '#':
                continue
            label, result = line.split(' ', 1)
            utt = _tag.findall(label)
            if len(utt) == 1:
                total_num += 1
                utt = utt[0].strip()
                result = result.strip()
                if result.split()[0] == 'LOG':
                    store = True
            else:
                 continue

        print(utt)
        #print(ans_dict[utt])
        #print(result)
        hyp = result.split()
        ref = ans_dict[utt].split()
        ''' 
        tmp_h = []
        for word in hyp:
            #tmp_h.extend(lexicon[word])
            if word in lexicon:
                tmp_h.extend(lexicon[word])
            else:
                tmp_h.extend(['RUNK'])
                total_oov += 1
                print(word)
        tmp_r = []
        for word in ref:
            if word in lexicon:
                tmp_r.extend(lexicon[word])
            else:
                tmp_r.extend(['UNK'])
                total_oov += 1
                print(word)
        hyp = tmp_h
        ref = tmp_r
        '''
        acc_num, err, sub, ins, dele = calc_accuracy(hyp, ref)
        tmp = '{} %PER {:.6f} [ {} / {} ]\n'.format(utt, (1.-float(acc_num)/len(ref))*100, len(ref)-acc_num, len(ref))
        fout.write(tmp)
        #print('err: %d' %(err))
        #print('acc: %d, %.2f' % (acc_num, acc_num / len(ref)))
        total_acc_num += acc_num
        total_err_num += err
        #total_sub_num += sub
        #total_ins_num += ins
        #total_del_num += dele
        total_ref_num += len(ref)

print(total_num)
print(total_oov)
print('[%d/%d], acc: %.4f, ER: %.4f'
      % (total_acc_num, total_ref_num,
         total_acc_num / total_ref_num,
         total_err_num / total_ref_num))
