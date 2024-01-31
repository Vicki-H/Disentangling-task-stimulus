import os
def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes
def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where
    allowed template fields - follow python string module:
    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """
    
    t1w = create_key('sub-{subject}/anat/sub-{subject}_T1w')
    func_task01 = create_key('sub-{subject}/func/sub-{subject}_task-lateral_run-01_bold')
    func_task02 = create_key('sub-{subject}/func/sub-{subject}_task-lateral_run-02_bold')
    func_task03 = create_key('sub-{subject}/func/sub-{subject}_task-lateral_run-03_bold')
    func_task04 = create_key('sub-{subject}/func/sub-{subject}_task-lateral_run-04_bold')

    info = {t1w: [], func_task01: [], func_task02: [], func_task03: [], func_task04: []}
    
    for idx, s in enumerate(seqinfo):
       if (s.dim1 == 256) and (s.dim2 == 256) and ('CBU_MPRAGE_32chn' in s.protocol_name):
            info[t1w].append(s.series_id)
       if (s.dim1 == 80) and (s.dim2 == 80) and ('CBU_mbep2d_bold_3mm_MEPI4_MB2_run1' in s.protocol_name):
            info[func_task01].append(s.series_id)
       if (s.dim1 == 80) and (s.dim2 == 80) and ('CBU_mbep2d_bold_3mm_MEPI4_MB2_run2' in s.protocol_name):
            info[func_task02].append(s.series_id)
       if (s.dim1 == 80) and (s.dim2 == 80) and ('CBU_mbep2d_bold_3mm_MEPI4_MB2_run3' in s.protocol_name):
            info[func_task03].append(s.series_id)
       if (s.dim1 == 80) and (s.dim2 == 80) and ('CBU_mbep2d_bold_3mm_MEPI4_MB2_run4' in s.protocol_name):
            info[func_task04].append(s.series_id)

    return info
