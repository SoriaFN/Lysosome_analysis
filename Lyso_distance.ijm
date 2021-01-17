/*
 * LYSOSOME DISTANCE TO NUCLEUS v1.0
 * ---------------------------------
 * 
 * This macro calculates the distance from each lysosome (or similar puncta)
 * to the center and average edge of the nucleus.
 * 
 * Cell and nuclei segmentation is performed manually (via manual ROIs).
 * Lysosome segmentation is automated via a pre-defined threshold.
 * 
 * A multichannel calibrated image is required
 * (one channel to segment cell, another to segment lysosomes).
 * 
 * If the image is a z-stack, a Maximal Intensity Projection will be calculated.
 * (the script is optimized for single z-planes, though).
 * 
 * The script has been optimized for in vivo immunostaining, where lysosomal labelling can be noisy.
 * Hence, the macro includes a Difference of Gaussians filter to enhance contrast.
 * (I will make this optional in the future).
 * 
 * 
 * Federico N. Soria (January 2021)
 * federico.soria@achucarro.org
 * 
 */

//INITIALIZATION
run("Collect Garbage");
Overlay.remove;
if (nImages==0) {
	exit("No images open. Please open an image");
}
name=getTitle();
getDimensions(width, height, channels, slices, frames);
if (channels==1) {
	exit("Image is not multichannel. Please open a multichannel image");
}
getPixelSize(unit, pw, ph);
run("Set Measurements...", "area centroid fit redirect=None decimal=2");
setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);

//GUI
ch_list=newArray(channels);
for (i=0; i<channels; i++){
		ch_list[i]=""+i+1+"";
}
thres_list = getList("threshold.methods");
Dialog.create("Lysosome distance to Nucleus for FIJI");
Dialog.addChoice("Channel for reference ROI (cell)", ch_list, "1");
Dialog.addString("Name for ref channel", "TH");
Dialog.addMessage("\n");
Dialog.addChoice("Channel for lysosome labelling", ch_list, "2");
Dialog.addString("Name for coloc channel", "LAMP2");
Dialog.addChoice("Threshold for coloc channel", thres_list, "Default");
Dialog.addMessage("\n");
Dialog.addNumber("Minimum sigma for DifGaus filter", 1);
Dialog.addNumber("Maximum sigma for DifGaus filter", 50);
Dialog.addCheckbox("Save binary images, values an ROIs to disk?", false);
Dialog.addMessage("\n(c) Federico N. Soria (federico.soria@achucarro.org)\nJan 2021");
Dialog.show();
cell_ch=Dialog.getChoice();
cell_name=Dialog.getString();
lyso_ch=Dialog.getChoice();
lyso_name=Dialog.getString();
thres_lyso=Dialog.getChoice();
gmin=Dialog.getNumber();
gmax=Dialog.getNumber();
save_files=Dialog.getCheckbox();

//DIRECTORY CREATION
if (save_files==true) {
	dir=getDirectory("Choose a folder to save Result files.");

	//DIRECTORY FOR IMAGES
	dir_im = dir + "Images" + File.separator;
	if (File.exists(dir_im)==false) {
		File.makeDirectory(dir_im);
	}
	
	//DIRECTORY FOR VALUES
	dir_val = dir + "Values" + File.separator;
	if (File.exists(dir_val)==false) {
		File.makeDirectory(dir_val);
	}
	
	//DIRECTORY FOR ROIS
	dir_roi = dir + "ROIs" + File.separator;
	if (File.exists(dir_roi)==false) {
		File.makeDirectory(dir_roi);
	}
}

//MIP CREATION
print("Analyzing "+ name + " ...");
run("Select None");
if (slices>1) {
	run("Z Project...", "projection=[Max Intensity]");
	print("MIP created.");
}
run("Duplicate...", "title=TEMP duplicate");

//PREPROCESSING
run("Grays"); 
difgaus(gmin, gmax, "DifGaus");
selectWindow("DifGaus");	
run("Split Channels");
n=0;

do{	
	n=n+1;
	
	//CLEAN FROM PREVIOUS
	roiManager("reset");
	roiManager("Show None");
	run("Select None");
	run("Clear Results");
	
	//CELL ROI
	selectWindow("C"+cell_ch+"-DifGaus");
	run("Enhance Contrast", "saturated=0.35");
	setTool("polygon");
	waitForUser("Draw a selection precisely around the cell soma and press OK");
	roiManager("Add");
	roiManager("select", 0);
	roiManager("rename", "cell soma");
	run("Select None");

	//NUCLEAR ROI
	waitForUser("Now draw a selection precisely around the nucleus and press OK");
	run("Fit Spline"); //To calculate max and min radius it will consider it an ellipse
	roiManager("Add");
	roiManager("Select", 1);
	roiManager("rename", "cell nucleus");
	run("Measure");
	r_major = getResult("Major")/2; //Major radius of the fitted ellipse
	r_minor = getResult("Minor")/2; //Minor radius of the fitted ellipse
	radius = (r_major+r_minor)/2; //Average radius, used to calculate distance to border
	x0 = (getResult("X"))*(1/pw);
	y0 = (getResult("Y"))*(1/ph);
	
	//LYSOSOME SEGMENTATION
	selectWindow("C"+lyso_ch+"-DifGaus");
	run("Duplicate...", " ");
	rename(name+"_"+lyso_name);
	puncta ("Default dark", 0, 10);

	//LYSOSOME DISTANCE
	ROIcount=roiManager("count");
	counter=1;
    for (i=2;i<ROIcount;i++) {
    	roiManager("select", i);
		getSelectionBounds(x1, y1, width1, height1);
		dx=(x0 - x1)*pw;
		dy=(y0 - y1)*ph;
		d_to_center = sqrt(dx*dx + dy*dy); //euclidean distance to center
		d_to_border = d_to_center - radius; //distance to border of nucleus
		Overlay.drawLine(x0, y0, (x1+width1/2), (y1+height1/2));
		Overlay.show;
		Overlay.setStrokeWidth(2);
		myTable(name,counter,cell_name,lyso_name,unit,d_to_center,d_to_border);
		counter=counter+1;
    }

	//SAVE SEGMENTED IMAGE AND ROIs
    if (save_files==true) {
    	selectWindow(name+"_"+lyso_name);
		saveAs("tiff", dir_im+File.separator+"BIN_"+name+"_"+lyso_name+"_"+n);
		roiManager("save", dir_roi+"ROI_"+name+"_"+n+".zip");
    }
    
	cont=getBoolean("Do you want to analyze another cell?");
}while(cont==true);

print((counter-1)+" lysosomes analysed");
run("Tile");

//SAVE RESULTS
if (save_files==true) {
	
	selectWindow("Quantification");
	saveAs("Text", dir_val+File.separator+"DISTANCES_"+name+".csv");
	
	print("Result files saved in "+dir);
}

//EXIT
close_images = getBoolean("Close all images?");
if (close_images==true) {
	run("Close All");	
}
print("DONE!");
print("");




//FUNCTION: DoG FILTERING
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

//FUNCTION: PUNCTA SEGMENTATION 
function puncta (autothres, ROI, size){
	setAutoThreshold(autothres);
	run("Convert to Mask");
	roiManager("Select", ROI);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside");
	run("Select None");
	run("Watershed");
	run("Analyze Particles...", "size="+size+"-Infinity pixel add");
}

//FUNCTION: CUSTOM TABLE
function myTable(a,b,c,d,e,f,g){
	title1="Quantification";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f+"\t"+g);
	}
	else{
   		run("Table...", "name="+title2+" width=800 height=400");
   		print(title2, "\\Headings:File\tLyso#\tCell type\tLyso marker\tUnit of D\tD to nucleus center\tD to nucleus border");
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f+"\t"+g);
	}
}
