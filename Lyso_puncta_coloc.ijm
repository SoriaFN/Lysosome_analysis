/*
 * LYSOSOMAL PUNCTA AND COLOCALIZATION v1.0  
 * ----------------------------------------
 * 
 * This macro allows to quantify lysosomal (and other) puncta, plus colocalization with
 * other lysosomal marker (CatD, LC3, etc).
 * 
 * Ideally, the image will have 3 channels, being channel 1 used for cell segmentation.
 * In this version, channels 2 and 3 are puncta to be quantified.
 * 
 * Cell segmentation is performed via a manually adjusted threshold.
 * Puncta segmentation is automated, with a predefined threshold.
 * 
 * The macro creates a custom table with results.
 * This window can remain open and it will be updated with each image.
 * 
 * Only one image should be open for the macro to work.
 * I will include a batch mode on the github repo in the next version.
 * 
 * The script has been optimized for in vivo immunostaining, where lysosomal labelling can be noisy.
 * Hence, the macro includes a Difference of Gaussians filter to enhance contrast.
 * (I will make this optional in the future).
 *
 * Federico N. Soria (January 2021) 
 * federico.soria@achucarro.org
 */

//INITIALIZATION
if (nImages==0) {
	exit("No images open. Please open an image");
}
run("Select None");
run("Clear Results");
roiManager("reset");
run("Set Measurements...", "area limit display redirect=None decimal=2");
print("\\Clear");

//IMAGE INFO
name=getTitle();
getDimensions(width, height, channels, slices, frames);

//GUI DIALOG
ch_list=newArray(channels);
for (i=0; i<channels; i++){
		ch_list[i]=""+i+1+"";
}
thres_list = getList("threshold.methods");
Dialog.create("Macro Parameters");
Dialog.addNumber("Minimum sigma for DifGaus filter", 1);
Dialog.addNumber("Maximum sigma for DifGaus filter", 50);
Dialog.addMessage("\n");
Dialog.addChoice("Channel for cell segmentation", ch_list, "1");
Dialog.addString("Name for ref channel", "TH");
Dialog.addNumber("Min cell size in calibrated units", 20); //This is used to separate somas from isolated neurites.
Dialog.addMessage("\n");
Dialog.addChoice("Channel for reference puncta", ch_list, "2");
Dialog.addString("Name for ref puncta channel", "LAMP2");
Dialog.addChoice("Threshold for ref puncta channel", thres_list, "Default");
Dialog.addNumber("Min puncta size", 10);
Dialog.addMessage("\n");
Dialog.addChoice("Channel for colocalized puncta", ch_list, "3");
Dialog.addString("Name for coloc puncta channel", "CatD");
Dialog.addChoice("Threshold for coloc puncta channel", thres_list, "Moments");
Dialog.addNumber("Min puncta size", 10);
Dialog.addCheckbox("Save values to file", true);
Dialog.show();

gmin=Dialog.getNumber();
gmax=Dialog.getNumber();
seg_chan=Dialog.getChoice();
seg_name=Dialog.getString();
cell_size=Dialog.getNumber();

ref_chan=Dialog.getChoice();
ref_name=Dialog.getString();
ref_thres=Dialog.getChoice();
ref_size=Dialog.getNumber();

coloc_chan=Dialog.getChoice();
coloc_name=Dialog.getString();
coloc_thres=Dialog.getChoice();
coloc_size=Dialog.getNumber();

savetofile=Dialog.getCheckbox();

//IMAGE PREPROCESSING
run("Grays");
difgaus(gmin, gmax, "DifGaus");
selectWindow("DifGaus");
run("Split Channels");

//CELL SEGMENTATION
selectWindow("C"+seg_chan+"-DifGaus");
rename(name+"_"+seg_name);
run("Threshold...");

waitForUser("Set Threshold", "Set Threshold for cell segmentation using the upper sliding bar \nCheck the 'Dark Background' box if necessary. \nThen click OK. \nDo not press Apply!");

run("Convert to Mask");
run("Analyze Particles...", "size="+cell_size+"-Infinity show=Outlines summarize");

selectWindow(name+"_"+seg_name);
setOption("BlackBackground", true);
run("Fill Holes");
run("Create Selection");
run("Enlarge...", "enlarge=5 pixel"); //This is to ensure you get also the lysosomes close to the membrane.
roiManager("Add");

//PUNCTA QUANTIFICATION 
setBackgroundColor(0, 0, 0);

selectWindow("C"+ref_chan+"-DifGaus");
rename(ref_name);
puncta (ref_thres+" dark", ref_size);

selectWindow("C"+coloc_chan+"-DifGaus");
rename(coloc_name);
puncta (coloc_thres+" dark", coloc_size);

//COLOCALIZATION (number of CH3 puncta colocalizing with CH2)
selectWindow(ref_name);
setAutoThreshold("Default dark");
run("Create Selection");
roiManager("Add");
selectWindow(coloc_name);
run("Duplicate...", "title=["+coloc_name+" in "+ref_name+"]");
roiManager("Select", 1);
run("Clear Outside");
run("Select None");
run("Analyze Particles...", "size=4-Infinity pixel summarize");

//GET VALUES
IJ.renameResults("Summary","Results");
if (savetofile==true) {
	dir=getDirectory("Choose Directory to save files");
	saveAs("Results", dir+File.separator+name+".xls");
	selectWindow("Log");
	saveAs("Text", dir+File.separator+name+".txt");
}
cells=getResult("Count", 0);
ref_val=getResult("Count", 1);
coloc_val=getResult("Count", 2);
coloc_in=getResult("Count", 3);
coloc_out=coloc_val-coloc_in;
selectWindow("Results");
run("Close");

//CUSTOM TABLE
myTable(name,cells,ref_val,coloc_val,coloc_in,coloc_out);

function myTable(a,b,c,d,e,f){
	title1="Quantification";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f);
	}
	else{
   		run("Table...", "name="+title2+" width=800 height=500");
   		print(title2, "\\Headings:File\tCells\tNumber of "+ref_name+"\tNumber of "+coloc_name+"\t"+coloc_name+" in "+ref_name+"\t"+coloc_name+" outside "+ref_name);
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f);
	}
}
waitForUser("Copy Results to Excel");

//EXIT
run("Tile");
waitForUser("Close all windows");
run("Close All");


//FUNCTION FOR IMAGE ENHANCEMENT (from Jorge Valero @Achucarro)
function difgaus (min, max, finalname){
	run("Duplicate...", "title=min duplicate");
	run("Gaussian Blur...", "sigma="+min+" stack");
	run("Duplicate...", "title=max duplicate");
	run("Gaussian Blur...", "sigma="+max+" stack");

	imageCalculator("Subtract stack", "min","max");
	selectWindow("max");
	close();
	selectWindow("min");
	rename(finalname);
}

//FUNCTION FOR PUNCTA QUANTIFICATION ("autothres is the Automatic Threshold chosen. "Size" is minimum size in pixels for segmentation) 
function puncta (autothres, size){
	setAutoThreshold(autothres);
	run("Convert to Mask");
	roiManager("Select", 0);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	run("Select None");
	run("Watershed");
	run("Analyze Particles...", "size="+size+"-Infinity pixel summarize");
	print("Threshold used for "+getTitle()+": "+autothres);
}
