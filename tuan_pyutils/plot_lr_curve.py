import os
import argparse

import re
import numpy as np
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt

_tag = re.compile(br"accuracy")
_acc = re.compile(br"\s0\.\d+")

parser = argparse.ArgumentParser()
parser.add_argument("--model-dir", type=str, default=None)
FLAGS = parser.parse_args()

train_dict = {}
valid_dict = {}
train_curve = []
valid_curve = []

data_dir = os.path.join(FLAGS.model_dir, 'log')
if not (os.path.exists(data_dir)):
    raise ValueError("data direstory %s not found.", data_dir)
for item in os.listdir(data_dir):
    if os.path.isfile(os.path.join(data_dir,item)) \
            and item[:12] == 'compute_prob':
        name, it = os.path.splitext(os.path.splitext(item)[0])
        name = name[-5:]
        it = it[1:]
        with open(os.path.join(data_dir, item), 'rb') as f:
            for _, line in enumerate(f):
                check_list = _tag.findall(line)
                if len(check_list) > 0:
                    acc_list = _acc.findall(line)
                    acc = float(acc_list[0])
                    if name == 'train':
                        train_dict[it] = acc
                    elif name == 'valid':
                        valid_dict[it] = acc

for i in range(len(train_dict)-1):
    train_curve.append(train_dict[str(i)])
train_curve.append(train_dict['final'])
for i in range(len(valid_dict)-1):
    valid_curve.append(valid_dict[str(i)])
valid_curve.append(valid_dict['final'])

print(train_curve)
print(valid_curve)

fig = plt.figure(1)
train_line, = plt.plot(range(len(train_curve)), np.array(train_curve),'b')
valid_line, = plt.plot(range(len(valid_curve)), np.array(valid_curve),'g')
plt.legend([train_line, valid_line], ['train', 'valid'])
plt.savefig('learning_curve_{}'.format(os.path.basename(FLAGS.model_dir)))
