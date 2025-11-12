#include ":utils"

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

function fitImageC1S(initial_coeff, src_image, fitType, [start, stop, offset, overclock])

	wave initial_coeff, src_image
	int start, stop, overclock
	string fitType
	variable offset
	
	redimension/d initial_coeff 	// make sure to have double element coeff wave	
		
	// Prepare working folder
	string name = nameOfWave(src_image)
	string folderName = name + "_FOLDER"
	createFolder(src_image, initial_coeff = initial_coeff)
	setDataFolder $folderName
	
	// Initialize waves
	wave image = $name
	wave fit = copy_append(image, "_FIT")
	wave coeff = copy_append_coeff(image, initial_coeff, "_COEFF") 
	wave sigma = new_append_coeff(image, initial_coeff, "_SIGMA")
	string gName, wname, tboxName
	variable i, N, j
   string num, trace
   
   // set def params
   N = dimsize(image, 1)
   if(paramisDefault(start))
   	start = 0
   endif
	if(paramisDefault(stop))
   	stop = N
   else 
   	stop = min(stop, N)
   endif
	
	// temp graph helpers
	duplicate/o initial_coeff slice_coeff
	duplicate/o/rmd=[][start] image, slice, slice_fit
	redimension/n=(-1,0) slice, slice_fit
	
	// CREATE PANEL
	newpanel/W=(0,0,750,450) as name + " Panel"
	KillWindow  $( name + "Panel" )
	DoWindow/C $( name + "Panel" )
	gName = winname(0, 64)
   printf "Created Panel %s\n", gName
   
	// Create the Graphs
   display/host=#/n=sliceFit/w=(0,0,0.60,1)	// SLICE FIT GRAPH
   appendToGraph slice, slice_fit
   
   if(cmpstr(fitType, "multiComp") == 0)
   	fitC1S_comp(slice_coeff, slice, res=slice_fit, wait = 1)
   elseif(cmpstr(fitType, "co") == 0)
   	fitC1S_CO(slice_coeff, slice, res=slice_fit, wait = 1)
   else
   	Printf "Type : %s not supported...\n",fitType
   	i = N // do not enter the loop
   endif
   
   //slice_fit = DsgnmBad2_MTHR(initial_coeff, x)
 	tboxName = "CF_" + wname					// Put the box up left and
   TextBox/C/N=$tboxName/A=LT/X=2/Y=2  // add two percent of padding to X and Y
   setactiveSubwindow ##
   
   display/host=#/n=image/w=(0.61,0,1,1)		// IMAGE SLICES GRAPH
   appendToGraph slice, slice_fit
   setactiveSubwindow ##
   
   doUpdate
   // check if starting values are correct
   variable didAbort = 0
   didAbort = UserPauseCheck(gname, 5)
   if (didAbort)
   	// go back to root
   	setdataFolder "root:"
   	return -1
   endif
    
	// loop trough slices
	printf "looping through %d slices\n", N
	printf "starting at %d ending at %d\n", start, min(stop, N)
	if(!paramisDefault(overclock))
		MultiThreadingControl setMode = 8
	endif
	
   for (i = start; i < stop; i++)   	
   	// load image slice into the waves
   	slice = image[p][i]
   	slice_coeff = coeff[p][i]
   	
   	setactiveSubwindow #sliceFit
   	removefromGraph/all
   	
   	if(cmpstr(fitType, "multiComp") == 0)
   		fitC1S_comp(slice_coeff, slice, res=slice_fit)
   	elseif(cmpstr(fitType, "co") == 0)
   		fitC1S_CO(slice_coeff, slice, res=slice_fit)	
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
   setdataFolder "root:"
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
	
	newimage/K=0 image
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