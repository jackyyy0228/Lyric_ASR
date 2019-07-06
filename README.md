# Lyric_ASR
Implementation of "Transcribing Lyrics From Commercial Song Audio: The First Step Towards Singing Content Processing"

## How to use

### Dependencies

-kaldi 

-srilm (can be built with kaldi/tools/install_srilm.sh)

### Path

- Modify path.sh with your path of kaldi and srilm.

### Preprocess

- Modify path of vocal_data in progress/prepare_data.sh

- Then run following commands:

```
$ bash progress/prepare_data.sh
```

### Train HMM-GMM models

```
$ bash progress/run.sh
```

## Citation

```
@inproceedings{tsai2018transcribing,
  title={Transcribing lyrics from commercial song audio: the first step towards singing content processing},
  author={Tsai, Che-Ping and Tuan, Yi-Lin and Lee, Lin-shan},
  booktitle={2018 IEEE International Conference on Acoustics, Speech and Signal Processing (ICASSP)},
  pages={5749--5753},
  year={2018},
  organization={IEEE}
}
```
