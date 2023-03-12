//Macro to quantify ER associated mitochondria at variable distances in 2D TEM images
//With ROI Group Manager, draw first mito, then the ER associated with it
//Objects should be labeled as follows: mito, MAM Rough,  MAM tight

run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

name=getInfo("image.filename");
dir=getInfo("image.directory");

var width, height, count;
// pixel sccale in nm, and name in ROI file   Mitochondrion, MAM Rough,  MAM tight
var pixelscale, mitoroiname, roughname, tightname
var r_dis, r_count, t_dis, t_count, r_length, t_length; 

// parameters for mito count and the size/perimeter
var mitoindex;
var mito_size=newArray(1000), mito_peri=newArray(1000), mito_peri_now;

// acquire parameter
Dialog.create("Parameter Input");
Dialog.addString("Mitochondia Name:", "Mitochondria");
Dialog.addString("MAM Rough Name:", "MAM rough");
Dialog.addString("MAM Tight Name:", "MAM tight");
Dialog.addNumber("PxielScale (nm/pixel):", 4.243);
Dialog.show();
mitoroiname = Dialog.getString();
roughname = Dialog.getString();
tightname = Dialog.getString();
pixelscale = Dialog.getNumber();


// get Width and Height, total ROI count
width=getWidth(); height=getHeight(); count=roiManager("Count");
newImage("map", "8-bit black", width, height, 1);

// reset pixel scale and measurement
run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1.0000000");
run("Set Measurements...", "area perimeter integrated limit redirect=None decimal=9");

// print header
print("RawFile:	"+dir+name);
print("PixelScale(nm/pixel)	"+pixelscale); print("   ");
print("Mito#	Size	Perimeter/Length	Ave_Distance	%rough	%tight	%rough+tight	rough_dis	tight_dis	rough_count	tight_count");

// start index of i   i=0  --> i=count-1
i=0;
while( i< count  )
 {
  //get roiname of the ith selection	
  //roiManager("Select", i ); 
  //roiname=Roi.getName(); 
  roiname=call("ij.plugin.frame.RoiManager.getName", i);

  // read a new "Mitochodria selection, start the new while loop
  if( indexOf(roiname, mitoroiname) > -1 )
   {
     
    // print result from previous mitochondria
    if( mitoindex>0)
     {
      print(" 	 	 	 	"+r_length/mito_peri_now+"	"+t_length/mito_peri_now+"	"+(r_length+t_length)/mito_peri_now+"	"+r_dis/r_count+"	"+t_dis/t_count+"	"+r_count+"	"+t_count);
      print("  ");	
     }
   	
    // get the Mitochondria size and perimeter
    roiManager("Select", i ); roiManager("Measure");
    mito_size[mitoindex]=getResult("Area", 0)*pixelscale*pixelscale; mito_peri[mitoindex]=getResult("Perim.", 0)*pixelscale; mito_peri_now=mito_peri[mitoindex];
    print(mitoindex+1+" : "+roiname+"	"+mito_size[mitoindex]+"	"+mito_peri[mitoindex]);
    //print(" 	selectionname	length	average_distance");
    mitoindex++;  run("Clear Results");

    //create map picture, the distance map for Mito of mitoindex
    selectImage("map"); run("Select All"); run("Clear", "slice"); run("Select None");
    roiManager("Select", i);  roiManager("Fill"); run("Invert");  run("Distance Map");  

    r_dis=0; r_count=0; t_dis=0; t_count=0; r_length=0; t_length=0; 
   }
    
  // if not a Mitochrondia,  based on the selection name and measure hte selction length and average distance to mito selection
  else
   {  
    // if selection is either "MAM tight or MAM rough	
    if( indexOf(roiname, tightname) > -1 || indexOf(roiname, roughname) > -1 )
     {
      
      // get length	
      roiManager("Select", i ); roiManager("Measure");
      length=getResult("Length",0)*pixelscale;  run("Clear Results");

      if( indexOf(roiname, tightname) > -1 ) { t_length=t_length+length; t_count++ ; }
      if( indexOf(roiname, roughname) > -1 ) { r_length=r_length+length; r_count++ ; }

      // get average distance
      newImage("distance", "8-bit black", width, height, 1);
      roiManager("Select", i ); run("Draw", "slice"); run("Select None");
      selectImage("distance"); run("Measure");
      tmppixel=getResult("RawIntDen", 0 ) / 255;

      imageCalculator("AND", "distance","map"); run("Measure");
      avedis=getResult("RawIntDen", 1) / tmppixel * pixelscale;
      run("Clear Results");  selectImage("distance"); close();

      if( indexOf(roiname, tightname) > -1 ) { t_dis=t_dis+avedis; }
      if( indexOf(roiname, roughname) > -1 ) { r_dis=r_dis+avedis; }

      //print out results
      print(" 	"+roiname+"	"+length+"	"+avedis);         	
     }
   } // end else

  //print(" 	 	 	 	"+r_length/mito_peri[mitoindex]+"	"+t_length/mito_peri[mitoindex]+"	"+(r_length+t_length)/mito_peri[mitoindex]+"	"+r_dis/r_count+"	"+t_dis/t_count+"	"+r_count+"	"+t_count);
  //print("  ");

  //go ot next selection
  i++; 
 } // end while

//print last mito
print(" 	 	 	 	"+r_length/mito_peri_now+"	"+t_length/mito_peri_now+"	"+(r_length+t_length)/mito_peri_now+"	"+r_dis/r_count+"	"+t_dis/t_count+"	"+r_count+"	"+t_count);
print("  ");	

run("Close All");
selectWindow("Log"); saveAs("Text", dir+name+"_Summary.xls");
run("Close");  roiManager("reset");
