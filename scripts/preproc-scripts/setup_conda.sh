#!/bin/bash

cd ~/

conda create -n AHALAI python=3 pip mdp numpy scikit-learn scipy 
conda activate AHALAI
pip install nilearn nibabel
pip install tedana
pip install heudiconv[all]

