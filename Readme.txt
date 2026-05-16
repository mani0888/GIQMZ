**Requirements**

The code was developed and tested in MATLAB.

Recommended MATLAB toolboxes:
  1. Image Processing Toolbox
  2. Statistics and Machine Learning Toolbox

**Usage**
1. Clone the repository
https://github.com/mani0888/GIQMZ.git 

2. Prepare image data
Place the distorted or rendered images in a local folder. Update the image path and information dataset inside the MATLAB scripts as required.
For example, in main_CIQMz_v2.m, update:
path = 'path_to_your_dataset/distorted/';

3. Run CIQM_ZN feature extraction
run main_CIQMz_v2.m
This script extracts CIQM_ZN-related color appearance and naturalness-based features.

4. Run SIQMZ feature extraction
run main_SIQMz_v1.m
This script extracts SIQMZ-related NSS features from chroma and depth channels.

**Notes**
GBD.mat is required for computing gamut-boundary-based color appearance ratios in CIQM_ZN.
The scripts may require minor path modification depending on the local dataset structure.
The current scripts are intended for feature extraction and evaluation as described in the manuscript.
Users should ensure that image names, dataset folders, and MOS/DMOS files are organized consistently with the script settings.

**Citation**
If you use this code or the proposed metrics in your research, please cite the associated IEEE Access article:
@article{khan2026giqmz,
  title = {No-Reference Generic Image Quality Assessment via Adaptive Fusion of Naturalness-Enhanced Color and Appearance-Driven Spatial Metrics},
  author = {Khan, Muhammad Usman and Mehmood, Imran and Luo, Ming Ronnier},
  journal = {IEEE Access},
  year = {2026} 
}
