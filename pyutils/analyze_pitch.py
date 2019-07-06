import numpy as np
import matplotlib.pyplot as plt
import sys,os
from song import *
def plt_clips_pitch(pitchDir):
    with open(pitchDir,'r') as fp:
        for line in fp:
            line = line.rstrip()
            if line.endswith('['):
                clip = line.split()[0]
                singerID, songID , clipID = clip.split('-')
                clipInfor = song(singerID,songID,clipID)
                pitch = []
            else:
                pitch.append(float(line.split()[1]))
                if line.endswith(']'):
                    pitch = smooth(pitch,75)
                    X = np.arange(0,len(pitch)) * 0.01
                    plt.plot(X,pitch)
                    plt.xlim(0,len(pitch)*0.01)
                    plt.ylim(0,500)
                    plt.xlabel('Time(s)')
                    plt.ylabel('Pitch(Hz)')
                    plt.title(clip+':'+clipInfor.songName)
                    #plt.show()
                    print clip,'is saved.'
                    saveDir = 'exp/pitch/' + sys.argv[1]+ '/smoothed'
                    if os.path.isdir(saveDir) is False:
                        os.mkdir(saveDir)
                    plt.savefig(os.path.join(saveDir,clip))
                    plt.clf()
def sex_pitch_distribution(pitchDir):
    Mpitch = []
    Fpitch = []
    Dpitch = []
    Allpitch = []
    with open(pitchDir,'r') as fp:
        for line in fp:
            line = line.rstrip()
            if line.endswith('['):
                clip = line.split()[0]
                singerID, songID , clipID = clip.split('-')
                clipInfor = song(singerID,songID,clipID)
                print 'Analyzing',clip,'singerSex is',clipInfor.singerSex
                pitch = []
            else:
                pitch.append(float(line.split()[1]))
                if line.endswith(']'):
                    pitch = smooth(pitch,75)
                    if clipInfor.singerSex == 'M':
                        for x in pitch:
                            Mpitch.append(x)
                            Allpitch.append(x)
                    if clipInfor.singerSex == 'F':
                        for x in pitch:
                            Fpitch.append(x)
                            Allpitch.append(x)
                    if clipInfor.singerSex == 'D':
                        for x in pitch:
                            Dpitch.append(x)
                            Allpitch.append(x)
    plt_pitch_distribt(Mpitch,'Male','b')
    plt_pitch_distribt(Fpitch,'Female','r')
    plt_pitch_distribt(Dpitch,'D','g')
    plt_pitch_distribt(Allpitch,'All','k')
    plt.legend()
    plt.show()


def smooth(pitch,weiLen):
    leng = len(pitch)
    result = []
    for i in range(leng):
        start = max(0,i-weiLen)
        end = min(leng,i+weiLen)
        avg = np.mean(pitch[start:end])
        result.append(avg)
    return result
def plt_pitch_distribt(pitch,label,color):
    X = np.arange(1000)
    Y = np.zeros(1000)
    for i in range(len(pitch)):
        Y[int(pitch[i])] += 1
    Y = smooth(Y,5)
    summ = np.sum(Y)
    Y = np.array(Y) / float(summ)
    plt.plot(X,Y,color = color,label = label)
    plt.xlabel('Pitch(Hz)')
    plt.ylabel('density')

def get_all_pitch(pitchDir):
    pitch = []
    with open(pitchDir,'r') as fp:
        clip = []
        for line in fp:
            line = line.rstrip()
            if line.endswith('['):
                continue
            else:
                clip.append(float(line.split()[1]))
                if line.endswith(']'):
                    clip = smooth(clip,75)
                    for x in clip:
                        pitch.append(x)
                    clip = []
    return pitch
if __name__ == '__main__':
    #plt_clips_pitch(sys.argv[1])  
    #sex_pitch_distribution(sys.argv[1])
    #sys.exit()
    ''' 
    pitch = get_all_pitch(sys.argv[1])
    print 'max:',np.max(pitch)
    print 'min:',np.min(pitch)
    print 'mean:',np.mean(pitch)
    plt_pitch_distribt(pitch,'sung','b')
    plt.show()
    sys.exit()
    '''
    sung_pitch = get_all_pitch(sys.argv[1])
    speech_pitch = get_all_pitch(sys.argv[2])
    plt_pitch_distribt(sung_pitch,'sung','r')
    plt_pitch_distribt(speech_pitch,'speech','b')
    plt.legend()
    plt.savefig('sung_speech')
     #plt.show()
    
    
    
                    


                
