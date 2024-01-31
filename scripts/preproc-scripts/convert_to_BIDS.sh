#!/bin/bash
#this locates dcm2niix
export PATH=$PATH:/group/mlr-lab/AH/Projects/AHalai

#conda environment with heudiconv pip installed
conda activate AHALAI

dirp=/group/mlr-lab/VHodgson/AH/
#heudiconv -d $PWD/Dicom/sub-{subject}/*/*/*/*.dcm -o $PWD/Nifti/ -f convertall -s $1 -c none -b --overwrite
cd $dirp
mrdir=/mridata/cbu

x=039;

#rm -rf $dirp/data/

for s in CBU220429_MR21011; do

#increase subj number by 1 using three digits (001, 002, etc)
y=`expr $x + 1`
x=$(printf "%03d" "$y")

#tmp copy files to newly named BIDS compliant folder
mkdir -p ./sub-"$x"/
cp -rf $mrdir/"$s" ./sub-"$x"/

#run converter to output BIDS compliant files
heudiconv -d $dirp/sub-{subject}/*/*/*/*.dcm -o $dirp/data/ -f $dirp/scripts/heuristics_main.py -s "$x" -c dcm2niix -b --overwrite

#remove tmp DICOM copies
rm -rf ./sub-"$x"/
done

