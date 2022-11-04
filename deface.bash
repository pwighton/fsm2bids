#!/bin/bash

#BIDS_DIR_FACE=/autofs/vast/gerenuk/pwighton/fsm-bids/20221006-heudiconv
#BIDS_DIR_DEFACE=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip
#DERIVATIVES_DIR=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip/derivatives/mideface
#WORK_DIR=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip/work

# Both $BIDS_DIR_FACE and $WORK_DIR contain sensitive information that should not
# be shared.  
#  - $BIDS_DIR_FACE contains the original defaced images in BIDS format
#  - $WORK_DIR contains before/after pngs to QA the defacing process
BIDS_DIR_FACE=/home/paul/lcn/20220822-fsm-bids/hd-out-20220920
WORK_DIR=/home/paul/lcn/20221031-deface-wip/work

# Both these dirs should not contain sensitive information
BIDS_DIR_DEFACE=/home/paul/lcn/20221031-deface-wip/bids-top-level-dir
DERIVATIVES_DIR=/home/paul/lcn/20221031-deface-wip/bids-top-level-dir/derivatives/mideface

ORIG_DIR=`pwd`

mkdir -p $BIDS_DIR_DEFACE
mkdir -p $DERIVATIVES_DIR
mkdir -p $WORK_DIR

for SUB in sub-fsm99tc
do
  echo "Working on subject: " $SUB
  mkdir -p $DERIVATIVES_DIR/$SUB/anat
  mkdir -p $BIDS_DIR_DEFACE/$SUB/anat
  cd $DERIVATIVES_DIR/$SUB/anat
  
  ##### Deface gre3d #####
  ## Deface the first GRE echo, save the work dir and generate QA pics
  mkdir -p $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag
  cd $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag
  mideface \
    --i $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE.nii.gz \
    --odir $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag \
    --pics \
    --code ${SUB}
  ## Copy/convert face mask and defaced echo 1 image to the right spot
  mri_convert \
    $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag/face.mask.mgz \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz
  mri_convert \
    $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag/defaced.mgz \
    $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE.nii.gz
  ## Apply the facemask to deface mag echos 2-12
  for ECHO in 2 3 4 5 6 7 8 9 10 11 12
  do
    mideface \
      --apply \
      $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-mag_MEGRE.nii.gz \
      $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz \
      regheader \
      $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-mag_MEGRE.nii.gz \
      --nii.gz
  done
  ## Create an 'mul-facemask', that can be multipled with orig phase images to deaface
  fscalc \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz \
    not \
    --o $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask-mul.nii.gz
  ## Apply the facemask to deface all phase echos
  for ECHO in 1 2 3 4 5 6 7 8 9 10 11 12
  do
    # Mideface currently core dumps on phase images, copy for now
    #mideface \
    #  --apply \
    #  $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz \
    #  $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz \
    #  regheader \
    #  $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz \
    #  --nii.gz
    #
    # simply copy?
    #cp \
    #  $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz \
    #  $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz
    #
    # deface with AND mask and multiply operator
    fscalc $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz \
      mul $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask-mul.nii.gz \
      --o $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz
  done
  ## Apply the facemask to deface the t2star map
  mideface \
    --apply \
    $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_T2starmap.nii.gz \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz \
    regheader \
    $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_T2starmap.nii.gz

  ##### Deface mp2rage #####
  ## Deface the second inversion, save the work dir and generate QA pics
  mkdir -p $WORK_DIR/$SUB/acq-mp2rage_inv-2
  cd $WORK_DIR/$SUB/acq-mp2rage_inv-2
  mideface \
    --i $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mp2rage_inv-2_MP2RAGE.nii.gz \
    --odir $WORK_DIR/$SUB/acq-mp2rage_inv-2 \
    --pics \
    --code ${SUB}
  ## Copy/convert face mask and defaced second inversion image to the right spot
  mri_convert \
    $WORK_DIR/$SUB/acq-mp2rage_inv-2/face.mask.mgz \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mp2rage_inv-2_MP2RAGE_facemask.nii.gz
  mri_convert \
    $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag/defaced.mgz \
    $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mp2rage_inv-2_MP2RAGE.nii.gz
  ## Apply the facemask to the other mp2rage contrasts
  for MP2CONTRAST in inv-1_MP2RAGE T1map UNIT1
  do
    mideface \
      --apply \
      $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mp2rage_${MP2CONTRAST}.nii.gz \
      $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mp2rage_inv-2_MP2RAGE_facemask.nii.gz \
      regheader \
      $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mp2rage_${MP2CONTRAST}.nii.gz \
      --nii.gz
  done

  ##### Deface vNav mprage #####
  ## Deface the RMS image, save the work dir and generate QA pics
  mkdir -p $WORK_DIR/$SUB/acq-mprageVnav_T1wRMS
  cd $WORK_DIR/$SUB/acq-mprageVnav_T1wRMS
  mideface \
    --i $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS.nii.gz \
    --odir $WORK_DIR/$SUB/acq-mprageVnav_T1wRMS \
    --pics \
    --code ${SUB}
  ## Copy/convert face mask and defaced echo 1 image to the right spot
  mri_convert \
    $WORK_DIR/$SUB/acq-mprageVnav_T1wRMS/face.mask.mgz \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS_facemask.nii.gz
  mri_convert \
    $WORK_DIR/$SUB/acq-mprageVnav_T1wRMS/defaced.mgz \
    $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS.nii.gz
  ## Apply the facemask to the other vNav MPRAGE contrasts
  for T1WCONTRAST in echo-1_part-mag echo-2_part-mag echo-3_part-mag echo-4_part-mag
  do
    mideface \
      --apply \
      $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz \
      $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS_facemask.nii.gz \
      regheader \
      $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz \
      --nii.gz
  done  
  ## Create an 'mul-facemask', that can be multipled with orig phase images to deaface
  fscalc \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS_facemask.nii.gz \
    not \
    --o $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS_facemask-mul.nii.gz
  ## Apply the mul-facemask to deface all phase echos
  for T1WCONTRAST in echo-1_part-phase echo-2_part-phase echo-3_part-phase echo-4_part-phase
  do
    # Mideface currently core dumps on phase images
    #mideface \
    #  --apply \
    #  $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz \
    #  $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS_facemask.nii.gz \
    #  regheader \
    #  $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz \
    #  --nii.gz
    # Don't deface phase, simply copy?
    #cp \
    #  $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz \
    #  $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz
    # Deface with mul op
    fscalc $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz \
      mul $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS_facemask-mul.nii.gz \
      --o $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz
  done 
  
  ##### Deface t2 flair #####
  mkdir -p $WORK_DIR/$SUB/acq-t2flair
  cd $WORK_DIR/$SUB/acq-t2flair
  mideface \
    --i $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-t2flair_T2w.nii.gz \
    --odir $WORK_DIR/$SUB/acq-t2flair \
    --pics \
    --code ${SUB}
  ## Copy/convert face mask and defaced echo 1 image to the right spot
  mri_convert \
    $WORK_DIR/$SUB/acq-t2flair/face.mask.mgz \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-t2flair_T2w_facemask.nii.gz
  mri_convert \
    $WORK_DIR/$SUB/acq-t2flair/defaced.mgz \
    $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-t2flair_T2w.nii.gz
    
  ##### Deface vNav t2 space #####
  mkdir -p $WORK_DIR/$SUB/acq-t2spaceVnav
  cd $WORK_DIR/$SUB/acq-t2spaceVnav
  mideface \
    --i $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-t2spaceVnav_T2w.nii.gz \
    --odir $WORK_DIR/$SUB/acq-t2spaceVnav \
    --pics \
    --code ${SUB}
  ## Copy/convert face mask and defaced echo 1 image to the right spot
  mri_convert \
    $WORK_DIR/$SUB/acq-t2spaceVnav/face.mask.mgz \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-t2spaceVnav_T2w_facemask.nii.gz
  mri_convert \
    $WORK_DIR/$SUB/acq-t2spaceVnav/defaced.mgz \
    $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-t2spaceVnav_T2w.nii.gz

  ## Copy over the jsons to go with the defaced nifits we just made
  cp $BIDS_DIR_FACE/$SUB/anat/*.json $BIDS_DIR_DEFACE/$SUB/anat/

  ## Copy over the dirs we are not defacing
  cp -R $BIDS_DIR_FACE/$SUB/dwi   $BIDS_DIR_DEFACE/$SUB/dwi
  cp -R $BIDS_DIR_FACE/$SUB/fmap  $BIDS_DIR_DEFACE/$SUB/fmap
  cp -R $BIDS_DIR_FACE/$SUB/func  $BIDS_DIR_DEFACE/$SUB/func

  ## Copy over top-level files
  cp $BIDS_DIR_FACE/$SUB/${SUB}* $BIDS_DIR_DEFACE/$SUB/
done

cd $ORIG_DIR
