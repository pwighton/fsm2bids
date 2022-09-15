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

4) Create an output directory for `heudiconv`

This directory represents a 'first pass' at creating the BIDS dataset.  We'll need to operate over this directory to create the final BIDS dataset and do things like:
- Fill out the stub json files that heudiconv creates (i.e. `dataset_description.json`, etc)
- Deface the data
- Scrub sensitive information from the json sidecar files

We'll use the env var `HEUDICONV_OUT` to refer to this directory

5) Create an env var to point to the heudiconv heuristic file

This is the file [`fsm2bids-heuristic.py`](fsm2bids-heuristic.py) in this repository.

We'll use the env var `HEUDICONV_HEURISTIC` to refer to this file

6) Create an output directory for the final BIDS dataset to be published

We'll use the env var `BIDS_FINAL` to refer to this directory

### Example

This is what I use to get everything setup n my machine:
```
conda activate heudiconv
export DICOM_DIR=/home/paul/lcn/20220822-fsm-bids/dicom
export HEUDICONV_OUT=/home/paul/lcn/20220822-fsm-bids/heudiconv-out
export BIDS_FINAL=/home/paul/lcn/20220822-fsm-bids/bids-final
export HEUDICONV_HEURISTIC=/home/paul/lcn/git/fsm2bids/fsm2bids-heuristic.py
```

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

TODO

### Finalize the dataset

TODO
  - deface
  - File/json sidecar cleanup
  - Validate
  - Obfuscate subject names

## Todo

- How to specify a specific session, if multiple sessions of the same sequences exists?
- Defacing
- File/json cleanup
- Validate
