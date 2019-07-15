# Lyric_ASR
Implementation of ["Transcribing Lyrics From Commercial Song Audio: The First Step Towards Singing Content Processing"](https://arxiv.org/abs/1804.05306)

## How to use

### Dependencies

- kaldi 

- srilm (can be built with `kaldi/tools/install_srilm.sh`)

### Path

- Modify path.sh with your path of kaldi and srilm.

- Relink utils and steps to `kaldi/egs/wsj/s5/utils` and `kaldi/egs/wsj/s5/steps`.

### Preprocess acoustic data

- Modify path of vocal_data in `progress/prepare_data.sh`

- Then run following commands:

```
$ bash progress/prepare_data.sh
```

### Train LMs

- Modify paths in `progress/process_lm.sh`

```
$ bash  progress/process_lm.sh
```

### Train HMM-GMM models

```
$ bash progress/run.sh
```

### Train blstm models

```
$ bash progress/nnet3/run_blstm_wsj.sh 10 500 125 2
```

### Train tdnn-lstm models

```
$ bash progress/nnet3/run_tdnn_lstm_1a_wsj.sh 10 130 65
```

## Files and Directories

* **conf** : configuration files (Ex: number of bins in extracting mfcc)

* **local** : training scripts for librispeech

* **progress** : our training scripts put in here

* **pyutils** : python codes (often used by scripts) written by Tsai

* **more_tools** : other python codes (independent to the scripts) written by Tuan

* **path.sh** : specified paths for kaldi, srilm...etc

* **steps** : One should soft link steps directory in wsj to it.(`ln -s $wsj_steps ./`)

* **utils** : One should soft link utils directory in wsj to it (`ln -s $wsj_utils ./`)


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
