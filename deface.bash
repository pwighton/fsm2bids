#!/bin/bash

START_TIME=`date`

#BIDS_DIR_FACE=/autofs/vast/gerenuk/pwighton/fsm-bids/20221006-heudiconv
#BIDS_DIR_DEFACE=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip
#DERIVATIVES_DIR=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip/derivatives/mideface
#WORK_DIR=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip/work

# Both $BIDS_DIR_FACE and $WORK_DIR contain sensitive information that should not
# be shared.  
#  - $BIDS_DIR_FACE contains the original defaced images in BIDS format
#  - $WORK_DIR contains before/after pngs to QA the defacing process
BIDS_DIR_FACE=/home/paul/lcn/20221104-fsm-bids-face
WORK_DIR=/home/paul/lcn/20221105-fsm-bids-deface/work

# Both these dirs should not contain sensitive information
BIDS_DIR_DEFACE=/home/paul/lcn/20221105-fsm-bids-deface/bids
DERIVATIVES_DIR=${BIDS_DIR_DEFACE}/derivatives/mideface

# Use the obfuscated subject list
SUBJECT_LIST=/home/paul/lcn/git/fsm2bids/subjects-obfuscated.txt

ORIG_DIR=`pwd`

mkdir -p $BIDS_DIR_DEFACE
mkdir -p $DERIVATIVES_DIR
mkdir -p $WORK_DIR

SUB=$1
#for SUB in `cat ${SUBJECT_LIST}`
#do
  echo "Working on subject: " $SUB
  mkdir -p $DERIVATIVES_DIR/$SUB/anat
  mkdir -p $BIDS_DIR_DEFACE/$SUB/anat
  cd $DERIVATIVES_DIR/$SUB/anat
  
  ##### Deface gre3d #####
  ## Deface the first GRE echo, save the work dir and generate QA pics
  if test -f "$BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE.nii.gz"; then
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
    ## Apply the facemask to deface the t2star map
    mideface \
      --apply \
      $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_T2starmap.nii.gz \
      $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz \
      regheader \
      $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_T2starmap.nii.gz
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
      --o $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask-mul.nii.gz
    ## Apply the mul-facemask to deface all phase echos
    for ECHO in 1 2 3 4 5 6 7 8 9 10 11 12
    do
      # deface with multiply operator
      fscalc $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz \
        mul $WORK_DIR/$SUB/acq-gre3d_echo-1_part-mag/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask-mul.nii.gz \
        --o $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-${ECHO}_part-phase_MEGRE.nii.gz
    done
  fi
  
  ##### Deface mp2rage #####
  ## Deface the second inversion, save the work dir and generate QA pics
  if test -f "$BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mp2rage_inv-2_MP2RAGE.nii.gz"; then
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
      $WORK_DIR/$SUB/acq-mp2rage_inv-2/defaced.mgz \
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
  fi

  ##### Deface vNav mprage #####
  ## Deface the RMS image, save the work dir and generate QA pics
  if test -f "$BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mprageVnav_T1wRMS.nii.gz"; then
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
      --o $WORK_DIR/$SUB/acq-mprageVnav_T1wRMS/${SUB}_acq-mprageVnav_T1wRMS_facemask-mul.nii.gz
    ## Apply the mul-facemask to deface all phase echos
    for T1WCONTRAST in echo-1_part-phase echo-2_part-phase echo-3_part-phase echo-4_part-phase
    do
      # Deface with mul op
      fscalc $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz \
        mul $WORK_DIR/$SUB/acq-mprageVnav_T1wRMS/${SUB}_acq-mprageVnav_T1wRMS_facemask-mul.nii.gz \
        --o $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-mprageVnav_${T1WCONTRAST}_T1w.nii.gz
    done 
  fi

  ##### Deface t2 flair #####
  if test -f "$BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-t2flair_T2w.nii.gz"; then
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
  fi

  ##### Deface vNav t2 space #####
  if test -f "$BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-t2spaceVnav_T2w.nii.gz"; then
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
  fi
  
  ## Copy over the jsons to go with the defaced nifits we just made
  cp $BIDS_DIR_FACE/$SUB/anat/*.json $BIDS_DIR_DEFACE/$SUB/anat/

  ## Copy over the dirs we are not defacing
  cp -R $BIDS_DIR_FACE/$SUB/dwi   $BIDS_DIR_DEFACE/$SUB/dwi
  cp -R $BIDS_DIR_FACE/$SUB/fmap  $BIDS_DIR_DEFACE/$SUB/fmap
  cp -R $BIDS_DIR_FACE/$SUB/func  $BIDS_DIR_DEFACE/$SUB/func

  ## Copy over top-level files
  cp $BIDS_DIR_FACE/$SUB/${SUB}* $BIDS_DIR_DEFACE/$SUB/
#end of "for SUB in `cat ${SUBJECT_LIST}`"
#done

cd $ORIG_DIR

END_TIME=`date`

echo Start Time: $START_TIME
echo   End Time: $END_TIME
