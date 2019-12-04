/* Script written by Brenton Cavanagh 2017 brentoncavanagh@rcsi.ie
 * 
 * Written to obtain the outline of large structure in an image so that shape descriptors and the ferret 
 * diameter can be used obtained. The ferret diameter ratio can be used to define elongated structures as 
 * opposed to more circular clusters.
 * 
 * This macro assumes that you have a 2 channel Z stack or a single 2 channel image. The second channel is 
 * used for analysis. For accurate measurement the appropriate scaling information should be present in the 
 * metadata.
*/

//The number 1 can be used to launch the macro once it is installed
macro "Structure Characterisation [1]" {

//Prepare the required images and set variables from the original image
name = File.nameWithoutExtension;
getDimensions(width, height, channels, slices, frames);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction limit display decimal=3");
if (channels==2 && slices >3){
	run("Z Project...", "start=1 stop"+slices+" projection=[Max Intensity]");
	run("Make Composite");
	MIP = getTitle();
	main(MIP);
}

else if (channels>1 && slices==1){
	run("Make Composite");
	main(name);
}

else{
	waitForUser("Error","This Images is not a 2 channel, Z stack.\n\rPlease try another image");
	run("Close All");
}

function main(MIP){
//rename images for ease
rename(name);
run("Duplicate...", "duplicate");
rename("working");
run("Split Channels");

//Close the unwanted first channel
selectWindow("C1-"+"working");
close();

//Continue processing the second channel, grayscale.
selectWindow("C2-"+"working");
run("Grays");

//Smooth the image and prompt for a user defined threshold.  Otsu often works well.
run("Gaussian Blur...", "sigma=3");
run("Threshold...");
setAutoThreshold("Otsu dark");
waitForUser( "Threshold the Structures of Interest","Please adjust the threshold so your structures of interest are red.\n\r \n\rThen press Ok");

//Binary processing to close structures
run("Convert to Mask");
run("Dilate");
run("Close-");
run("Erode");

//Create ROI's for each structure in the ROI manager
run("ROI Manager...");
roiManager("Reset");
run("Analyze Particles...", "size=100-Infinity pixel add");
selectWindow(name);
run("Enhance Contrast", "saturated=0.35");

//rename ROIs to Human readable and show them on the original image
for(i=0; i<roiManager("Count"); i++){
		//Create the cytoplasmic band ROI
		roiManager("Select", i);
		roiManager("Rename", (i+1));
		roiManager("Set Color", "White");
	}
roiManager("Show All with labels");

//Save ROIs created and those selected by the user
dir1 = getDirectory("Please choose where to save ROI's");
roiManager("Save", dir1+name+".zip");
waitForUser("Identify the Structures of interest","Using the ROI manager please delete all structures you DO NOT wish to analyse.\n\r \n\rThen press Ok");
roiManager("Save", dir1+name+"_selected.zip");
roiManager("multi-measure");

//prompt for the user to save the dataand then clean up for next session
selectWindow("Results");
waitForUser("Secure Results","Please copy the results into excel or save as a CSV file.\n\r \n\rThen press Ok when you are finished");
run("Close All");
}
