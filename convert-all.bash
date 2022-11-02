#!/bin/bash

HEUDICONV_OUT=/autofs/vast/gerenuk/pwighton/fsm-bids/20221006-heudiconv
DICOM_DIR=/autofs/vast/gerenuk/pwighton/fsm-bids/dicoms
HEUDICONV_HEURISTIC=/autofs/vast/gerenuk/pwighton/fsm-bids/fsm2bids/fsm2bids-heuristic.py

# Key file is not stored in repo (sensitive info!)
# but it's format is:
#
# actual_subname  obfuscated_suffix dicom_dir
KEY_FILE=/autofs/vast/gerenuk/pwighton/fsm-bids/key_dcm.txt

for SUB in `cat $KEY_FILE|awk '{print $2}'`
do
  heudiconv \
    -d ${DICOM_DIR}/{subject}/* \
    -s fsm${SUB} \
    -o ${HEUDICONV_OUT} \
    -c dcm2niix \
    -f ${HEUDICONV_HEURISTIC} \
    --bids \
    --overwrite
done
