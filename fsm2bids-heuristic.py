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

    # TODO:  
    #  - What to do about:
    #    - BIAS_BC
    #    - BIAS_32ch
    #    - tfl_DBS
    #  - Verify that the two gre fmap magnitude series are in the right order
    
    # See https://github.com/nipy/heudiconv/blob/master/heudiconv/heuristics/bids_ME.py
    megre_mag = create_key('sub-{subject}/anat/sub-{subject}_acq-gre3d_part-mag_MEGRE')
    megre_phase = create_key('sub-{subject}/anat/sub-{subject}_acq-gre3d_part-phase_MEGRE')
    megre_t2starmap = create_key('sub-{subject}/anat/sub-{subject}_acq-gre3d_T2starmap')
    
    t1w_mprage_vnav_mag = create_key('sub-{subject}/anat/sub-{subject}_acq-mprageVnav_part-mag_T1w')
    t1w_mprage_vnav_phase = create_key('sub-{subject}/anat/sub-{subject}_acq-mprageVnav_part-phase_T1w')
    t1w_mprage_vnav_rms = create_key('sub-{subject}/anat/sub-{subject}_acq-mprageVnav_T1wRMS')

    t1w_mp2rage_inv1 = create_key('sub-{subject}/anat/sub-{subject}_acq-mp2rage_inv-1_MP2RAGE')
    t1w_mp2rage_inv2 = create_key('sub-{subject}/anat/sub-{subject}_acq-mp2rage_inv-2_MP2RAGE')
    t1w_mp2rage_t1map = create_key('sub-{subject}/anat/sub-{subject}_acq-mp2rage_T1map')
    t1w_mp2rage_uni = create_key('sub-{subject}/anat/sub-{subject}_acq-mp2rage_UNIT1')
    
    t2w_space_vnav = create_key('sub-{subject}/anat/sub-{subject}_acq-t2spaceVnav_T2w')
    t2w_flair = create_key('sub-{subject}/anat/sub-{subject}_acq-t2flair_T2w')
    
    dwi = create_key('sub-{subject}/dwi/sub-{subject}_dwi')
    dwi_sbref = create_key('sub-{subject}/dwi/sub-{subject}_sbref')

    rest = create_key('sub-{subject}/func/sub-{subject}_task-rest_bold')
    rest_sbref = create_key('sub-{subject}/func/sub-{subject}_task-rest_sbref')

    # See:
    #  - https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/01-magnetic-resonance-imaging-data.html#types-of-fieldmaps
    #  - https://github.com/nipy/heudiconv/blob/e284072365e250d95de3f7ccc8e168298a403828/heudiconv/heuristics/banda-bids.py#L31
    fmap_se = create_key('sub-{subject}/fmap/sub-{subject}_acq-se_dir-{dir}_epi')
    
    # todo: verify that the two gre fmap magnitude series are in the right order
    fmap_gre_mag1 = create_key('sub-{subject}/fmap/sub-{subject}_acq-gre_magnitude')
    fmap_gre_phasediff = create_key('sub-{subject}/fmap/sub-{subject}_acq-gre_phasediff')
    
    info = {
             megre_mag:             [],
             megre_phase:           [],
             megre_t2starmap:       [],
             t1w_mprage_vnav_mag:   [],
             t1w_mprage_vnav_phase: [],
             t1w_mprage_vnav_rms:   [],
             t1w_mp2rage_inv1:      [],
             t1w_mp2rage_inv2:      [],
             t1w_mp2rage_t1map:     [],
             t1w_mp2rage_uni:       [],
             t2w_space_vnav:        [],
             t2w_flair:             [],
             dwi:                   [],
             dwi_sbref:             [],
             rest:                  [],
             rest_sbref:            [],
             fmap_se:               [],
             fmap_gre_mag1:         [],
             fmap_gre_phasediff:    []
           }

    for s in seqinfo:
        """
        The namedtuple `s` contains the following fields:

        * total_files_till_now
        * example_dcm_file
        * series_id
        * dcm_dir_name
        * unspecified2
        * unspecified3
        * dim1
        * dim2
        * dim3
        * dim4
        * TR
        * TE
        * protocol_name
        * is_motion_corrected
        * is_derived
        * patient_id
        * study_description
        * referring_physician_name
        * series_description
        * image_type
        """

        # This seems to work; commenting out for now
        
        if 'gre3D' in s.series_description:
          if (s.image_type[2] == 'M'):
            # This tests for 'NORM' in imagetype without crashing if len isn't 5
            if (len(s.image_type)==5):
              info[megre_mag].append(s.series_id)
          elif s.image_type[2] == 'P':
            info[megre_phase].append(s.series_id)
        if 'T2Star_Images' in s.series_description and 'gre3D' in s.protocol_name:
          info[megre_t2starmap].append(s.series_id)

        if 'T1w_MPR_vNav' in s.series_description:
          if (s.image_type[2] == 'M'):
            # This tests for 'NORM' in imagetype without crashing if len isn't 5
            if (len(s.image_type)==5):
              info[t1w_mprage_vnav_mag].append(s.series_id)
          elif s.image_type[2] == 'P':
            info[t1w_mprage_vnav_phase].append(s.series_id)
        
        if 'T1w_MPR_vNav' in s.series_description and 'RMS' in s.series_description:
          # This tests for 'NORM' in imagetype without crashing if len isn't 6
          if (len(s.image_type)==6):
            info[t1w_mprage_vnav_rms].append(s.series_id)

        if 't1_mp2rage' in s.series_description:
          if 'INV1' in s.series_description:
            # This tests for 'NORM' in imagetype without crashing if len isn't 5
            if (len(s.image_type)==5):
              # Subject-specific heuristics if there are multiple runs
              # Maybe we can edit and use `.heudiconv/fsm042/info/fsm042.edit.txt` instead? 
              # -----------
              #if '042' in s.dcm_dir_name:
              #  if not '64' in s.series_id:
              #    info[t1w_mp2rage_inv1].append(s.series_id)
              #else:
              #  info[t1w_mp2rage_inv1].append(s.series_id)
              # -----------
              info[t1w_mp2rage_inv1].append(s.series_id)
          if 'INV2' in s.series_description:
            # This tests for 'NORM' in imagetype without crashing if len isn't 5
            if (len(s.image_type)==5):
              info[t1w_mp2rage_inv2].append(s.series_id)
          if 'T1_Images' in s.series_description:
              info[t1w_mp2rage_t1map].append(s.series_id)
          if 'UNI_Images' in s.series_description:
              info[t1w_mp2rage_uni].append(s.series_id)
        
        if 'T2w_SPC_vNav' in s.series_description:
          # This tests for 'NORM' in imagetype without crashing if len isn't 5
          if (len(s.image_type)==5):
            info[t2w_space_vnav].append(s.series_id)

        if 'dMRI_dir98_AP' in s.series_description:
          if 'SBRef' in s.series_description:
            info[dwi_sbref].append(s.series_id)
          else:
            info[dwi].append(s.series_id)

        if 'rfMRI_REST' in s.series_description:
          if 'SBRef' in s.series_description:
            info[rest_sbref].append(s.series_id)
          else:
            info[rest].append(s.series_id)

        if 't2_flair' in s.series_description:
          # This tests for 'NORM' in imagetype without crashing if len isn't 5
          if (len(s.image_type)==5):
            info[t2w_flair].append(s.series_id)

        if 'gre_field_mapping' in s.series_description:
          if s.image_type[2] == 'M':
            info[fmap_gre_mag1].append(s.series_id)
          elif s.image_type[2] == 'P':
            info[fmap_gre_phasediff].append(s.series_id)

        if 'SpinEchoFieldMap' in s.series_description:
          if 'AP' in s.series_description:
            info[fmap_se].append({'item': s.series_id, 'dir': 'AP'})
          elif 'PA' in s.series_description:
            info[fmap_se].append({'item': s.series_id, 'dir': 'PA'})

    return info
