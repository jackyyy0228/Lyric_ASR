from song import *
import os
def get_vocal_lyric():
    songs =  []
    vocalDir = '/data1/hao246/vocal_data/all'
    for root,dirs,files in os.walk(vocalDir):
        for filee in files:
            if filee.endswith('.flac'):
                name = filee.rstrip('.flac')
                songs.append(name.split('-'))
    return songs
def delete_lyric(songs):
    corpusPath = '/data1/hao246/lyric_corpus/all'
    engine = songInfor()
    songnames = []
    for song in songs:
        infor = engine.get(song[0],song[1],song[2])
        songnames.append(infor.songName.upper().replace(' ','_'))
        songnames.append(songnames[0].replace('\'','%27'))
    idx = 0
    for root,dirs,files in os.walk(corpusPath):
        for filee in files:
            if filee.rstrip('.txt').upper() in songnames:
                os.remove(os.path.join(root,filee))
                


    
if __name__ == '__main__':
    songs = get_vocal_lyric()
    delete_lyric(songs)
