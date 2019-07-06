import sys 
import numpy as np
import matplotlib.pyplot as plt
def isfloat(value):
    try:
        float(value)
        return True
    except ValueError:
        return False
def main():
    #python save_pitch.py <data-dir> <output-dir>
    conti=0
    y=[]
    title=" "
    count=0
    for line in open(sys.argv[1],'r'):
        flag=0
        prepart=" "
        for part in line.split():
            if part=='[':
                title=prepart
                count=count+1
            if part==']':
                n = len(y)
                x = np.arange(0,n)*0.01
             #   plt.plot(x,y)
                plt.plot(x[0:1000],y[0:1000]) 
             #   plt.xlim(0,n*0.01)
                plt.xlim(0,10)
                plt.ylim(0,500)
                plt.xlabel("time (s)") 
                plt.ylabel("pitch (Hz)")
                plt.title(title)
                dire=sys.argv[2]
                print dire+title
                plt.savefig(dire+'/'+title,format="png")
                plt.clf()
                y=[]
                break
            if isfloat(part):
                if flag>0:
                    y.append(part)
                else:
                    flag=flag+1
            prepart=part

if __name__=="__main__":
    main()
