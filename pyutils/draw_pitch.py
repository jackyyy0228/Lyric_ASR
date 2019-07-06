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
    conti=0
    breakpoint=0
    y=[]
    for line in open(sys.argv[1],'r'):
        flag=0
        for part in line.split():
            if part==sys.argv[2]: 
                conti=1
            if part==']':
                if conti==1:
                    breakpoint=1
                    conti=0
                    break
            if isfloat(part) and conti :
                if flag>0:
                    y.append(part)
                else:
                    flag=flag+1
        if breakpoint==1:
            break
    n = len(y)
    x = np.arange(0,n)*0.01
    plt.plot(x,y) 
    plt.xlim(0,n*0.01)
    plt.ylim(0,500)
    plt.xlabel("time (s)") 
    plt.ylabel("pitch (Hz)") 
    plt.title(sys.argv[2]) 
    plt.show()

if __name__=="__main__":
    main()
