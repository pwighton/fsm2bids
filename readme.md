# fsm2bids

Notes on how to conver the FreeSufer maintenance grant dataset (fsm) to BIDS format

## Overview

This repo describes how the FSM dataset was converted to BIDS and contains the [heudiconv heuristic file](fsm2bids-heuristic.py).

## Setup

1) Create a new pyton environment
```
conda create --name heudiconv python=3.7
conda activate heudiconv
pip install heudiconv
```

2) Install dmc2niix, and ensure it's in your PATH

See [dmc2niix's installation instructions](https://github.com/rordenlab/dcm2niix#install)

3) Create a DICOM directory

Inside the DICOM directory, create a sub-directory for each subject.  The FSM dataset is single session, so we don't have to worry about sub-dividing for sessions.

We'll use the env var `DICOM_DIR` to refer to this directory.

To obfusacte subject names, we create symlinks in the `DICOM_DIR` with the obfuscated subject name, that points to the subject directory with the actual DICOMs.

4) Create an output directory for `heudiconv`

This directory represents a 'first pass' at creating the BIDS dataset.  We'll need to operate over this directory to create the final BIDS dataset and do things like:
- Fill out the stub json files that heudiconv creates (i.e. `dataset_description.json`, etc)
- Deface the data
- Scrub sensitive information from the json sidecar files

We'll use the env var `HEUDICONV_OUT` to refer to this directory

5) Create an env var to point to the heudiconv heuristic file

This is the file [`fsm2bids-heuristic.py`](fsm2bids-heuristic.py) in this repository.

We'll use the env var `HEUDICONV_HEURISTIC` to refer to this file

6) Create an output directory for the final BIDS dataset to be published.  This will contain a defaced version of the BIDS dataset.

We'll use the env var `BIDS_FINAL` to refer to this directory

7) Create a working directory for [`mideface`](https://surfer.nmr.mgh.harvard.edu/fswiki/MiDeFace)

### Example

This is what I use to get everything setup n my machine:
```
conda activate heudiconv
export DICOM_DIR=/home/paul/lcn/20220822-fsm-bids/dicom
export HEUDICONV_OUT=/home/paul/lcn/20220822-fsm-bids/heudiconv-out
export BIDS_FINAL=/home/paul/lcn/20220822-fsm-bids/bids-final
export MIDEFACE_WORK=/home/paul/lcn/20220822-fsm-bids/mideface-work
export HEUDICONV_HEURISTIC=/home/paul/lcn/git/fsm2bids/fsm2bids-heuristic.py
```

Note all of the above directories, with the exception of `BIDS_FINAL` contains PHI and should not be distributed.

## Using heudiconv

### Initial scan

To begin, we run heudiconv in 'convertall' mode on a single subject to analyse the dataset and help us build the heuristics file.  Here, we are using the subject `sub-fsm042`

```
heudiconv \
  -d ${DICOM_DIR}/sub-{subject}/* \
  -s fsm042 \
  -o ${HEUDICONV_OUT} \
  -c none \
  -f convertall \
  --overwrite
```

This creates the directory `.heudiconv` under `$HEUDICONV_OUT`.

### Create the `$HEUDICONV_HEURISTIC` file

The file `${HEUDICONV_OUT}/.heudiconv/fsm042/info/dicominfo.tsv` is very helpful for creating the [heuristic file](fsm2bids-heuristic.py).

Other useful resources:
- [Heuristic documentation](https://heudiconv.readthedocs.io/en/latest/heuristics.html)
- [Example heuristic files](https://github.com/nipy/heudiconv/tree/master/heudiconv/heuristics)
- [BIDS spec for MR files](https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/01-magnetic-resonance-imaging-data.html)

### Convert a single subject

Use the [heuristic file](fsm2bids-heuristic.py) created above to convert data.  We need to delete the `${HEUDICONV_OUT}/.heudiconv` directory, otherwise heudiconv will use the cached heurisitc file (in this case, `${HEUDICONV_OUT}/.heudiconv/fsm042/info/heuristic.py` and nothing interesting will happen.

So let's go ahead and delete the entire `${HEUDICONV_OUT}/.heudiconv` directory:
```
rm -rf ${HEUDICONV_OUT}/.heudiconv
```

Then:
```
heudiconv \
  -d ${DICOM_DIR}/sub-{subject}/* \
  -s fsm042 \
  -o ${HEUDICONV_OUT} \
  -c dcm2niix \
  -f ${HEUDICONV_HEURISTIC} \
  --bids \
  --overwrite
```

### Convince yourself everything converted correctly

See the converted files in `${HEUDICONV_OUT}/sub-fsm042`

### Repeat for all other subjects

Edit `convert-all.bash` set the variables `HEUDICONV_OUT`, `DICOM_DIR` and `HEUDICONV_HEURISTIC` accordingly then run.

### Create a defaced version of the BIDS dataset.

Edit `daface.bash` and set:
  - `BIDS_DIR_FACE` to the value of `HEUDICONV_OUT` above
  - `WORK_DIR` to the value of `MIDEFACE_WORK` above
  - `BIDS_DIR_DEFACE` to the value of `BIDS_FINAL` above
  - `DERIVATIVES_DIR` to `${BIDS_DIR_DEFACE}/derivatives/mideface`

Then run the `deface.bash` script which will iterate through each subject and:
  - Runs `mideface` on: 
    - `${SUB}_acq-gre3d_echo-1_part-mag_MEGRE.nii.gz`
    - `${SUB}_acq-gre3d_T2starmap.nii.gz`
    - `${SUB}_acq-mp2rage_inv-2_MP2RAGE.nii.gz`
    - `${SUB}_acq-mprageVnav_T1wRMS.nii.gz`
    - `${SUB}_acq-t2flair_T2w.nii.gz`
    - `${SUB}_acq-t2spaceVnav_T2w.nii.gz`
  - Applies the resulting `mideface` facemasks to all other mag contrasts from the same sequence
  - For sequences with phase images:
    - The resulting facemask is `not`ed to produce a `mul` facemask (face voxels are `0`, all other voxels are `1`)
    - Multiples the phase image with this `mul` facemask to deface
  - Copies over `.json` files from the `anat` directory
  - Copies over non-defaced directories, including `func`, `fmap` and `dwi`
  - Copes over top-level subject files (`${SUB}_scans.tsv`)
  
### Finalize the dataset

TODO
  - File/json sidecar cleanup
  - Validate

## Todo

- How to specify a specific session, if multiple sessions of the same sequences exists?
- Validate
