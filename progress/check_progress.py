import numpy as np
import sys,os
import matplotlib.pyplot as plt
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("logDir", help = 'log directory of nnet2')
parser.add_argument("firstIter", help = 'first iter', type = int)
parser.add_argument("finalIter", help = 'final iter', type = int)
args = parser.parse_args()

def find_acc(content):
    content = content.rstrip()
    content = content.split()
    flag = 0
    acc = 0
    for word in content:
        if flag > 0:
            flag += 1 
        if word == 'accuracy':
            flag = 1 
        if flag == 5    :
            acc = float(word)
            return acc
X = []
Y_train = []
Y_valid = []
for itr in range(args.firstIter,args.finalIter):
    logFileTrain = os.path.join(args.logDir,'compute_prob_train' + '.' + 
                           str(itr) + '.log' )
    logFileValid = os.path.join(args.logDir,'compute_prob_valid' + '.' + 
                           str(itr) + '.log' )
    with open(logFileTrain,'r') as fp:
        content = fp.read()
    acc_train = find_acc(content) 
    with open(logFileValid,'r') as fp:
        content = fp.read()
    acc_valid = find_acc(content) 
    X.append(itr)
    Y_train.append(acc_train)
    Y_valid.append(acc_valid)
plt.plot(X,Y_train,label = 'train',color='b')
plt.plot(X,Y_valid,label = 'valid',color='r')
plt.legend()
plt.show()
