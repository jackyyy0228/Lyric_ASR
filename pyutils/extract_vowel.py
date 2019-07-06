#It is used to extract the vowel in show-transition output file
import sys
transitionFile = sys.argv[1]

S = set()
with open(transitionFile,'r') as fp:
    flag = False
    for line in fp:
        line = line.rstrip()
        if line.startswith('Transition-state'):
            flag = False
            phone = line.split()[4]
            if phone.startswith(('A','E','I','O','U')):
                state = line.split()[7]
                S.add(state)
                if state == '5' :
                    flag = True
        if flag :
            print(line)
print(S)
