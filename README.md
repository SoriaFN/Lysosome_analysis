# Lysosome Analysis
ImageJ scripts used in *Arotcarena, Soria et al. (2021) [Journal]*

## Lyso_distance.ijm
*This macro calculates the distance from each lysosome (or similar puncta) to the center and average edge of the nucleus.*

**How to use**
1. Drag and drop lyso_distance.ijm file into FIJI
2. Open a *multichannel* image.
3. Run the script. A GUI will let you choose the segmentation channels and whether to save results to file.
4. Follow the instructions. Manual segmentation At the end, an overlay will show you vectors where each distance was calculated.
5. If you chose to save files, the binary image, ROIs and .csv quantification table will be available at the directory of choice.

**Notes**
- Cells and nuclei segmentation is performed manually (via manual ROIs). Lysosome segmentation is automated via a pre-defined threshold that you can choose at start.
- A multichannel image is needed: one channel to segment cell, another to segment lysosomes. For in vivo this is crucial to be sure you are quantifying lysosomes in the correct cell type. For in vitro, you need at least a reference to manually segment the cell and its nucleus (it can be brightfield channel).
- If the image is a z-stack, a Maximal Intensity Projection will be calculated (the script is optimized for single z-planes, though, since distances in z get distorted in confocal).
- The script has been optimized for in vivo immunostaining, where lysosomal labelling can be noisy. Hence, the macro includes a Difference of Gaussians filter to enhance features for automatic segmentation. You can minimize filtering by increasing the maximum sigma. 
- The "distance to border" is estimated using an *average* radius, which is calculated from an ellipse fitted to the (manually segmented) nucleus ROI. Hence, some lysosome distances might appear as negative values. This means that the lysosome is next to the nucleus border, but in some part where the nucleus does not achieve it maximal radius.
- The "distance to center" is preferred only if all quantified cells have very similar nuclear area.


The macro has been tested only with our datasets, so you will probably find bugs, or have suggestions. Please e-mail me.
