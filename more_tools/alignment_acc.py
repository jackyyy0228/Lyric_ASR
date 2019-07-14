from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import argparse
import itertools
import numpy as np

# Word Alignment Accuracy
# Average alignment error duration

# Arguments Paser
parser = argparse.ArgumentParser(description="""Calculate WAA ignoring silence(or short pause) duration.
                                 For consider sil & sp duration, please refer to \'WAA.py\'.""")
parser.add_argument("--data-dir",type=str,default=None,
                    help="directory of labeled TextGrid files.")
parser.add_argument("--model-dir",type=str,default=None,
                    help="directory of ctm files.")
parser.add_argument("--output-dir",type=str,default=None,
                    help="directory to store output logfile.")
args = parser.parse_args()


def read_labeled_data(data_dir):
    '''read labeled data
    target_utts = ["004-1-0003","009-4-0001","025-1-0001","027-1-0003",
                   "047-3-0007","049-1-0002","061-2-0004","069-1-0008",
                   "077-1-0012","081-1-0001","084-1-0002","085-1-0002",
                   "087-1-0004"]
    '''
    target_utts = []
    labeled_files = []
    if not (os.path.exists(data_dir)):
        raise ValueError("data direstory %s not found.", data_dir)
    for item in os.listdir(data_dir):
        if os.path.isfile(os.path.join(data_dir,item)) and os.path.splitext(item)[-1] == '.TextGrid':
            target_utts.append(os.path.splitext(item)[0])
            labeled_files.append(os.path.join(data_dir,item))
    target_utts.sort()
    labeled_files.sort()
    print("Number of used labeled data: %d" % len(target_utts))

    sureset = { utt:[] for utt in target_utts }
    # Parse labeled praat TextGrid
    for utt, file_per_utt in zip(target_utts, labeled_files):
        with open(file_per_utt,'r') as grid:
            lines = grid.read().splitlines()
            idx = 15
            while idx+2 <= len(lines):
                dummy, start = lines[idx].split(' = ',2)
                dummy, end = lines[idx+1].split(' = ',2)
                dummy, word = lines[idx+2].split(' = ',2)
                word, dummy = word[1:].split('\"',2)
                if word != "<sil>" and word != "<uh>" and word != "":
                    sureset[utt].append([float(start),float(end),word])
                idx += 4
    return sureset, target_utts


def read_model_preds(model_dir,target_utts):
    if not (os.path.exists(model_dir)):
        raise ValueError("model direstory %s not found.", model_dir)
    models_list = []
    prefixes = []
    for item in os.listdir(model_dir):
        if os.path.isfile(os.path.join(model_dir,item)) and ( 'ctm' in item ):
            models_list.append(os.path.join(model_dir,item))
            prefixes.append(item.split('-',2)[-1])
    print("Number of models(ctms): %d" % len(prefixes))
    preds = []
    for idx, name in enumerate(prefixes):
        predset = { utt: [] for utt in target_utts }
        preds.append([name,predset])

    # Parse word-level alignment ctm
    for ctmfile , [_, predset] in zip(models_list, preds):
        with open(ctmfile,'r') as ctm:
            for idx, line in enumerate(ctm):
                utt, seg, start, dur, word = line.split(' ',4)
                if ( utt in target_utts ):
                    predset[utt].append([float(start),float(start)+float(dur),word[:-2]])
    return preds

def alignment_LCS(predseq, sureseq):
    LEFT = 0
    UP = 1
    UPLEFT = 2
    array = np.empty([len(predseq)+1, len(sureseq)+1], dtype=int)
    prev = np.empty([len(predseq)+1, len(sureseq)+1], dtype=int)
    print("sureseq num: %d" % len(sureseq))
    print("predseq num: %d" % len(predseq))

    for i in range(0,len(predseq)+1):
        array[i][0] = 0
    for j in range(0,len(sureseq)+1):
        array[0][j] = 0

    for i in range(1,len(predseq)+1):
        for j in range(1,len(sureseq)+1):
            if (predseq[i-1][2] == sureseq[j-1][2]):
                array[i][j] = array[i-1][j-1] + 1
                prev[i][j] = UPLEFT
            else:
                if (array[i-1][j] < array[i][j-1]):
                    array[i][j] = array[i][j-1]
                    prev[i][j] = LEFT
                else:
                    array[i][j] = array[i-1][j]
                    prev[i][j] = UP
 
    (i,j) = (len(predseq), len(sureseq))
    print(array.shape)
    print('LCS: %d' % array[i][j])
    align_set = []
    no_i_set = []
    no_j_set = []

    while True:
        if i < 1 or j < 1:
            break
        if (prev[i][j] == UPLEFT):
            (i,j) = (i-1, j-1)
            align_set.append((i,j))
        elif (prev[i][j] == UP):
            (i,j) = (i-1, j)
            no_i_set.append(i)
        elif (prev[i][j] == LEFT):
            (i,j) = (i, j-1)
            no_j_set.append(j)
    return align_set, no_i_set, no_j_set

def calc_and_write_log(outfile, predset, sureset, target_utts):
    with open(outfile, 'w') as fout:
        all_accnum = 0
        all_accdur = 0.0
        all_totaldur = 0.0
        all_loosenum = 0
        all_totalnum = 0
        for utt in target_utts:
            accnum = 0
            accdur = 0.0
            totaldur = 0.0
            loosenum = 0
            totalnum = 0
            totaldur += sureset[utt][-1][1] - sureset[utt][0][0]
            fout.write("%s\n" % utt)
            fout.write("sureset num: %d\n" % len(sureset[utt]))
            fout.write("predset num: %d\n" % len(predset[utt]))

            if len(predset[utt]) == 0:
                continue
            seq_gen, fail_pred, fail_sure = alignment_LCS(predset[utt], sureset[utt])
            for i in fail_pred:
                fout.write("fail pred: %s\n" % predset[utt][i][2])
            for j in fail_sure:
                fout.write("fail sure: %s\n" % sureset[utt][j][2])
            for i,j in reversed(seq_gen):
                if predset[utt][i][2] == sureset[utt][j][2]:
                    # write out the labeled and prediction
                    '''
                    fout.write("Correspond: %s, %s\n" %(predset[utt][i][2], sureset[utt][j][2]))
                    fout.write("%s, " % utt)
                    fout.write("%s\n" % sureset[utt][slide][2])
                    fout.write('start time(ans,pred): %f, %f\n' %(sureset[utt][slide][0], label[0]))
                    fout.write('end time(ans,pred): %f, %f\n' %(sureset[utt][slide][1], label[1]))
                    '''
                    dur = sureset[utt][j][1] - sureset[utt][j][0]
                    tolr = 0.2 * dur
                    # Set the tolerance correspond to the word duration
                    if ( abs(sureset[utt][j][0] - predset[utt][i][0]) <=tolr
                            and abs(predset[utt][i][1] - sureset[utt][j][1])<=tolr ):
                        accnum += 1
                        '''
                        fout.write("True\n")
                        '''
                    elif (i>0 and i<len(predset[utt])-1):
                        if (((sureset[utt][j][1] > predset[utt][i][1]) and ( predset[utt][i+1][0] > sureset[utt][j][1]))
                            or ((sureset[utt][j][0] < predset[utt][i][0]) and ( predset[utt][i-1][1] < sureset[utt][j][0] ))):
                            loosenum += 1
                            '''
                            fout.write("Loose True\n")
                        fout.write("False\n")
                    else:
                        fout.write("False\n")'''
                    if predset[utt][i][0] < sureset[utt][j][1] and sureset[utt][j][0] < predset[utt][i][1]:
                        adur = min(predset[utt][i][1],sureset[utt][j][1]) - max(predset[utt][i][0],sureset[utt][j][0])
                        accdur += adur
                    #fout.write("errdur: %f\n" %(e))
                    totalnum += 1
                    # Set the current flag
            fout.write('totalnum: %d\n' % totalnum)
            print('Total: %d' % totalnum)
            if totalnum > 0:
                fout.write('WAA=%f\n' % (float(accnum)/totalnum))
                fout.write('WCAA=%f\n' % (float(accnum+loosenum)/totalnum))
                fout.write('AvgErrDur=%f\n' % ((totaldur-accdur)/totalnum))
            else:
                fout.write('WAA=NAN')
                fout.write('WCAA=NAN')
                fout.write('AvgErrDur=NAN')

            all_accnum += accnum
            all_accdur += accdur
            all_totaldur += totaldur
            all_loosenum += loosenum
            all_totalnum += totalnum

        fout.write('total word num: {}\n'.format(all_totalnum))
        fout.write('total acc word num: {}\n'.format(all_accnum))
        fout.write('total duration: {}\n'.format(all_totaldur))
        fout.write('total acc duration: {}\n'.format(all_accdur))
        # Write out AER
        fout.write('WAA=%f\n' % (float(all_accnum)/all_totalnum))
        fout.write('WCAA=%f\n' % (float(all_accnum+all_loosenum)/all_totalnum))
        fout.write('AvgErrDur=%f\n' % ((all_totaldur-all_accdur)/all_totalnum))
                


def old_calc_and_write_log(outfile,predset,sureset,target_utts):
    with open(outfile,'w') as fout:
        all_accnum = 0
        all_accdur = 0.0
        all_totaldur = 0.0
        all_loosenum = 0
        all_totalnum = 0
        # Compare prediction and label
        print(target_utts)
        for utt in target_utts:
            accnum = 0
            accdur = 0.0
            totaldur = 0.0
            loosenum = 0
            totalnum = 0
            totaldur += sureset[utt][-1][1] - sureset[utt][0][0]
            pointer = 0
            slide = 0
            fout.write("%s\n" % utt)
            fout.write("sureset num: %d\n" % len(sureset[utt]))
            fout.write("predset num: %d\n" % len(predset[utt]))
            for idx, label in enumerate(sureset[utt]):
                if idx < len(predset[utt]):
                    fout.write("%s, %s\n" % (label[2], predset[utt][idx][2]))
                while True:
                    if pointer >= len(predset[utt]):
                        break
                    elif slide >= len(predset[utt]):
                        slide = pointer
                        break
                    # If find the same word
                    if label[2] == predset[utt][slide][2]:
                        fout.write("Correspond: %s, %s\n" %(label[2],predset[utt][slide][2]))
                        # write out the labeled and prediction
                        '''
                        fout.write("%s, " % utt)
                        fout.write("%s\n" % sureset[utt][slide][2])
                        fout.write('start time(ans,pred): %f, %f\n' %(sureset[utt][slide][0], label[0]))
                        fout.write('end time(ans,pred): %f, %f\n' %(sureset[utt][slide][1], label[1]))
                        '''
                        dur = label[1] - label[0]
                        tolr = 0.2 * dur
                        # Set the tolerance correspond to the word duration
                        if ( abs(label[0] - predset[utt][slide][0]) <=tolr
                                and abs(predset[utt][slide][1] - label[1])<=tolr ):
                            accnum += 1
                            '''
                            fout.write("True\n")
                            '''
                        elif (slide>0 and slide<len(predset[utt])-1):
                            if (( predset[utt][slide+1][0] > label[1])
                                or ( predset[utt][idx-1][1] < label[0] )):
                                loosenum += 1
                                '''
                                fout.write("Loose True\n")
                            fout.write("False\n")
                        else:
                            fout.write("False\n")'''
                        if predset[utt][slide][0] < label[1] and label[0] < predset[utt][slide][1]:
                            adur = min(predset[utt][slide][1],label[1]) - max(predset[utt][slide][0],label[0])
                            accdur += adur
                        #fout.write("errdur: %f\n" %(e))
                        totalnum += 1
                        slide += 1
                        # Set the current flag
                        pointer = slide
                        break
                    else:
                        slide += 1
            fout.write('totalnum: %d\n' % totalnum)
            if totalnum > 0:
                fout.write('WAA=%f\n' % (float(accnum)/totalnum))
                fout.write('WCAA=%f\n' % (float(accnum+loosenum)/totalnum))
                fout.write('AvgErrDur=%f\n' % ((totaldur-accdur)/totalnum))
            else:
                fout.write('WAA=NAN')
                fout.write('WCAA=NAN')
                fout.write('AvgErrDur=NAN')
            
            all_accnum += accnum
            all_accdur += accdur
            all_totaldur += totaldur
            all_loosenum += loosenum
            all_totalnum += totalnum

        # Write out AER
        fout.write('WAA=%f\n' % (float(all_accnum)/all_totalnum))
        fout.write('WCAA=%f\n' % (float(all_accnum+all_loosenum)/all_totalnum))
        fout.write('AvgErrDur=%f\n' % ((all_totaldur-all_accdur)/all_totalnum))

def main():
    sureset, target_utts = read_labeled_data(args.data_dir)
    preds = read_model_preds(args.model_dir, target_utts)
    if not os.path.exists(args.output_dir):
        os.mkdir(args.output_dir)
    for name, predset in preds:
        outfile = os.path.join(args.output_dir, name+str(len(target_utts))+'.log')
        calc_and_write_log(outfile, predset, sureset, target_utts)

if __name__ == "__main__":
    main()
