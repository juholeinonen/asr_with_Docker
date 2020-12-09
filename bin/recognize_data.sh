#!/bin/bash

if [ $# != 3 ]; then

  echo "You're doing this wrong"
  exit 1;
fi

bin_folder=asr_with_Docker/bin

data_done=$1
data_folder=$2
version_name=$3

nj=1

if [ "$data_done" = false ] ; then
  python3 $bin_folder/make_wav_and_utt2spk.py

  utils/utt2spk_to_spk2utt.pl data/"$data_folder"/utt2spk > data/"$data_folder"/spk2utt

  utils/copy_data_dir.sh data/"$data_folder" data/"$data_folder"_hires

  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf --cmd "run.pl" data/"$data_folder"_hires
  steps/compute_cmvn_stats.sh data/"$data_folder"_hires

  utils/fix_data_dir.sh data/"$data_folder"_hires

  steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj $nj data/"$data_folder"_hires exp/nnet3/extractor exp/nnet3/ivectors_"$data_folder"_hires
fi

steps/nnet3/decode.sh --extra-left-context 40 --extra-right-context 0 --frames-per-chunk 140 --beam 20 --lattice-beam 10.0 --min-active 12000 --max-active 21000 --skip-scoring false --nj $nj --post-decode-acwt 10.0 --acwt 1.0 --online-ivector-dir exp/nnet3/ivectors_"$data_folder"_hires/ exp/"$version_name"/graph data/"$data_folder"_hires/ exp/nnet3/chain/"$data_folder"_"$version_name"

steps/lmrescore.sh --self-loop-scale 1.0 data/"$version_name"_lang data/"$version_name"_larger_lm data/"$data_folder"_hires exp/nnet3/chain/"$data_folder"_"$version_name" exp/nnet3/chain/rescored_"$data_folder"_"$version_name"_larger_lm
steps/lmrescore_const_arpa.sh data/"$version_name"_lang data/"$version_name"_const_arpa data/"$data_folder"_hires exp/nnet3/chain/"$data_folder"_"$version_name" exp/nnet3/chain/rescored_"$data_folder"_"$version_name"_const_arpa
