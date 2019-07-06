import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--level2spk", type=str, default=None)
parser.add_argument("--in-trans", type=str, default=None)
parser.add_argument("--out-trans", type=str, default=None)
FLAGS = parser.parse_args()

dup_dict = {}
with open(FLAGS.level2spk, 'r') as f:
    for _, line in enumerate(f):
        ids, dup_list = line.split(' ', 1)
        dup_list = dup_list.split()
        dup_dict[ids] = dup_list

prev = None
pre_id = None
with open(FLAGS.in_trans, 'r') as f:
    all_lines = f.readlines()
with open(FLAGS.out_trans, 'w') as fout:
    with open(FLAGS.in_trans, 'r') as f:
        for line_no, line in enumerate(f):
            ids, _ = line.split(' ', 1)
            if ids in dup_dict:
                if prev is not None:
                    matrix = all_lines[prev+1:line_no]
                    for name in dup_dict[pre_id]:
                        fout.write('{}  [\n'.format(name))
                        for vec in matrix:
                            fout.write(vec)
                prev = line_no
                pre_id = ids
                
        if prev is not None:
            matrix = all_lines[prev+1:]
            for name in dup_dict[pre_id]:
                fout.write('{}  [\n'.format(name))
                for vec in matrix:
                    fout.write(vec)
