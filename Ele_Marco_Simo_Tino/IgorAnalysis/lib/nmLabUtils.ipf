#pragma rtGlobals=3
#include ":utils"

menu "nmLabUtils"
	"-"
	"Batch Lineshape Analysis /1", batchLineshapeAnalysis()
	"-"
	"Fit C1STR (Current Folder)", MenuItemFitC1STR()
	"Fit C1STR with CO (Current Folder)"	
end


function MenuItemFitC1STR()
	string currentFolder = getdataFolder(0)
	string imageName = currentFolder
	string coeffName = imageName + "_COEFF"
	
	print "Fitting spectra from wave:", imageName
	
	wave/z image = $imageName
	if(!waveexists(image))
		print "wave does not exist"
		return -1
	endif
	// if there are already coeff in the folder respect that
	wave/z coeff = $coeffName
	
	if(!waveexists(coeff))
		wave coeff = $("root:"+"KDefault_C1S_MultipleComponents")
		fitimageC1S(coeff, image,"multicomp",  offset = 30, duplicateInFolder=1)
	else
		fitimageC1S(coeff, image,"multicomp",  offset = 30)
	endif
end

function removeBackground(wave coeff, wave image, [variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime

	Print "Removing background using Mulitcomponents and CO of image : ",nameofWave(image)
	duplicate/o image, $(nameOfWave(image) + "_NoBG")
	wave background = $(nameOfWave(image) + "_NoBG")
	
	// get 1D waves
	duplicate/o/rmd=[][0] image, thisBackground, slice
	redimension/n=(-1,0) thisBackground, slice
	duplicate/o/rmd=[][0] coeff, thisCoeff
	redimension/n=(-1,0) thisCoeff
	
	display thisBackground, slice
	int i 
	for(i=0;i<dimsize(image,1);i++)
		thisCoeff[] = coeff[p][i]
		slice[] = image[p][i]
		plotPeaksC1S_compAndCO(thisCoeff, thisBackground, plot="bg")
		background[][i] = slice[p] - thisBackground[p]
		doUpdate
		Sleep/s sleepTime
	endfor 
end

function normalizeArea(wave coeff, wave image, [variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	Print "Normalizing spectra using area: ",nameofWave(image)
	duplicate/o image, $(nameOfWave(image) + "_Norm")
	wave normImage = $(nameOfWave(image) + "_Norm")
	
	// get 1D waves
	duplicate/o/rmd=[][0] image, slice, fitSlice
	redimension/n=(-1,0) slice, fitSlice
	duplicate/o/rmd=[][0] coeff, thisCoeff
	redimension/n=(-1,0) thisCoeff
	
	display slice, fitSlice
	int i 
	for(i=0;i<dimsize(image,1);i++)
		// remove bg and CO
		thisCoeff[] = coeff[p][i]
		thisCoeff[0,1] = 0
		thisCOeff[5] = 0
		
		// get the slices
		fitSlice = dsgnmBad2_MTHR(thisCoeff, x)
		slice = image[p][i]
		doUpdate
		Sleep/s sleepTime
		
		slice = slice[p] / waveMax(fitSlice)
		fitSlice = fitSlice[p] / waveMax(fitSlice)
		normImage[][i] = slice[p]
		
		doUpdate
		Sleep/s sleepTime
	endfor 
end

function fitImageGauss(wave image)

	variable N = dimsize(image, 1)
	variable i
	wave slice = $getslice(image, 0, name="slice")
	wave w_coeff = $getglobalWave("W_coeff")
	duplicate/o slice fitslice
	
	display/n=tempGraph slice, fitslice

	for(i=0;i<N;i++)
		slice[] = image[p][i]
		curvefit gauss slice/d=fitslice
		doUpdate
		sleep/s 0.1
	endfor
	
	killwindow tempGraph
	killwaves slice, fitslice	
end

function histogram2D(wave image)
	string name = nameofWave(image)
	wave slice = $getSlice(image, 0)

	// result
	//  Sturges' method
	int nbin = 1 + round((ln(dimsize(slice,0))/ln(2)))

	make/o/n=(nbin) hist
	make/o/n=0 $(name + "_Hist")
	make/free/n=0 tmp
	wave hist2D = $(name + "_Hist")
	
	int i 
	display/n=tempGraph0/w=(0,0,400,300) slice
	display/n=tempGraph1/w=(400,0,800,300) hist
	
	for(i=0;i<dimsize(image,1);i++)
		slice[] = image[p][i]
		Histogram/B=1 slice, hist
		if(i==0)
			duplicate/o hist hist2D
		else
			concatenate/o {hist2D, hist}, tmp
			duplicate/o tmp hist2D
		endif
		
		doUPdate
	endfor
	
	killWIndow tempGraph0
	killWIndow tempGraph1 
	killwaves hist, slice
end

function computeDifference(wave coeff, wave image, [variable n, variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime

	variable A
	n = paramisDefault(n) ? 0 : n
	Print "Computing difference using first fit spectre as reference"
	
	duplicate/o image, $(nameOfWave(image) + "_Diff")
	wave diffImage = $(nameOfWave(image) + "_Diff")
	
	duplicate/o/rmd=[][0] image, slice, fitSlice
	redimension/n=(-1,0) slice, fitSlice
	duplicate/o/rmd=[][0] coeff, thisCoeff
	redimension/n=(-1,0) thisCoeff
	
	// get n-th slice witout bg and CO
	thisCoeff[] = coeff[p][n]
	thisCoeff[0,1] = 0
	thisCOeff[5] = 0

	fitSlice = dsgnmBad2_MTHR(thisCoeff, x)
	A = waveMax(fitSlice)
	fitSlice = fitSlice[p] / A 
	
	display slice, fitSlice
	
	int i 
	for(i=0;i<dimsize(image,1);i++)
		slice = image[p][i]
		doupdate
		sleep/s sleepTime
		diffImage[][i] = slice[p] - fitSlice[p]
		
	endfor
end

function lineshapeCompatibility(wave coeff, wave image, [variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	string name = nameofWave(image)
	removeBackground(coeff, image, sleepTime=sleepTime)
	wave noBg = $(name + "_NoBg")
	normalizeArea(coeff, noBg, sleepTime=sleepTime)
	wave normalized  = $(name + "_NoBg_Norm")
	computeDifference(coeff, normalized, sleepTime=sleepTime)
end


function batchLineshapeAnalysis([variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	make/t/free targets = {"SE0523_100_2D", "SE0523_104_2D", "SE0523_108_2D", "SE0523_112_2D", "SE0523_120_2D", "SE0524_004_2D","SE0524_076_2D","SE0524_080_2D","SE0525_003_2D","SE0525_007_2D","SE0525_011_2D","SE0525_015_2D"}
	DFREF saveDFR = GetDataFolderDFR()		// Save
	SetDataFolder root:
	Print "batchLineshapeAnalysis"
	for(string target : targets)
		setDataFolder $("root:"+target+":")
		wave image = $(target)
		wave coeff = $(target + "_COEFF")
		lineshapeCompatibility(coeff, image, sleepTime=sleepTime)
	endfor
	
	
	SetDataFolder saveDFR		// and restore
	
end

function createFolder(wave wav, [wave initial_coeff])

	// names
	string name = nameOfWave(wav)
	string folderName = name // + "_FOLDER"
	
	// ----------- ORDER HERE MATTERS -----------
	// create folder if not exists
	if(!dataFolderExists(folderName))
		newDataFolder $foldername
	endif
	
	// duplicate the wav inside the folder
	string imagePath
	sprintf imagePath, "root:%s:%s", folderName, name
	duplicate/o wav, $imagePath
	
	
	if(!paramisDefault(initial_coeff))
		string initialCoeffPath
		sprintf initialCoeffPath, "root:%s:%s", folderName, "initial_coeff"
		duplicate/o initial_coeff, $initialCoeffPath
	endif
	
	print "saved to folder", folderName
end

function fitImageC1S(initial_coeff, src_image, fitType, [start, stop, offset, overclock, sleepTime, quiet, duplicateInFolder])

	wave initial_coeff, src_image
	int start, stop, overclock
	string fitType
	variable offset, sleepTime, quiet, duplicateInFolder
	
	redimension/d initial_coeff 	// make sure to have double element coeff wave	
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	quiet = paramisDefault(quiet) ? 1 : quiet
	
	if(!paramIsDefault(duplicateInFolder))
		duplicate/o initial_coeff $nameofwave(initial_coeff) // duplicate the initial coeff in current folder
	endif
	
	// if initial_coeff wave is 2D then duplicate and split it,
	// the second column is the hold parameters
	if(dimsize(initial_coeff, 1) != 0)
		duplicate/free/rmd=[][1] initial_coeff, holdWave 
		redimension/n=(-1,0) holdWave // and so is holdWave
		print "Generating Hold Parameters"
		svar globalHold = $getglobalString("globalHold", folder = ":options")
		globalHold = wavetoHoldString(holdWave)
	endif
	// Initialize waves
	string name = nameOfWave(src_image) + "_"
	
	duplicate/o src_image $name
	wave image = $name
	wave fit = copy_append(image, "FIT")
	wave coeff = copy_append_coeff(image, initial_coeff, "COEFF") 
	wave sigma = new_append_coeff(image, initial_coeff, "SIGMA")
	string gName, wname, tboxName
	variable i, N, j
   string num, trace
   
   // set def params
   N = dimsize(image, 1)
   start = paramisDefault(start) ? 0 : start
   stop = paramisDefault(stop) ? N : min(stop, N)
   
   // save starting folder
   dfreF startingFolder = getDataFolderDFR()

	// temp graph helpers
	duplicate/o/rmd=[][start] image, $"slice", $"slice_fit"
	redimension/n=(-1,0) $"slice", $"slice_fit"
	wave slice = $moveToFolder(":internal", "slice")
	wave slice_fit = $moveToFolder(":internal", "slice_fit")
	wave slice_coeff = $getGlobalWave("slice_coeff", like = initial_coeff, folder = ":internal")
	redimension/n=(-1,0) slice_coeff // make sure this is 1D
	slice_coeff[] = initial_coeff[p][0]
	
	// CREATE PANEL
	newpanel/W=(0,0,750,450) as name + " Panel"
	KillWindow/Z  $( name + "Panel" )
	DoWindow/C $( name + "Panel" )
	gName = winname(0, 64)
   printf "Created Panel %s\n", gName
   
	// Create the Graphs
   display/host=#/n=sliceFit/w=(0,0,0.60,1)	// SLICE FIT GRAPH
   if(cmpstr(fitType, "multiComp") == 0)
   		fitC1S_comp(slice_coeff, slice, res=slice_fit, wait = 1)
   elseif(cmpstr(fitType, "co") == 0)
   		fitC1S_CO(slice_coeff, slice, res=slice_fit, wait = 1)
   	elseif(cmpstr(fitType, "compAndCO") == 0)
   		fitC1S_compAndCO(slice_coeff, slice, res=slice_fit, wait = 1, quiet=quiet)
   else
   		Printf "Type : %s not supported...\n",fitType
   		i = N // do not enter the loop
   endif
   
 	tboxName = "CF_"				// Put the box up left and
   TextBox/C/N=$tboxName/A=LT/X=2/Y=2  // add two percent of padding to X and Y
   setactiveSubwindow ##
   
   display/host=#/n=image/w=(0.61,0,1,1)	// IMAGE SLICES GRAPH
   appendToGraph slice, slice_fit
   setactiveSubwindow ##
   doUpdate
   
   // check if starting values are correct
   variable didAbort = 0
   didAbort = UserPauseCheck(gname, 5)
   if (didAbort)
   	// go back to root
   	setdataFolder startingFolder
   	return -1
   endif
    
	// loop trough slices
	printf "looping through %d slices\n", N
	printf "starting at %d ending at %d\n", start, min(stop, N)
	if(!paramisDefault(overclock))
		MultiThreadingControl setMode = 8
	endif
	
   for (i = start; i < stop; i++)   
   		if(!quiet)
   			print ""
   			printf "===== FITTING SLICE : %s =====\n", num2str(i) 
   		endif	
   		// load image slice into the waves
   		slice = image[p][i]
   		slice_coeff = coeff[p][i]
   	
   		setactiveSubwindow #sliceFit
   		removefromGraph/all
   	
   		if(cmpstr(fitType, "multiComp") == 0)
   			fitC1S_comp(slice_coeff, slice, res=slice_fit, sleepTime=sleepTime)
   		elseif(cmpstr(fitType, "co") == 0)
   			fitC1S_CO(slice_coeff, slice, res=slice_fit, sleepTime=sleepTime)	
   		elseif(cmpstr(fitType, "compAndCO") == 0)
   			fitC1S_compAndCO(slice_coeff, slice, res=slice_fit, sleepTime=sleepTime, quiet=quiet)
   		else
   			Printf "Type : %s not supported...\n", fitType
   			break // from loop
   		endif
   	
   		// save fit results
   		coeff[][i] = slice_coeff[p]
    	fit[][i] = slice_fit[p]
    	wave w_sigma = $"W_sigma"
    	sigma[][i] = w_sigma[p] // default sigma wave used by FuncFit
    	
    	// update next coeff and save errors
    	if(i < N - 1)
    		coeff[][i + 1] = coeff[p][i]
    	endif
   	
   		// display fit results in tbox and terminal
   		replacetext/n=$tboxName "\f01 Lineshape : DSGN \f00"
		//addEntriesToTBOX(tboxName, coeff, sigma, i=i)
		printcoeff(slice_coeff)
    	setactiveSubwindow ##
    		
    	// update the slices on image graph
    	setactiveSubwindow #image
    	
    	if(!paramisDefault(offset))
    		fit[][i] = fit[p][i] + offset * (N - i)
    	endif
    	
    	num = "#" + num2str(i)
    	appendtograph fit[][i]/tn=$("fit_slice" + num)
    	
    	if (i > start)
    		num = "#" + num2str(i - 1)
    		trace = "'fit_slice" + num + "'"
    		ModifyGraph lsize($trace)=0.9,rgb($trace)=(0,0,0)
    	endif
    	
    	setactiveSubwindow ##
    	doupdate 
	endfor
	
	if(!paramisDefault(overclock))
		MultiThreadingControl setMode = 1
	endif
	
	// one last time 
	setactiveSubwindow #image
	num = "#" + num2str(i - 1)
   trace = "'fit_slice" + num + "'"
	ModifyGraph lsize($trace)=0.9,rgb($trace)=(0,0,0)
	removeFromGraph slice, slice_fit
	setactiveSubwindow ##
    
   // go back to root
   setdataFolder startingFolder
end

function removeAllX(string name)
	name = name[0,9] // drop additional info
	string id = name[2,9]
	
	make/T/free removeItems = {"X", "Y", "Z", "Phi", "Extra", "Theta", "Time", "Energy", "Press", "Temp", "Current" }
	printf "Removing non useful AllX from wave %s with id %s\n" name, id
	
	for(string item : removeItems)
		string itemFullName = item + id
		
		if(!waveExists($itemFullName))
			printf "Error : wave %s not found\n", itemFullName
			continue
		endif
		
		// print "removed", itemFullName
		killwaves $itemFullName
	endfor
end

function copyAllX(string folderPath, string name)
	name = name[0,9] // drop additional info
	string id = name[2,9]
	
	make/T/free moveItems = {"Time", "Energy", "Press", "Temp", "Current"}
	printf "Moving useful AllX from wave %s with id %s to folder %s\n" name, id, folderPath
	
	// create folder if not exists
	if(!dataFolderExists(folderPath))
		print "Error, folder does not exist"
		return -1
	endif
	
	// move the items inside the folder
	for(string item : moveItems)
		string itemFullName = item + id
		
		if(!waveExists($itemFullName))
			printf "Error : wave %s not found\n", itemFullName
			continue
		endif
		
		// print "copied", folderPath + ":" + itemFullName
		duplicate/o $itemFullName, $(folderPath + ":" + itemFullName)
	endfor
end

function startAnalysis(wave image, wave FL)
	string imageName = nameofWave(image)
	string FLName = nameofWave(FL)
	string folderName = imageName	
	string folderPath
	sprintf folderPath, "root:%s", folderName

	if(!dataFolderExists(folderName))
		newDataFolder $folderPath
		newDataFolder $(folderPath + ":initial")
		newDataFolder $(folderPath + ":options")
		newDataFolder $(folderPath + ":internal")
	endif
	
	moveToFolder(folderPath + ":initial", imageName)
	moveToFolder(folderPath + ":initial", FLName)
	copyAllX(folderPath + ":initial", imageName)
	removeAllX(imageName)
	
	setdataFolder folderPath + ":initial"
	// duplicate original image and calibrate it
	// then move it to parent folder
	string id = imageName[2,9]
	string currentName = "Current" + id
	print imageName + "_raw"
	duplicate/o $(imageName) $(imageName + "_raw")
	calibrateImageFLIN(imageName, FLName, currentName)
	movetoFolder(folderPath, imageName)
	
	setdataFolder folderPath
	newimage/K=0 $imageName
	
	setDataFolder root:
	
end

function calibrateImageFLIN(string imageName, string FLName, string currentName)
	// Calibrates an image using
	// - reference FL for image
	// - corrects scaling
	// - normalizes intensity using current in nA

	wave image = $imageName
	wave FL = $FLName
	wave current = $currentName
	
	printf "Calibrating %s with FL %s\n", imageName, FLName

	variable delta = dimdelta(image, 0)
	variable offset = dimoffset(image,0)
	
	if(offset < 0)
		print "Something is not right..."
		print "offset is < 0, aborting\n"
		return -1
	endif
	
	display FL
	CurveFit/W=0 Sigmoid, FL/D
	
	// get results
	wave coeff = $"W_coef"
	variable xhalf = coeff[2]
	SetScale/P x -(offset - xhalf),-delta,"eV", image // correct scaling
	variable vCurr = mean(current) / 1e-9 // normalize for current in nA
	image = image / vCurr
	
	printf "calibrated for xhalf : %.3f, curr : %.3f nA\n", xhalf, vCurr
	
end