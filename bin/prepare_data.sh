#!/bin/bash

bin_folder=asr_with_Docker/bin
python3 $bin_folder/make_wav_and_utt2spk.py

utils/utt2spk_to_spk2utt.pl data/eval/utt2spk > data/eval/spk2utt

utils/copy_data_dir.sh data/eval data/eval_hires

nj=1

steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf --cmd "run.pl" data/eval_hires
steps/compute_cmvn_stats.sh data/eval_hires

utils/fix_data_dir.sh data/eval_hires

steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj $nj data/eval_hires exp/nnet3/extractor exp/nnet3/ivectors_eval_hires

steps/nnet3/decode.sh --extra-left-context 40 --extra-right-context 0 --frames-per-chunk 140 --beam 20 --lattice-beam 10.0 --min-active 12000 --max-active 21000 --skip-scoring false --nj $nj --post-decode-acwt 10.0 --acwt 1.0 --online-ivector-dir exp/nnet3/ivectors_eval_hires/ exp/ex3_word/graph data/eval_hires/ exp/nnet3/chain/decode_ex3_word

# steps/lmrescore.sh --self-loop-scale 1.0 data/lang data/lang_3g data/eval_hires exp/nnet3/chain/decode_ex3_word exp/nnet3/chain/rescored_normal_ex3_word
steps/lmrescore_const_arpa.sh data/lang data/lang_test_3g data/eval_hires exp/nnet3/chain/decode_ex3_word exp/nnet3/chain/rescored_ex3_word
