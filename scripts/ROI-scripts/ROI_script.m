base=['\\cbsu\data\Group\MLR-Lab\VHodgson\AH\derivatives\GLM\first\sub-'];
addpath('\\cbsu\data\Group\MLR-Lab\VHodgson\spm12\toolbox\marsbar-0.45');

%subid={'001','002','003','004','005','007','009','010','011','012','013','014','015','016','017','018','019','020','021','024','025','026','027','029','030','031','032','033','035','036','037'};
subid={'001'};

roidir='\\cbsu\data\Group\MLR-Lab\VHodgson\AH\derivatives\ROI_spheres\MFG';
%firstdir=[base,'first\alladj3_blocks_3rdMay\']; %directory for spm file? diff by subid?

b=0; %do you want to extract betas? 1=yes, 0=no.
c=1; %do you want to extract contrasts? 1=yes, 0=no.

a=dir([roidir,'*.mat']);
roi_file=cell(length(a),1);
for n=1:length(a)
    roi_file{n,1}=a(n).name;
end

%OR
%roi_file = {'Schwartz_ATL_sphere_10--41_19_-30_roi.mat'};
                       
ncon=36; %number of contrasts for each subject/roi
nbeta=36; %number of betas for each subject/roi ?

%make matrix to contain contrast values - one row for each subject+ROI,
%one column for each beta/contrast

if c==1
    cons=cell(length(subid)*length(roi_file),ncon+2);
end

if b==1
    beta=cell(length(subid)*length(roi_file),nbeta+2);
end

%use the following if want to import contrast vectors from a dummy SPM, rather than
%using those already defined in the subject's SPM
%D1=mardo([base,'marsbar\dummy_spms\SPM.mat']);
%xCon1 = get_contrasts(D1);

crow=1; %keep track of correct row in contrast array - move down 1 row after each subject/ROI
brow=1; %keep track of correct row in beta array

for srun = 1:length(subid)
            
    spm_name = [base,subid{srun},'\8sm_lateral\SPM.mat'];

    %changing image files to have right directory - del if design got correct
    %images!!!
    %SPM.swd(1)='J';

    % Make marsbar design object
    load(spm_name);
    D = mardo(SPM);
    %changing image files to have right directory - del if design got correct
    %images!!!
    %D.swd(1)='J';

    % Get contrasts from original design
    xCon = get_contrasts(D);  

    for rrun = 1:length(roi_file)

        disp(sprintf(['\nSubject:',subid{srun}],'\n'));
        disp(sprintf(['\nROI: ',roi_file{rrun}],'\n'));

        % Make marsbar ROI object
        R = maroi([roidir,roi_file{rrun}]);

        % Fetch data into marsbar data object
        Y = get_marsy(R, D, 'mean');
        % Estimate design on ROI data
        E = estimate(D, Y);
        % Put contrasts from original design back into design object
        E = set_contrasts(E, xCon);

        %get stats and stuff for all contrasts into statistics structure
        if c==1
            marsS = compute_contrasts(E, 1:36); %adjust 2nd value according to which contrasts you want
            cons{crow,1}=subid{srun}; %write subject ID
            cons{crow,2}=roi_file{rrun}(1:end-8); %write ROI name (stripping end bits from filename)
            for n=1:ncon;
            cons{crow,n+2}=marsS.con(n);
            end
            crow=crow+1;
        end

        if b==1
            bs = betas(E); % get design betas
            beta{brow,1}=subid{srun};%write subject ID
            beta{brow,2}=roi_file{rrun}(1:end-8); %write ROI name (stripping end bits from filename)
            m=1;
            for n=1:36 %specify which betas you want here ??
                beta{brow,m+2}=bs(n);
                m=m+1;
            end
            brow=brow+1;
        end

    end

    save('\\cbsu\data\Group\MLR-Lab\VHodgson\AH\derivatives\ROIanalysis\temp',subid{srun},'.mat');

end
