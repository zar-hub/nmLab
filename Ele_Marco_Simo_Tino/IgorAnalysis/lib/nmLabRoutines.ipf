#include ":utils"



function/wave getSlice(image, i)
	wave image
	variable i
	
	string name, new 
	name = nameofWave(image)
	new = name + "_slice" + num2str(i)
	
	// duplicate also copies the scaling
	duplicate/o/rmd=[][i] image $new 
	
	// redimention to get a 1D wave
	redimension/n=(-1,0) $new
	return $new
	
	// Maybe this is another way to do it using copyscale
	//	Make/o/n=(N) fitres
	//	copyscales/P image fitres
end



function sliceImage(image, offset)
	wave image 
	variable offset
	
	variable N = dimsize(image, 0)
	variable i
	
	// duplicate the image to get the slices
	wave imageSlices = copy_append(image, "_slices")
	
	display
	for(i=0; i<dimSize(image, 1); i++)
		imageSlices[][i] = imageSlices[p][i] + offset * i
		appendtoGraph/c=(0,0,0) imageSlices[][i]
	endfor
end



Function UserPauseCheck(graphName, autoAbortSecs)
	String graphName
	Variable autoAbortSecs
	
	DoWindow/F $graphName // Bring graph to front
	if (V_Flag == 0) // Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	
	NewPanel /K=2 /W=(187,368,437,531) as "Pause for Cursor"
	DoWindow/C tmp_PauseforCursor // Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$graphName // Put panel near the graph
	DrawText 21,20,"Check if valid initial parameters"
	DrawText 21,40,"then click continue or abort."
	Button button0,pos={80,58},size={92,20},title="Continue"
	Button button0,proc=UserPauseCheck_ContButtonProc
	
	Variable didAbort= 0

	if( autoAbortSecs == 0 )
		PauseForUser tmp_PauseforCursor,$graphName
	else
		SetDrawEnv textyjust= 1
		DrawText 162,103,"sec"
		SetVariable sv0,pos={48,97},size={107,15},title="Aborting in "
		SetVariable sv0,limits={-inf,inf,0},value= _NUM:10
		Variable td= 10,newTd
		Variable t0= ticks
		Do
			newTd= autoAbortSecs - round((ticks-t0)/60)
			if( td != newTd )
				td= newTd
				SetVariable sv0,value= _NUM:newTd,win=tmp_PauseforCursor
				if( td <= 10 )
					SetVariable sv0,valueColor= (65535,0,0),win=tmp_PauseforCursor
				endif
			endif
			if( td <= 0 )
				DoWindow/K tmp_PauseforCursor
				didAbort= 1
				break
			endif
			PauseForUser/C tmp_PauseforCursor,$graphName
		while(V_flag)
	endif
	return didAbort
end



Function UserPauseCheck_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K tmp_PauseforCursor // Kill panel
End



function fitC1S_simple(coeff, src, [res])
	// Expects an open graph to plot the fit process to.
	// Data is appended to default axis names, so one should 
	// leave them for this function to handle and plot to other 
	// axis in the same graph.
	wave coeff, src, res
	string name = nameofWave(src)
	
	if(paramisDefault(res))
		duplicate/o src res
		
	endif

	FuncFit/Q/N=2 dsgn_MTHR coeff, src
	appendtoGraph src, res
end



function fitC1S_comp(coeff, src, [res, wait, dbg])
	// Expects an open graph to plot the fit process to.
	// Data is appended to default axis names, so one should 
	// leave them for this function to handle and plot to other 
	// axis in the same graph.
	wave coeff, src, res
	int wait, dbg
	string name = nameofWave(src)
	
	if(paramisDefault(res))
		duplicate/o src res
	endif
	
	if(!paramisDefault(dbg))
		display 			// enable when debugging
	endif
	
	duplicate/o src, C1, C2, C3
	appendtoGraph src, res, C1, C2, C3
	duplicate/free coeff tcoeff
	ModifyGraph lsize(res)=1.3,rgb(res)=(1,16019,65535)
	ModifyGraph lsize(C1)=1.3,rgb(C1)=(0,65535,0),lsize(C2)=1.3,rgb(C2)=(65535,43690,0),lsize(C3)=1.3,rgb(C3)=(65535,0,52428)
	ModifyGraph mode(C1)=7,usePlusRGB(C1)=1,hbFill(C1)=2,plusRGB(C1)=(3,52428,1,16384),mode(C2)=7,usePlusRGB(C2)=1,hbFill(C2)=2,plusRGB(C2)=(52428,34958,1,16384),mode(C3)=7,usePlusRGB(C3)=1,hbFill(C3)=2,plusRGB(C3)=(52428,1,41942,16384)
	
	// components
	tcoeff = coeff
	tcoeff[0,1] = 0
	tcoeff[7] = 0
	tcoeff[9] = 0
	C1 = dsgnmBas_MTHR(tcoeff, x)
	tcoeff = coeff
	tcoeff[0,1] = 0
	tcoeff[5] = 0
	tcoeff[9] = 0
	C2 = dsgnmBas_MTHR(tcoeff, x)
	tcoeff = coeff
	tcoeff[0,1] = 0
	tcoeff[5] = 0
	tcoeff[7] = 0
	C3 = dsgnmBas_MTHR(tcoeff, x)
	
	res = dsgnmBas_MTHR(coeff, x)
	
	if(!paramisDefault(wait))
		return 0
	endif

	FuncFit/Q/N=2 dsgnmBas_MTHR coeff, src
end



function fitC1S_CO(coeff, src, [res, wait, dbg])
	// Expects an open graph to plot the fit process to.
	// Data is appended to default axis names, so one should 
	// leave them for this function to handle and plot to other 
	// axis in the same graph.
	
	// filosophy:
	// lineshape cannot change much... it should be 
	// almost a constant. 
	// We let the shape vary slightly from the initial
	// coeff, say 2%.
	
	wave coeff, src, res
	int wait, dbg
	
	duplicate/o src C1S, CO, mask
	duplicate/free coeff tcoeff
	
	if(paramisDefault(res))
		duplicate/o src res
	endif

	// plot stuff in case wait is true
	res = dsgnmBad2_MTHR(coeff, x)
	tcoeff = coeff
	tcoeff[0,1] = 0
	tcoeff[10] = 0
	CO = dsgnmBad2_MTHR(tcoeff, x)
	tcoeff = coeff
	tcoeff[0,1] = 0
	tcoeff[5] = 0
	C1S = dsgnmBad2_MTHR(tcoeff, x)
	
	if(!paramisDefault(dbg))
		display 			// enable when debugging
	endif

	string resname = nameofWave(res) // res can be named outside of this funciton
	appendtoGraph src, res, mask, CO, C1S
	ModifyGraph lsize($resname)=1.3,rgb($resname)=(0,0,65535)
	ModifyGraph mode(CO)=7,lsize(CO)=1.3,rgb(CO)=(1,34817,52428)
	ModifyGraph hbFill(CO)=2, plusRGB(CO)=(1,34817,52428,16384), usePlusRGB(CO)=1
	ModifyGraph mode(C1S)=7,lsize(C1S)=1.3,rgb(C1S)=(36873,14755,58982)
	ModifyGraph hbFill(C1S)=2,plusRGB(C1S)=(36873,14755,58982,16384), usePlusRGB(C1S)=1
	
	if(!paramisDefault(wait))
		return 0
	endif
	
	execute "mask(-285.76, -282) = 0"
	Make/O/T/free constrains={"K4 > 0.01", "K6 < -286.4", "K6 > -287.6", "K3 > 0.01"}
	string hold="0011100"
	// try to fit only position and intensity
	FuncFit/Q/N=2/h=hold Dsgn_MTHR coeff[0,6] src /M=mask// /c=constrains
	
	if(coeff[5] < 10) // no peak found, so hold the intensity to zero
		coeff[5] = 0
		hold = "001111111101"
	else // peak found, so feel free to keep fitting it
		FuncFit/Q/N=2 Dsgn_MTHR coeff[0,6] src /M=mask/c=constrains
		hold = "001110111101"	
	endif
	
	tcoeff = coeff
	tcoeff[10] = 0
	tcoeff[0,6] = coeff[p]
	CO = Dsgn_MTHR(tcoeff, x)
	C1S = src - CO
	
	// only fit C1S
	FuncFit/Q/N=2 dsgnnb_MTHR coeff[7,11], C1S
	
	// fit both
	FuncFit/h=hold/Q/N=2 dsgnmBad2_MTHR coeff src
	
	// update stuff again
	removefromGraph mask
	res = dsgnmBad2_MTHR(coeff, x)
	tcoeff = coeff
	tcoeff[0,1] = 0
	tcoeff[10] = 0
	CO = dsgnmBad2_MTHR(tcoeff, x)
	tcoeff = coeff
	tcoeff[0,1] = 0
	tcoeff[5] = 0
	C1S = dsgnmBad2_MTHR(tcoeff, x)
end


function prepareFolder(wave initial_coeff, wave image)

	// names
	string name = nameOfWave(image)
	string folderName = name + "_FOLDER"
	string imagePath, initialCoeffPath
	
	
	DFREF saveDFR = GetDataFolderDFR()			// Save
	// ----------- ORDER HERE MATTERS -----------
	// create folder if not exists
	if(!dataFolderExists(folderName))
		newDataFolder $foldername
	endif
	
	// duplicate the image inside the folder
	sprintf imagePath, "root:%s:%s", folderName, name
	sprintf initialCoeffPath, "root:%s:%s", folderName, "initial_coeff"
	print "saving to folder", imagePath
	duplicate/o image, $imagePath
	duplicate/o initial_coeff, $initialCoeffPath
	
	// go into the folder and
	// create other waves 
	setDataFolder $folderName
	wave image = $name
	wave fit = copy_append(image, "_FIT")
	wave coeff = copy_append_coeff(image, initial_coeff, "_COEFF") 
	wave sigma = new_append_coeff(image, initial_coeff, "_SIGMA")
	// --------- END ORDER HERE MATTERS ----------
	SetDataFolder saveDFR							// and restore
end

function fitImageC1S(initial_coeff, src_image, [start, stop, offset, overclock])

	wave initial_coeff, src_image
	int start, stop, overclock
	variable offset
	
	redimension/d initial_coeff 	// make sure to have double element coeff wave	
		
	// Prepare working folder
	string name = nameOfWave(src_image)
	string folderName = name + "_FOLDER"
	prepareFolder(initial_coeff, src_image)
	setDataFolder $folderName
	
	// Initialize waves
	wave image = $name
	wave fit = $(name + "_FIT")
	wave coeff = $(name + "_COEFF") 
	wave sigma = $(name + "_SIGMA")
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
   endif
	
	// temp graph helpers
	duplicate/o initial_coeff slice_coeff
	duplicate/o/rmd=[][0] image, slice, slice_fit
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
   slice_fit = DsgnmBad2_MTHR(initial_coeff, x)
 	tboxName = "CF_" + wname					// Put the box up left and
   TextBox/C/N=$tboxName/A=LT/X=2/Y=2  // add two percent of padding to X and Y
   setactiveSubwindow ##
   
   display/host=#/n=image/w=(0.61,0,1,1)		// IMAGE SLICES GRAPH
   appendToGraph slice, slice_fit
   setactiveSubwindow ##
    
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
	
   for (i = start; (i < N) & (i < stop); i++)   	
   	
   	// load image slice into the waves
   	slice = image[p][i]
   	slice_coeff = coeff[p][i]
   	
   	setactiveSubwindow #sliceFit
   	removefromGraph/all
   	
   	// fitC1S_CO(slice_coeff, slice, res=slice_fit)
   	
   	fitC1S_comp(slice_coeff, slice, res=slice_fit)
   	
   	// save fit coeffs
   	coeff[][i] = slice_coeff[p]
   	wave w_sigma = $"W_sigma"
    	sigma[][i] = w_sigma[p] // default sigma wave used by FuncFit
   	
   	// display fit results
   	replacetext/n=$tboxName "\f01 Lineshape : DSGN \f00"
		//addEntriesToTBOX(tboxName, coeff, sigma, i=i)
		printcoeff(slice_coeff)
    	setactiveSubwindow ##
    		
   	// update next coeff and save errors
    	if(i < N - 1)
    		coeff[][i + 1] = coeff[p][i]
    	endif
    	
    	// make a nice graph
    	num = "#" + num2str(i)
    	
    	// ?
    	slice = image[p][i]
    	//slice_fit = dsgnmBad2_MTHR(slice_coeff, x)
    	fit[][i] = slice_fit[p]
    	
    	if(!paramisDefault(offset))
    		fit[][i] = fit[p][i] + offset * (N - i)
    	endif
    	
    
    	setactiveSubwindow #image
    	appendtograph fit[][i]/tn=$("fit_slice" + num)
    	
    	if (i > 0)
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