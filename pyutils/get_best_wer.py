import sys
import numpy as np
WERPath = sys.argv[1]
with open(WERPath,'r') as fp:
    lines= []
    wer = []
    for line in fp:
        lines.append(line)
        x = float(line.split()[1])
        wer.append(x)
    idx=np.argmin(wer)
    target = lines[idx].split()[0]
    pos = target.find(':')
    target = target[0:pos]
    back = target[::-1].find('/')
    target = target[-back+4:]
    target = target.replace('_','.')
    print(target)

