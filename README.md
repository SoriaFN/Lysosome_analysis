# Lysosome Analysis
ImageJ/FIJI scripts used in *Arotcarena, Soria et al. (2022) Aging Cell*

# How to cite
Please acknowledge these scripts if you use them in your publication. Cite the DOI from Zenodo.
[![DOI](https://zenodo.org/badge/328500157.svg)](https://zenodo.org/badge/latestdoi/328500157)

## Lyso_distance.ijm
This macro calculates the distance from each lysosome (or similar puncta) to the center and average edge of the nucleus.

**How to use**
1. Open lyso_distance.ijm file in FIJI.
2. Open a *multichannel* image.
3. Run the script. A GUI will let you choose the segmentation channels and whether to save results to file.
4. Follow the instructions for manual segmentation. At the end, an overlay will show you vectors where each distance was calculated.
5. If you chose to save files, the binary image, ROIs and .csv quantification table will be available at the directory of choice.

**Notes**
- Cells and nuclei segmentation is performed manually (via manual ROIs). Lysosome segmentation is automated via a pre-defined threshold chosen by the user at start.
- A multichannel image is needed: one channel to segment cell, another to segment lysosomes. For in vivo this is crucial to be sure you are quantifying lysosomes in the correct cell type. For in vitro, you need at least a reference to manually segment the cell and its nucleus (it can be brightfield channel).
- If the image is a z-stack, a Maximal Intensity Projection will be calculated (the script is optimized for single z-planes, though, since distances in z get distorted in confocal).
- The script has been optimized for in vivo immunostaining, where lysosomal labelling can be noisy. Hence, the macro includes a Difference of Gaussians filter to enhance features for automatic puncta segmentation. You can minimize filtering by increasing the maximum sigma. 
- The "distance to border" is estimated using an *average* radius, which is calculated from an ellipse fitted to the (manually segmented) nuclear ROI. Hence, some lysosome distances might appear as negative values (This usually means that the lysosome is next to the nucleus border, but in some part where the nucleus does not achieve it maximal radius).
- The "distance to center" is preferred only if all quantified cells have very similar nuclear area.

## Lyso_puncta_coloc.ijm
This macro calculates the number of lysosome puncta (e.g. LAMP2-positive vesicles) within a cellular ROI. It also estimates colocalization with other similar puncta (e.g. CatD).

**How to use**
1. Open lyso_puncta_coloc.ijm file in FIJI.
2. Open a *multichannel* image.
3. Run the script. A GUI will let you choose the segmentation and puncta channels and whether to save results to file.
4. Follow the instructions for cell segmentation. Puncta segmentation is automatic (user-defined threshold).
5. If you chose to save files, Results table and log.txt (to document the different thresholds used) will be available at the directory of choice.
6. The custom results table can be left open after finishing analysis. It will be updated after quantification of successive images (useful for batch).

**Notes**
- Cell segmentation uses a threshold manually adjusted by the user. Since this threshold defines the cellular ROI where lysosomes will be searched, it is better to be less conservative.
- Lysosome segmentation is automated via a pre-defined threshold chosen by the user at start.
- A multichannel single plane image is needed: one channel to segment cell, another to segment lysosomes ("ref_puncta"), and a second type of puncta ("coloc_puncta").
- The script has been optimized for in vivo immunostaining, where lysosomal labelling can be noisy. Hence, the macro includes a Difference of Gaussians filter to enhance features for automatic segmentation. You can minimize filtering by increasing the maximum sigma.
- A batch version of this macro (with fully automated cell segmentation) is available in my "Tools" repository.

***These scripts have been tested in FIJI with our images only. If you find bugs, or have suggestions, please e-mail me.***
