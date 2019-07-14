gender_dict = {}
gender_dict['M'] = []
gender_dict['F'] = []
gender_dict['D'] = []

spk_gender_dict = {}

with open('../vocal_data/SINGERS.TXT') as singers:
    for i, line in enumerate(singers):
        if i < 3:
            continue
        spkid, _, _, gender = line.split('|', 3)
        if spkid and gender:
            spkid = spkid.strip()
            gender = gender.strip()
            spk_gender_dict[spkid] = gender

prev = None
with open('data/vocal/test_clean/utt2spk') as utt2spk:
    for _, line in enumerate(utt2spk):
        _, song = line.split()
        spk, spk_song = song.split('-')
        spk = spk.strip()
        if prev == spk :
            continue
        gender_dict[spk_gender_dict[spk]].append(spk)
        prev = spk

for gender in gender_dict:
    print('Gender {} has {} singers in {}'
          .format(gender, len(gender_dict[gender]), 'data/vocal/all_clean'))
    print(gender_dict[gender])
print(gender_dict)
print(spk_gender_dict)
