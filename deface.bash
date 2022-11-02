#!/bin/bash

BIDS_DIR_FACE=/autofs/vast/gerenuk/pwighton/fsm-bids/20221006-heudiconv
BIDS_DIR_DEFACE=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip
DERIVATIVES_DIR=/autofs/vast/gerenuk/pwighton/fsm-bids/20221031-deface-wip/derivatives/mideface

ORIG_DIR=`pwd`

for SUB in "sub-fsm99tc"
do
  echo "Workin on subject: " $SUB
  mkdir -p $DERIVATIVES_DIR/$SUB/anat
  cd $DERIVATIVES_DIR/$SUB/anat
  # Create a facemask from the first echo of the MRGRE data, and apply the mask to all other echos
  mideface \
    --i $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE.nii.gz \
    --o $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE.nii.gz \
    --facemask $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz
  mideface --apply \
    $BIDS_DIR_FACE/$SUB/anat/${SUB}_acq-gre3d_echo-2_part-mag_MEGRE.nii.gz \
    $DERIVATIVES_DIR/$SUB/anat/${SUB}_acq-gre3d_echo-1_part-mag_MEGRE_facemask.nii.gz \
    regheader \
    $BIDS_DIR_DEFACE/$SUB/anat/${SUB}_acq-gre3d_echo-2_part-mag_MEGRE.nii.gz
done

cd $ORIG_DIR
