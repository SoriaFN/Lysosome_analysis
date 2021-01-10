# Lysosome Analysis
ImageJ scripts used in *Arotcarena, Soria et al. (2021) [Journal]

## Lyso_distance.ijm
*This macro calculates the distance from each lysosome (or similar puncta) to the center and average edge of the nucleus.*

Cell and nuclei segmentation is performed manually (via manual ROIs). Lysosome segmentation is automated via a pre-defined threshold.
A multichannel calibrated image is required (one channel to segment cell, another to segment lysosomes).
If the image is a z-stack, a Maximal Intensity Projection will be calculated (the script is optimized for single z-planes, though).
The script has been optimized for in vivo immunostaining, where lysosomal labelling can be noisy. Hence, the macro includes a Difference of Gaussians filter to enhance contrast. (I will make this optional in the future).

**How to use**
1. Drag and drop lyso_distance.ijm file into FIJI
2. Open an image (preferably not a z-stack)
3. Run the script. A GUI will let you choose the segmentation channels and whether save results to file.
4. Follow the instructions. At the end, an overlay will show you vectors where each distance was calculated.
5. If you chose to save files, the binary image, ROIs and .csv quantification table will be available at the directory of choice.

The macro has been tested only with our datasets, so you will probably find bugs, or have suggestions. Please e-mail me.
