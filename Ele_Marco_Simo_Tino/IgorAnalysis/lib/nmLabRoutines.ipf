#include ":utils"
#include ":FitControlPackage"



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

function updateAndSleep(variable t)
	if(t > 0)
		doupdate
		sleep/b/s t
	endif
end




function fitC1S_CO(coeff, src, [res, wait, dbg, sleepTime])
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
	variable sleepTime
	
	duplicate/o src C1S, CO, mask
	duplicate/free coeff tcoeff startingCoeff delta
	
	if(paramisDefault(res))
		duplicate/o src res
	endif
	
	if (paramIsDefault(sleepTime))
		sleepTime = 0.2
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
	updateAndSleep(sleepTime)
	
	if(!paramisDefault(wait))
		return 0
	endif
	
	execute "mask(-285.76, -282) = 0"
	Make/O/T/free constrains={\
		"K2 > 0.08",\
		"K2 < 0.14",\
		"K3 > 0.24",\
		"K4 > 0.18",\
		"K4 < 0.26",\
		"K6 < -286.4",\
		"K6 > -287.6"\
	}
	string hold="0000000"
	// try to fit only position and intensity
	FuncFit/Q/N=0/h=hold Dsgn_MTHR coeff[0,6] src /M=mask/c=constrains
	CO = Dsgn_MTHR(tcoeff, x)
	updateAndSleep(sleepTime)
	
	
	if(coeff[5] < 14) // no peak found, so hold the intensity to zero
		coeff[5] = 0.1
		hold = "001111111101"
	else // peak found, so feel free to keep fitting it
		FuncFit/Q/N=0 Dsgn_MTHR coeff[0,6] src /M=mask/c=constrains
		hold = "001110111101"	
		
	endif
	
	tcoeff = coeff
	tcoeff[10] = 0
	tcoeff[0,6] = coeff[p]
	CO = Dsgn_MTHR(tcoeff, x)
	C1S = src - CO
	updateAndSleep(sleepTime)
	
	// only fit C1S
	FuncFit/Q/N=2 dsgnnb_MTHR coeff[7,11], C1S
	updateAndSleep(sleepTime)
	
	// allow lineshape parameter to vary only by 10 %
	//make/free toVarySlowly = {2,3,4,7,8,9}
	make/free toVarySlowly = {2,3,4,6,7,8,9,11}
	delta =  (coeff - startingCoeff) * 0.1
	for(int i : toVarySlowly)
		coeff[i] = startingCoeff[i] + delta[i]
	endfor
	
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
	
	// ----------- ORDER HERE MATTERS -----------
	// create folder if not exists
	if(!dataFolderExists(folderName))
		newDataFolder $foldername
	endif
	
	// duplicate the image inside the folder
	sprintf imagePath, "root:%s:%s", folderName, name
	sprintf initialCoeffPath, "root:%s:%s", folderName, "initial_coeff"
	print "saving to folder", folderName
	duplicate/o image, $imagePath
	duplicate/o initial_coeff, $initialCoeffPath
	
end


function fitImageC1S(initial_coeff, src_image, [start, stop, offset, overclock])

	wave initial_coeff, src_image
	int start, stop, overclock
	variable offset
	
	redimension/d initial_coeff 	// make sure to have double element coeff wave	
		
	// Initialize folders
	newDataFolder 
	newDataFolder options
	newDataFolder internals
	newDataFolder inputs
	
	string name = nameOfWave(src_image)
	string folderName = name + "_FOLDER"
	prepareFolder(initial_coeff, src_image)
	setDataFolder $folderName
	
	
	// Initialize global variables
	nvar i = $GetGlobalVar("G_vSliceCounter")
	nvar N = $GetGlobalVar("G_vNumSlices")
	wave fit = copy_append(image, "_FIT")
	wave resid = copy_append(image, "_RES")
	wave coeff = copy_append_coeff(image, initial_coeff, "_COEFF") 
	wave sigma = new_append_coeff(image, initial_coeff, "_SIGMA")
	
	wave image = $name
	string gName, wname, tboxName
	variable j
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
   
   i = start
	
	// temp graph helpers
	duplicate/o initial_coeff slice_coeff
	duplicate/o/rmd=[][start] image, slice, slice_fit
	redimension/n=(-1,0) slice, slice_fit
	
	// CREATE PANEL
	newpanel/W=(0,0,850,500) as name + " Panel"
	KillWindow  $( name + "Panel" )
	DoWindow/C $( name + "Panel" )
	gName = winname(0, 64)
   printf "Created Panel %s\n", gName
   
   newpanel/W=(0,0,300,500)/ext=0/host=#/n=FitControlPanel as "Fit Control"
   initFitControlPanel(slice_coeff)
   setactiveSubwindow ##
   
	// Create the Graphs
	// 1) SLICE FIT GRAPH
   display/host=#/n=sliceFit/w=(0,0,0.50,0.8)	
   appendToGraph slice, slice_fit
   slice_fit = DsgnmBad2_MTHR(initial_coeff, x)
 	tboxName = "CF_" + wname					// Put the box up left and
   TextBox/C/N=$tboxName/A=LT/X=2/Y=2  // add two percent of padding to X and Y
   setactiveSubwindow ##
   // 2) IMAGE SLICES GRAPH
   display/host=#/n=image/w=(0.50,0,0.75,0.8)		
   appendToGraph slice, slice_fit
   setactiveSubwindow ##
   // 3) RESID GRAPH
   display/host=#/n=resid/w=(0.75,0,1,0.8)		
   setactiveSubwindow ##
   
   // UI
   SetActiveSubwindow #FitControlPanel
   setactiveSubwindow ##
end

function FitLoop(string sImage)

	// Initialize global variables
	nvar i 		= $GetGlobalVar("vSliceCounter")
	nvar N   	= $GetGlobalVar("vNumSlices")
	nvar start 	= $GetGlobalVar("vStart")
	nvar stop 	= $GetGlobalVar("vStop")
	nvar offset = $GetGlobalVar("vOffset")
	wave fit 	= $GetGLobalWave(sImage + "_FIT")
	wave resid 	= $GetGLobalWave(sImage + "_RES")
	wave coeff 	= $GetGLobalWave(sImage + "_COEFF") 
	wave sigma 	= $GetGLobalWave(sImage + "_SIGMA")
	
	// initialize locals
	wave slice, image, slice_coeff, slice_fit
	string tBoxName, num, trace
	
	// loop trough slices
	printf "looping through %d slices\n", N
	printf "starting at %d ending at %d\n", start, min(stop, N)
	
	
   for (i = start; i < stop; i = i+1)   	
   	
   	// load image slice into the waves
   	slice = image[p][i]
   	slice_coeff = coeff[p][i]
   	
   	setactiveSubwindow #sliceFit
   	removefromGraph/all
   	fitC1S_CO(slice_coeff, slice, res=slice_fit)
   	//fitC1S_comp(slice_coeff, slice, res=slice_fit)
   	
   	// save fit results
   	coeff[][i] = slice_coeff[p]
    	fit[][i] = slice_fit[p]
    	wave w_sigma = $"W_sigma"
    	sigma[][i] = w_sigma[p] // default sigma wave used by FuncFit
    	resid[][i] = slice[p] - slice_fit[p]
    	
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
    	num = "#" + num2str(i)
    	setactiveSubwindow #image	
    	
    	appendtograph fit[][i]/tn=$("fit_slice" + num)
    	if (i > start)
    		num = "#" + num2str(i - 1)
    		trace = "'fit_slice" + num + "'"
    		ModifyGraph lsize($trace)=0.9,rgb($trace)=(0,0,0)
    	endif
    	setactiveSubwindow ##
    	
    	setactiveSubwindow #resid
    	appendtograph resid[][i]/tn=$("resid_slice" + num)
    	if (i > start)
    		num = "#" + num2str(i - 1)
    		trace = "'resid_slice" + num + "'"
    		ModifyGraph lsize($trace)=0.9,rgb($trace)=(0,0,0)
    	endif
    	setactiveSubwindow ##
    	doupdate 
	endfor
	
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
