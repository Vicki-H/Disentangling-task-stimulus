function [subcode] = firstlevel_glm_VH3(ids,smoothkernel)

%ids='001';
%smoothkernel=8;

addpath('/group/mlr-lab/AH/Projects/spm12')
root = '/Group/MLR-Lab/VHodgson/AH/derivatives'; %removed square brackets

cd(root);%removed square brackets

subcode{1} = [ids];

sm=smoothkernel;
trs=1.792;
slices=46;

%% run 1st level analysis for all subjects

cond={'lateral'};
nslices=slices;

for s=1:size(subcode,2)
    
%     %select run order per participant, using s (for the loop)
%     if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
%         run_order={'SC','NVC','Sn','NVn'};
%     elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
%         run_order={'NVC','Sn','NVn','SC'};
%     elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
%         run_order={'Sn','NVn','SC','NVC'};
%     elseif ismember(str2num(ids),[9 16 24 27 39 40]);
%         run_order={'NVn','SC','NVC','Sn'};
%     end
    
    cd(root)
    
    if exist([root,'/fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_run-1_design.mat'])
    disp([root,'/fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_run-1_design.mat','*****FILE FOUND - PROCESSING*****'])
    % this if statement is cut short at the end if there's no design.mat file
        
    outdir=([root,'/GLM/first/sub-',subcode{s},'/',num2str(sm),'sm_lateral/']);
    datadir=([root,'/SPM/sub-',subcode{s}]);
%     mkdir(outdir);
%     mkdir(datadir);
%     delete([outdir,'SPM.mat']);
%     
%     %if smoothed file is missing, create files - in case you want re-smooth data this also includes prefix for smoothing
%     if isempty(dir([datadir,'/',num2str(sm),'*task-lateral*t2star*.nii']))
%         
    %load confounds file and extract 6 motion parameters
    %can be modified to include other/more confounds
    for i=1:length(dir([root,'/fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_*_desc-confounds_timeseries.tsv']))
    x=spm_load([root,'/fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_run-',num2str(i),'_desc-confounds_timeseries.tsv']);
    R=[x.rot_x,x.rot_y,x.rot_z,x.trans_x,x.trans_y,x.trans_z];
    save([datadir,'/motion_lateral_run-',num2str(i),'.mat'],'R');     
    end
%      
%     %unzip func file to be used in SPM, and save in the subject specific datadir
%     %note: has already been done manually
%     gunzip(['./fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_rec-t2star_*_bold.nii.gz'],[datadir,'/']);
%         
%     %smooth data and delete unsmoothed
%     %has already been done manually
%     clear matlabbatch
%     matlabbatch{1}.spm.spatial.smooth.data = cellstr(spm_select('ExtFPList',[datadir],'/^*lateral.*\.nii$',1:450));
%     matlabbatch{1}.spm.spatial.smooth.fwhm = [sm sm sm]; %use smoothing kernel pre-specified
%     matlabbatch{1}.spm.spatial.smooth.dtype = 0;
%     matlabbatch{1}.spm.spatial.smooth.im = 0;
%     matlabbatch{1}.spm.spatial.smooth.prefix = ['s',num2str(sm)];
%     spm_jobman('run',matlabbatch);
%     delete([datadir,'/sub-*_bold.nii']);
%     end
    
%     for i=1:4
%         gunzip(['./fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_run-',num2str(i),'_space-MNI152NLin2009cAsym_res-2_desc-brain_mask.nii.gz']);
%     end

    %build GLM
    clear matlabbatch
    matlabbatch{1}.spm.stats.fmri_spec.dir = {['/GLM/first/sub-',subcode{s},'/',num2str(sm),'sm_lateral/']}; %this line tells SPM where to put the SPM.mat file
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = trs; %TR variable set above
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = slices; %slices variable set above
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = slices/2;
    
    for i=1:4 %4 runs
    %smoothed_scans=['s8sub-',subcode{s},'_task-lateral_rec-t2star_run-',num2str(i),'*'];
    scan_dir=['\\cbsu\data\Group\MLR-Lab\VHodgson\AH\derivatives\SPM\sub-',subcode{s}];
    filename=['s8sub-',subcode{s},'_task-lateral_rec-t2star_run-',num2str(i),'_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.nii'];
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).scans = cellstr(spm_select('ExtFPList',scan_dir,filename,[1:450])); %load smoothed data
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi_reg = {[scan_dir,'/motion_lateral_run-',num2str(i),'.mat']}; %extracted from confounds file
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).multi = {['fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_run-',num2str(i),'_design.mat']}; % design matrix
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).hpf = 128; %default
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(i).regress = struct('name', {}, 'val', {});
    end
    
    %gunzip([root,'/fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_run-',num2str(i),'_space-MNI152NLin2009cAsym_res-2_desc-brain_mask.nii.gz'],[datadir,'/'])
    matlabbatch{1}.spm.stats.fmri_spec.mask = {['/fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_run-',num2str(i),'_space-MNI152NLin2009cAsym_res-2_desc-brain_mask.nii']}; %brain mask, same as template used by fMRIprep
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0;    
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST'; %used based on Jamie's original analyses, evidence from Guy Williams group that is better than AR(1)
    %model estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    spm_jobman('run',matlabbatch);
             
    %set contrasts for each experiment
    %tmp={[root,'/GLM/first/sub-',subcode{s},'/',num2str(sm),'sm_lateral/'],[root,'/GLM/first/sub-',subcode{s},'/',num2str(sm),'sm_lateral_dn/']};
    clear matlabbatch
    matlabbatch{1}.spm.stats.con.spmmat = {['/GLM/first/sub-',subcode{s},'/',num2str(sm),'sm_lateral/SPM.mat']};
    matlabbatch{1}.spm.stats.con.delete = 1;
    
    % hard>easy for each condition - main planned first level contrasts
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = ['SCHard-SCEasy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 -1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 0 0 0 0 0 0 0 1 -1];
    end
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = ['NVCHard-NVCEasy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [1 -1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    end
    matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = ['SnHard-SnEasy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [1 -1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    end
    matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{4}.tcon.name = ['NVnHard-NVnEasy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 0 0 0 0 0 1 -1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = [1 -1];
    end
    matlabbatch{1}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
    
    % hard/easy contrasts across all conditions
    matlabbatch{1}.spm.stats.con.consess{5}.tcon.name = 'Hard>Easy';
    matlabbatch{1}.spm.stats.con.consess{5}.tcon.weights = [0.25 -0.25];
    matlabbatch{1}.spm.stats.con.consess{5}.tcon.sessrep = 'repl';
    matlabbatch{1}.spm.stats.con.consess{6}.tcon.name = 'Hard+Easy>Rest';
    matlabbatch{1}.spm.stats.con.consess{6}.tcon.weights = [0.125 0.125];
    matlabbatch{1}.spm.stats.con.consess{6}.tcon.sessrep = 'repl';
    matlabbatch{1}.spm.stats.con.consess{7}.tcon.name = ['Hard>Rest'];
    matlabbatch{1}.spm.stats.con.consess{7}.tcon.weights = [1];
    matlabbatch{1}.spm.stats.con.consess{7}.tcon.sessrep = 'repl';
    matlabbatch{1}.spm.stats.con.consess{8}.tcon.name = ['Easy>Rest'];
    matlabbatch{1}.spm.stats.con.consess{8}.tcon.weights = [0 1];
    matlabbatch{1}.spm.stats.con.consess{8}.tcon.sessrep = 'repl'; 
    
    % hard+easy>rest for each of the 4 conditions
    matlabbatch{1}.spm.stats.con.consess{9}.tcon.name = ['SCHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{9}.tcon.weights = [0.5 0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{9}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{9}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{9}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{9}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{10}.tcon.name = ['NVCHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{10}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{10}.tcon.weights = [0.5 0.5];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{10}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{10}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{10}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{11}.tcon.name = ['SnHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{11}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{11}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{11}.tcon.weights = [0.5 0.5];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{11}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{11}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{12}.tcon.name = ['NVnHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{12}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{12}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{12}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 0.5];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{12}.tcon.weights = [0.5 0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{12}.tcon.sessrep = 'none';
    
    % easy>rest for each of the 4 conditions
    matlabbatch{1}.spm.stats.con.consess{13}.tcon.name = ['SCEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{13}.tcon.weights = [0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{13}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{13}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{13}.tcon.weights = [0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{13}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{14}.tcon.name = ['NVCEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{14}.tcon.weights = [0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{14}.tcon.weights = [0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{14}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{14}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{14}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{15}.tcon.name = ['SnEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{15}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{15}.tcon.weights = [0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{15}.tcon.weights = [0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{15}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{15}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{16}.tcon.name = ['NVnEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{16}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{16}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{16}.tcon.weights = [0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{16}.tcon.weights = [0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{16}.tcon.sessrep = 'none';
    
    % hard>rest for each of the 4 conditions
    matlabbatch{1}.spm.stats.con.consess{17}.tcon.name = ['SCHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{17}.tcon.weights = [1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{17}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{17}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{17}.tcon.weights = [0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{17}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{18}.tcon.name = ['NVCHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{18}.tcon.weights = [0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{18}.tcon.weights = [1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{18}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{18}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{18}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{19}.tcon.name = ['SnHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{19}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{19}.tcon.weights = [0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{19}.tcon.weights = [1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{19}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{19}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{20}.tcon.name = ['NVnHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{20}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{20}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{20}.tcon.weights = [0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{20}.tcon.weights = [1];
    end
    matlabbatch{1}.spm.stats.con.consess{20}.tcon.sessrep = 'none';
    
    % hard>easy for each stimulus and task
    matlabbatch{1}.spm.stats.con.consess{21}.tcon.name = ['SemanticHard>Easy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{21}.tcon.weights = [0.5 -0.5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{21}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 -0.5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{21}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{22}.tcon.name = ['NVHard>Easy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{22}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 -0.5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{22}.tcon.weights = [0.5 -0.5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{22}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{23}.tcon.name = ['CattellHard>Easy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{23}.tcon.weights = [0.5 -0.5 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{23}.tcon.weights = [0.5 -0.5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{23}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{23}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 -0.5 0 0 0 0 0 0 0.5 -0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{23}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{24}.tcon.name = ['nBackHard>Easy'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{24}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{24}.tcon.weights = [0 0 0 0 0 0 0 0 0.5 -0.5 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{24}.tcon.weights = [0.5 -0.5 0 0 0 0 0 0 0.5 -0.5];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{24}.tcon.weights = [0.5 -0.5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.5 -0.5];
    end
    matlabbatch{1}.spm.stats.con.consess{24}.tcon.sessrep = 'none';
    
    % hard>rest for each stimulus and task
    matlabbatch{1}.spm.stats.con.consess{25}.tcon.name = ['SemanticHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{25}.tcon.weights = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{25}.tcon.weights = [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
    end
    matlabbatch{1}.spm.stats.con.consess{25}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{26}.tcon.name = ['NVHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{26}.tcon.weights = [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{26}.tcon.weights = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
    end
    matlabbatch{1}.spm.stats.con.consess{26}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{27}.tcon.name = ['CattellHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{27}.tcon.weights = [1 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{27}.tcon.weights = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{27}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{27}.tcon.weights = [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0];
    end
    matlabbatch{1}.spm.stats.con.consess{27}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{28}.tcon.name = ['nBackHard>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{28}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{28}.tcon.weights = [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{28}.tcon.weights = [1 0 0 0 0 0 0 0 1 0];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{28}.tcon.weights = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
    end
    matlabbatch{1}.spm.stats.con.consess{28}.tcon.sessrep = 'none';
    
    % easy>rest for each stimulus and task
    matlabbatch{1}.spm.stats.con.consess{29}.tcon.name = ['SemanticEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{29}.tcon.weights = [0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{29}.tcon.weights = [0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{29}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{30}.tcon.name = ['NVEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{30}.tcon.weights = [0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{30}.tcon.weights = [0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{30}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{31}.tcon.name = ['CattellEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{31}.tcon.weights = [0 1 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{31}.tcon.weights = [0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{31}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{31}.tcon.weights = [0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{31}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{32}.tcon.name = ['nBackEasy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{32}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{32}.tcon.weights = [0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{32}.tcon.weights = [0 1 0 0 0 0 0 0 0 1];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{32}.tcon.weights = [0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    end
    matlabbatch{1}.spm.stats.con.consess{32}.tcon.sessrep = 'none';
    
    % hard+easy>rest for each stimulus and task
    matlabbatch{1}.spm.stats.con.consess{33}.tcon.name = ['SemanticHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{33}.tcon.weights = [0.25 0.25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{33}.tcon.weights = [0 0 0 0 0 0 0 0 0.25 0.25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25];
    end
    matlabbatch{1}.spm.stats.con.consess{33}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{34}.tcon.name = ['NVHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32 7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{34}.tcon.weights = [0 0 0 0 0 0 0 0 0.25 0.25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36 9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{34}.tcon.weights = [0.25 0.25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25];
    end
    matlabbatch{1}.spm.stats.con.consess{34}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{35}.tcon.name = ['CattellHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{35}.tcon.weights = [0.25 0.25 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{35}.tcon.weights = [0.25 0.25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{35}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{35}.tcon.weights = [0 0 0 0 0 0 0 0 0.25 0.25 0 0 0 0 0 0 0.25 0.25];
    end
    matlabbatch{1}.spm.stats.con.consess{35}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.consess{36}.tcon.name = ['nBackHard+Easy>Rest'];
    if ismember(str2num(ids),[1 2 3 10 11 18 25 29 31 32]);
        matlabbatch{1}.spm.stats.con.consess{36}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[4 5 13 19 20 30 33 35 36]);
        matlabbatch{1}.spm.stats.con.consess{36}.tcon.weights = [0 0 0 0 0 0 0 0 0.25 0.25 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[7 14 15 21 26 37 38]);
        matlabbatch{1}.spm.stats.con.consess{36}.tcon.weights = [0.25 0.25 0 0 0 0 0 0 0.25 0.25];
    elseif ismember(str2num(ids),[9 16 24 27 39 40]);
        matlabbatch{1}.spm.stats.con.consess{36}.tcon.weights = [0.25 0.25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0.25];
    end
    matlabbatch{1}.spm.stats.con.consess{36}.tcon.sessrep = 'none';  
    
    spm_jobman('run',matlabbatch);
              
    else
        disp([root,'/fmriprep/sub-',subcode{s},'/func/sub-',subcode{s},'_task-lateral_design.mat','*****FILE NOT FOUND SKIPPING*****'])
    end
    
end

end


