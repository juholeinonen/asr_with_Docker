#!/bin/bash

bin_folder=asr_with_Docker/bin
python3 $bin_folder/make_wav_and_utt2spk.py
utils/utt2spk_to_spk2utt.pl data/eval/utt2spk > data/eval/spk2utt

utils/copy_data_dir.sh data/eval data/eval_hires

nj=1

steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf --cmd "run.pl" data/align_hires
steps/compute_cmvn_stats.sh data/align_hires

utils/fix_data_dir.sh data/align_hires

steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj $nj data/align_hires exp/nnet3/extractor exp/nnet3/ivectors_align_hires

#TODO rescore
