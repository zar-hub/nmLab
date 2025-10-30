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


function fitC1S_CO(wave image, int i)

	string name = nameofWave(image)
	string tboxName
	wave fit = $(name + "_FIT")
	wave coeff = $(name + "_COEFF")
	wave sigma = $(name + "_SIGMA")
	
	
	duplicate/o/rmd=[][i] image slice, mask
	redimension/n=(-1,0) slice, mask
	
	execute "mask(-285.76, ) = 0"
	
	display slice, mask
	
	FuncFit/TBOX=768/x Dsgn_MTHR coeff_CO[][i] slice /M=mask/D
	
	//FuncFit/TBOX=25/N=2/Q dsgn_MTHR coeff[][i], image[][i] /d=fit[][i]
end





function fitImageC1S(wave initial_coeff, wave src_image, [ variable offset ])
	
	// names
	string name = nameOfWave(src_image)
	string folderName = name + "_FOLDER"
	string imagePath, initialCoeffPath
	string gName, wname, tboxName
	
	// ----------- ORDER HERE MATTERS -----------
	
	// create folder if not exists
	if(!dataFolderExists(folderName))
		newDataFolder $foldername
	endif
	
	// duplicate the image inside the folder
	sprintf imagePath, "root:%s:%s", folderName, name
	sprintf initialCoeffPath, "root:%s:%s", folderName, "initial_coeff"
	print "saving to folder", imagePath
	duplicate/o src_image, $imagePath
	duplicate/o initial_coeff, $initialCoeffPath
	
	// go into the folder and
	// create other waves 
	setDataFolder $folderName
	wave image = $name
	wave fit = copy_append(image, "_FIT")
	wave coeff = copy_append_coeff(image, initial_coeff, "_COEFF") 
	wave sigma = new_append_coeff(image, initial_coeff, "_SIGMA")
	
	// --------- END ORDER HERE MATTERS ----------
	
	// temp graph helpers
	duplicate/o initial_coeff slice_coeff
	duplicate/o/rmd=[][0] image, slice, slice_fit
	redimension/n=(-1,0) slice, slice_fit
	
	// CREATE PANEL
	newpanel/W=(0,0,750,400) as name + " Panel"
	DoWindow/C $( name + "Panel" )
	gName = winname(0, 64)
   printf "Created Panel %s", gName
	// create the graph if not open
   display/host=#/n=sliceFit/w=(0,0,0.60,1)
   appendToGraph slice, slice_fit
   
   // Put the box up left
   // add two percent of padding to X and Y
 	tboxName = "CF_" + wname
   TextBox/C/N=$tboxName/A=LT/X=2/Y=2
   setactiveSubwindow ##
   
   display/host=#/n=image/w=(0.61,0,1,1)
   appendToGraph slice, slice_fit
   setactiveSubwindow ##
    
   variable i, N, j
   string num, trace
   N = dimsize(image, 1)
    
   // create a graph to check
   slice_fit = Dsgn_MTHR(initial_coeff, x)
   
   
   //
   // appendToGraph/b=bImage/l=lImage slice, slice_fit
   //ModifyGraph freePos(lImage)={0.65,kwFraction}
   //ModifyGraph axisEnab(bImage)={0.65,1},freePos(bImage)=0
   //ModifyGraph axisEnab(bottom)={0,0.55}
   
   // check if starting values are correct
   variable didAbort = 0
   didAbort = UserPauseCheck(gname, 5)
   if (didAbort)
   	// go back to root
   	setdataFolder "root:"
   	return -1
   endif
    
    
	// loop trough slices
	printf "looping through %d slices", N
   for (i = 0; i < N; i++)   	
   	// fit stuff
   	
   	slice = image[p][i]
   	slice_coeff = coeff[p][i]
   	
   	setactiveSubwindow #sliceFit
   	removefromGraph/all
   	fitC1S_simple(slice_coeff, slice, res=slice_fit)
   	
   	
   	// save fit coeffs
   	coeff[][i] = slice_coeff[p]
   	replacetext/n=$tboxName "\f01 Lineshape : DSGN \f00"
		addEntriesToTBOX(tboxName, coeff, sigma, i=i)
    	setactiveSubwindow ##
    		
   	// update next coeff and save errors
    	if(i < N - 1)
    		coeff[][i + 1] = coeff[p][i]
    		wave w_sigma = $"W_sigma"
    		sigma[][i] = w_sigma[p] // default sigma wave used by FuncFit
    	endif
    	
    	// make a nice graph
    	num = "#" + num2str(i)
    	
    	slice = image[p][i]
    	slice_fit = dsgn_MTHR(slice_coeff, x)
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