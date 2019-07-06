import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--level2spk", type=str, default=None)
parser.add_argument("--spk2level", type=str, default=None)
parser.add_argument("--spk2utt", type=str, default=None)
FLAGS = parser.parse_args()

spk2level_dict = {}
with open(FLAGS.spk2level, 'r') as f:
    for _, line in enumerate(f):
        ids, _ = line.split(' ', 1)
        level2spk_dict[ids] = dup_list
