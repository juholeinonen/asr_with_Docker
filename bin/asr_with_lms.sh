#!/bin/bash
# align will be copied from outside

bin_folder=asr_with_Docker/bin
csv_file=$bin_folder/phone-finnish-finnish.csv

ln -s ../wsj/s5/utils utils
ln -s ../wsj/s5/steps steps

cp ../wsj/s5/path.sh .

sed -i '1 s/...$//' path.sh

cat <<EOF > data/dict/optional_silence.txt
SIL
EOF

cat <<EOF > data/dict/silence_phones.txt
NSN
SIL
SPN
EOF

cat <<EOF > data/dict/nonsilence_phones.txt
2
A
I
N
U
b
d
e
f
g
h
j
k
l
m
n
o
p
r
s
t
v
y
{
EOF


python3 $bin_folder/change_lex_pho.py data/local/lm/200000.words $csv_file
mv lexicon.txt data/dict

extra=3
utils/prepare_lang.sh --num-extra-phone-disambig-syms $extra data/dict "<UNK>" data/lang/local data/lang


# IF USING MORPHS. CHECK https://github.com/aalto-speech/subword-kaldi README
#utils/prepare_lang.sh --phone-symbol-table data/lang/phones.txt --num-extra-phone-disambig-syms $extra data/subword_dict "<UNK>" data/subword_lang/local data/subword_lang
#dir=data/subword_lang
#tmpdir=data/subword_lang/local
# Overwrite L_disambig.fst
#common/make_lfst_wb.py $(tail -n$extra $dir/phones/disambig.txt) < $tmpdir/lexiconp_disambig.txt | fstcompile --isymbols=$dir/phones.txt --osymbols=$dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstaddselfloops  $dir/phones/wdisambig_phones.int $dir/phones/wdisambig_words.int | fstarcsort --sort_type=olabel > $dir/L_disambig.fst 

utils/format_lm.sh data/lang data/local/lm/2gram.lm.gz data/dict/lexicon.txt data/lang/test
mv data/lang/test/G.fst data/lang/G.fst

utils/mkgraph.sh --remove-oov --self-loop-scale 1.0 data/lang exp/nnet3/chain exp/ex3_word/graph

utils/build_const_arpa_lm.sh data/local/lm/3gram.lm.gz data/lang data/lang_test_3g
