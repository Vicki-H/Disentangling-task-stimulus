#!/bin/bash
echo "
++++++++++++++++++++++++" 
echo +* "Set up script run environment" 
#adds appropriate tools and options - no need to change if you have access to /imaging/mlr_imaging as the tools are in my folder 'AH', which is accessable to all users
export PATH=$PATH:/group/mlr-lab/AH/Projects/toolboxes/afni/v18.3.03
export PATH=$PATH:/imaging/local/software/anaconda/latest/x86_64/bin/
export PATH=$PATH:/group/mlr-lab/AH/Projects/toolboxes/apps/bin
export PATH=/imaging/local/software/centos7/ants/bin/ants/bin/:$PATH
export PATH=/imaging/local/software/mrtrix/v3.0.3_v2/bin/:$PATH
export OMP_NUM_THREADS=16
export MKL_NUM_THREADS=16
export AFNI_3dDespike_NEW=YES
FSLDIR=/imaging/local/software/fsl/latest/x86_64/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH
export ANTSPATH=/imaging/local/software/centos7/ants/bin/ants/bin/
FSLOUTPUTTYPE=NIFTI_GZ

#conda enviroment includes tedana toolkit
conda activate AHALAI

dirp=/group/mlr-lab/VHodgson/AH
echo "$dirp"/data/sub-"$ids"

#run fmriprep singularity - no freesurfer reconall, framewise-displacement set to 0.3 to detect outlier volumes but can change post-hoc
singularity run --cleanenv -B /imaging/local/software/freesurfer/7.1.1/license.txt:/opt/freesurfer/license.txt -B $dirp:/base /imaging/local/software/singularity_images/fmriprep/fmriprep-20.2.1.simg /base/data /base/derivatives participant --participant-label sub-"$ids" -w /base/work --fs-no-reconall --fs-license-file /opt/freesurfer/license.txt --output-spaces MNI152NLin2009cAsym:res-2 --fd-spike-threshold 0.3 

#re-process the multi-echo data to include ICA denoising pipeline

#automatically detect fmriprep folders
folders=$(ls -d $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/func*)

for s in $folders; do
#detect if data had multi-echo fMRI (this folder is not present for single echo fMRI)
if [ -d "$s"/skullstrip_bold_wf ]; then
echo $s
echo "Found multi-echo, running multi-echo specific analysis"

#get all folders related to each echo from fmriprep outputs use bold_bold as skullstrip already had func masked applied, using T1 mask here instead
echoes=$(ls -d "$s"/bold_bold_trans_wf/_*)
x=0
unset e1
for e in $echoes; do
#echo $e
xx=`expr $x + 1`
x=$(printf "%01d" "$xx")
#re-save fMRIPrep outputs in tmp space
cp -rf $e/merge/vol0000_xform-00000_merged.nii.gz $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp"$x".nii.gz

#get echo time from orig json file
y=$(basename ${e#*func..} .nii.gz)
e1+=($(cat "$dirp"/data/sub-"$ids"/func/"$y".json | jq '.EchoTime'))

done
#get all folders related to each echo from fmriprep outputs use bold_bold as skullstrip already had func masked applied, using T1 mask here instead
echoes=$(ls -d "$s"/bold_bold_trans_wf/_*)
x=0
for e in $echoes; do
#echo $e
xx=`expr $x + 1`
x=$(printf "%01d" "$xx")
cp -rf $e/merge/vol0000_xform-00000_merged.nii.gz $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp"$x".nii.gz

#get echo time from orig json file
y=$(basename ${e#*func..} .nii.gz)
if [ $xx == 1 ]; then
e1=($(cat "$dirp"/data/sub-"$ids"/func/"$y".json | jq '.EchoTime'))
e1=$(echo "$e1*1000" | bc -l)
elif [ $xx == 2 ]; then 
e2=($(cat "$dirp"/data/sub-"$ids"/func/"$y".json | jq '.EchoTime'))
e2=$(echo "$e2*1000" | bc -l)
elif [ $xx == 3 ]; then 
e3=($(cat "$dirp"/data/sub-"$ids"/func/"$y".json | jq '.EchoTime'))
e3=$(echo "$e3*1000" | bc -l)
elif [ $xx == 4 ]; then 
e4=($(cat "$dirp"/data/sub-"$ids"/func/"$y".json | jq '.EchoTime'))
e4=$(echo "$e4*1000" | bc -l)
fi
done

#move T1 mask into mean native EPI space and match dimensions
fslmaths $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp"$x".nii.gz -Tmean $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp"$x"_mean

antsApplyTransforms --default-value 0 --float 1 --input "$dirp"/derivatives/fmriprep/sub-"$ids"/anat/sub-"$ids"_desc-brain_mask.nii.gz --interpolation NearestNeighbor --output $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/T1.nii.gz --reference-image $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp"$x"_mean.nii.gz --transform $s/bold_reg_wf/fsl_bbr_wf/fsl2itk_inv/affine.txt

#modify command for 3 or 4 echoes (not sure how to do this on the fly so seperated)
if [ $x == 3 ]; then
tedana -d $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp1.nii.gz $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp2.nii.gz $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp3.nii.gz -e $e1 $e2 $e3 --fittype curvefit --n-threads 16 --maxit 500 --maxrestart 50 --mask $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/T1.nii.gz --out-dir "$s"/tedana/
elif [ $x == 4 ]; then
tedana -d $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp1.nii.gz $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp2.nii.gz $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp3.nii.gz $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/tmp4.nii.gz -e $e1 $e2 $e3 $e4 --fittype curvefit --n-threads 16 --maxit 500 --maxrestart 50 --mask $dirp/work/fmriprep_wf/single_subject_"$ids"_wf/T1.nii.gz --out-dir "$s"/tedana/
fi

#identify filename and run automatically (dirty version)
yy=${y#*"$ids"_}
cond=${yy%_run*}
yy=${y#*_run-0}	
r=${yy%_echo*}
echo sub-"$ids"_"$cond"_"$r"

#apply bbr and MNI warps in one concat step
antsApplyTransforms -d 3 -e 3 -i "$s"/tedana/desc-optcomDenoised_bold.nii.gz -r $dirp/derivatives/fmriprep/sub-"$ids"/anat/sub-"$ids"_*space-MNI152NLin2009cAsym_*_T1w.nii.gz -o "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_rec-tedana_run-"$r"_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.nii.gz --default-value 0 --float 1 -n LanczosWindowedSinc --transform "$dirp"/derivatives/fmriprep/sub-"$ids"/anat/sub-"$ids"_*from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 --transform $s/bold_reg_wf/fsl_bbr_wf/fsl2itk_fwd/affine.txt --transform identity --transform identity

antsApplyTransforms -d 3 -e 3 -i "$s"/tedana/desc-optcom_bold.nii.gz -r $dirp/derivatives/fmriprep/sub-"$ids"/anat/sub-"$ids"_*space-MNI152NLin2009cAsym_*_T1w.nii.gz -o "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_rec-t2star_run-"$r"_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.nii.gz --default-value 0 --float 1 -n LanczosWindowedSinc --transform "$dirp"/derivatives/fmriprep/sub-"$ids"/anat/sub-"$ids"_*from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 --transform $s/bold_reg_wf/fsl_bbr_wf/fsl2itk_fwd/affine.txt --transform identity --transform identity

#apply to t2star map
antsApplyTransforms -d 3 -i "$s"/tedana/T2starmap.nii.gz -r $dirp/derivatives/fmriprep/sub-"$ids"/anat/sub-"$ids"_*space-MNI152NLin2009cAsym_res-2_desc-preproc_T1w.nii.gz -o "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_space-MNI152NLin2009cAsym_res-2_desc-t2star_roi.nii.gz --default-value 0 --float 1 -n LanczosWindowedSinc --transform "$dirp"/derivatives/fmriprep/sub-"$ids"/anat/sub-"$ids"_*from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 --transform $s/bold_reg_wf/fsl_bbr_wf/fsl2itk_fwd/affine.txt --transform identity --transform identity

#move files to final output folders and rename
#move flirt bbr reg in case native EPI outputs need to be moved to T1 (or MNI space)
cp -rf $s/bold_reg_wf/fsl_bbr_wf/fsl2itk_fwd/affine.txt "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_run-1_from-bold_to-T1w_mode-affine_xfm.txt
#copy old json file and rename
cp "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"*bold.json "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_rec-tedana_run-"$r"_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.json
cp "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"*bold.json "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_rec-t2star_run-"$r"_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.json
#create space to store multi-echo preprocessing and report files
mkdir -p "$dirp"/derivatives/fmriprep/sub-"$ids"/func/ME_report/"$cond"_"$r"/
mv "$s"/tedana/* "$dirp"/derivatives/fmriprep/sub-"$ids"/func/ME_report/"$cond"_"$r"/

#remove fmriprep (old) multi-echo outputs
rm -rf "$dirp"/derivatives/fmriprep/sub-"$ids"/func/sub-"$ids"_"$cond"_run*bold*.nii.gz

#retain native preprocessed files
mkdir -p "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/ "$dirp"/derivatives/fmriprep_native/sub-"$ids"/anat/
cp -rf "$s"/bold_bold_trans_wf/*echo-1*/merge/vol0000_xform-00000_merged.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-1_space-EPI_desc-preproc_bold.nii.gz
cp -rf "$s"/bold_bold_trans_wf/*echo-2*/merge/vol0000_xform-00000_merged.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-2_space-EPI_desc-preproc_bold.nii.gz
cp -rf "$s"/bold_bold_trans_wf/*echo-3*/merge/vol0000_xform-00000_merged.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-3_space-EPI_desc-preproc_bold.nii.gz
cp -rf "$s"/bold_bold_trans_wf/*echo-4*/merge/vol0000_xform-00000_merged.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-4_space-EPI_desc-preproc_bold.nii.gz

cp -rf "$s"/final_boldref_wf/enhance_and_skullstrip_bold_wf/combine_masks/ref_*mask*.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-1_space-EPI_desc-brain_mask.nii.gz
cp -rf "$s"/final_boldref_wf/enhance_and_skullstrip_bold_wf/combine_masks/ref_*mask*.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-2_space-EPI_desc-brain_mask.nii.gz
cp -rf "$s"/final_boldref_wf/enhance_and_skullstrip_bold_wf/combine_masks/ref_*mask*.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-3_space-EPI_desc-brain_mask.nii.gz
cp -rf "$s"/final_boldref_wf/enhance_and_skullstrip_bold_wf/combine_masks/ref_*mask*.nii.gz "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-4_space-EPI_desc-brain_mask.nii.gz

cp -rf "$dirp"/data/sub-"$ids"/func/sub-"$ids"_"$cond"_*0"$r"*echo-1_bold.json "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-1_space-EPI_desc-preproc_bold.json
cp -rf "$dirp"/data/sub-"$ids"/func/sub-"$ids"_"$cond"_*0"$r"*echo-2_bold.json "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-2_space-EPI_desc-preproc_bold.json
cp -rf "$dirp"/data/sub-"$ids"/func/sub-"$ids"_"$cond"_*0"$r"*echo-3_bold.json "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-3_space-EPI_desc-preproc_bold.json
cp -rf "$dirp"/data/sub-"$ids"/func/sub-"$ids"_"$cond"_*0"$r"*echo-4_bold.json "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-4_space-EPI_desc-preproc_bold.json

antsApplyTransforms --default-value 0 -d 3 --float 1 --input "$s"/t1w_brain/*T1w_corrected_xform_masked.nii.gz --interpolation Linear --output "$dirp"/derivatives/fmriprep_native/sub-"$ids"/anat/sub-"$ids"_run-"$r"_space-EPI_desc-preproc_T1w.nii.gz --reference-image "$dirp"/derivatives/fmriprep_native/sub-"$ids"/func/sub-"$ids"_"$cond"_run-"$r"_echo-1_space-EPI_desc-brain_mask.nii.gz --transform ["$s"/bold_reg_wf/fsl_bbr_wf/fsl2itk_fwd/affine.txt, 1]
cp -rf $s/bold_reg_wf/fsl_bbr_wf/fsl2itk_fwd/affine.txt "$dirp"/derivatives/fmriprep_native/sub-"$ids"/anat/sub-"$ids"_"$cond"_run-"$r"_from-bold_to-T1w_mode-affine_xfm.txt

else
echo "No multi-echo detected, skipping multi-echo specific analysis"

fi

#remove fmriprep work/temp files
#rm -rf $dirp/work/fmriprep_wf/single_subject_"$ids"_wf
done

