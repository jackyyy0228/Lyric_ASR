import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt

import numpy as np
import math
import re

_tag = re.compile(r'\d+-\d+-\d+')

with open('tmp_mfcc_pitch_2.txt','r') as f:
    
    pre_utt = None

    for _, line in enumerate(f):
        utt = _tag.findall(line) 
        if len(utt) == 1:
            
            if pre_utt is not None:
                fig = plt.figure(1)
                fig, ax = plt.subplots(4, sharex=True)
                time_list = np.array(range(len(delta_list))) * 0.01
                delta_contour, = ax[0].plot(time_list, np.array(delta_list), 'b')
                normalize_contour, = ax[1].plot(time_list, np.array(normalize_list), 'g')
                pov_contour, = ax[2].plot(time_list, np.array(pov_list), 'r')
                pitch_contour, = ax[3].plot(time_list, np.array(pitch_list), 'k')
                plt.legend([delta_contour, normalize_contour, pov_contour, pitch_contour], ['delta', 'normalize', 'pov', 'pitch'])
                plt.savefig('{}_contour'.format(pre_utt[0]))
                plt.close(fig)

            pre_utt = utt
            delta_list = []
            normalize_list = []
            pov_list = []
            pitch_list = []

        else:

            if pre_utt is not None:
                mfcc = line.split()
                if mfcc[-1] == ']':
                    mfcc = mfcc[:-1]
                delta_list.append(float(mfcc[-4]))
                normalize_list.append(float(mfcc[-3]))
                pov_list.append(float(mfcc[-2]))
                hz = math.exp(float(mfcc[-1]))
                pitch_list.append( 69 + 12 * math.log(hz/440, 2) )

