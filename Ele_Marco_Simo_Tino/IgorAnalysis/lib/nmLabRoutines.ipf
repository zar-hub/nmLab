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

function createWavesC1S_simple(wave image)

end


function fitC1S_simple(wave image, int i)
	string name = nameofWave(image)
	wave fit = $(name + "_FIT")
	wave coeff = $(name + "_COEFF")
	wave sigma = $(name + "_SIGMA")
	
	FuncFit/TBOX=768/Q/N=2 dsgn_MTHR coeff[][i], image[][i] /d=fit[][i]
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
	DrawText 21,20,"Adjust the cursors and then"
	DrawText 21,40,"Click Continue."
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

function fitC1S_CO(wave image, int i)
	string name = nameofWave(image)
	wave fit = $(name + "_FIT")
	wave coeff_C1S = $(name + "_COEFF_C1S")
	wave sigma_C1S = $(name + "_SIGMA_C1S")
	wave coeff_CO = $(name + "_COEFF_CO")
	wave sigma_CO = $(name + "_SIGMA_CO")
	
	duplicate/o/rmd=[][i] image slice, mask
	redimension/n=(-1,0) slice, mask
	
	execute "mask(-285.76, ) = 0"
	
	display slice, mask
	
	FuncFit/TBOX=768/x Dsgn_MTHR coeff_CO[][i] slice /M=mask/D
	
	//FuncFit/TBOX=25/N=2/Q dsgn_MTHR coeff[][i], image[][i] /d=fit[][i]
end





function fitImageC1S(wave initial_coeff, wave src_image)
	
	// names
	string name = nameOfWave(src_image)
	string folderName = name + "_FOLDER"
	string imagePath 
	string gName, wname, tboxName
	
	
	// ----------- ORDER HERE MATTERS -----------
	
	
	// create folder if not exists
	if(!dataFolderExists(folderName))
		newDataFolder $foldername
	endif
	
	// duplicate the image inside the folder
	sprintf imagePath, "root:%s:%s", folderName, name
	print "saving to folder", imagePath
	duplicate/o src_image, $imagePath
	
	// go into the folder
	setDataFolder $folderName
	
	// create other waves in the folder
	wave image = $name
	wave fit = copy_append(image, "_FIT")
	wave coeff = copy_append_coeff(image, initial_coeff, "_COEFF") 
	wave sigma = new_append_coeff(image, initial_coeff, "_SIGMA")
	
	// --------- END ORDER HERE MATTERS ----------
	
	// temp graph helpers
	duplicate/free initial_coeff, tcoeff, tsigma
	duplicate/rmd=[][0] image, slice 
	redimension/n=(-1,0) slice 
	
	// create the graph if not open
    display/n=name/w=(0,0,600,300)
    gName = winname(0, 1)
    wname = nameOfWave(image)
    
    // Put the box up left
 	tboxName = "CF_" + wname
    // TextBox/C/N=$tboxName/A=LT/X=3.52/Y=4.69
    
    variable i, N, j
    string num, trace
    N = dimsize(image, 1)
    
    // create a graph to check
    fit[][0] = Dsgn_MTHR(initial_coeff, x)
    appendToGraph slice, fit[][0]
    
    
    // check if starting values are correct
    variable didAbort = 0
    didAbort = UserPauseCheck(gname, 5)
    if (didAbort)
    	// go back to root
    	setdataFolder "root:"
    	return -1
    endif
    
    // reset graph
    removefromGraph/all
    appendToGraph slice
    
    // loop trough slices
    for (i = 0; i < N; i++)   	
    	// fit stuff
    	fitC1S_simple(image, i)
    		
   	// update next coeff and save errors
    	if(i < N - 1)
    		coeff[][i + 1] = coeff[p][i]
    		wave W_sigma = $"W_sigma"
    		sigma[][i] = W_sigma[p] // default sigma wave used by FuncFit
    	endif
    	
    	// make a nice graph
    	num = "#" + num2str(i)
    	
    	//appendtograph image[][i]/tn=$("slice" + num)
    	slice = image[p][i]
    	// fit[][i] = fit[p][i] + 13 * (N - i)
    	appendtograph fit[][i]/tn=$("fit_slice" + num)
    	tcoeff = coeff[p][i]
    	tsigma = sigma[p][i]
    	
    	//addEntriesToTBOX(tboxName, tcoeff, tsigma)
    	
    	if(i>2)
    		num = "#" + num2str(i - 3)
    		trace = "'slice" + num + "'"
    		ModifyGraph lsize($trace)=0.7,rgb($trace)=(13107,13107,13107)
    		trace = "'fit_slice" + num + "'"
    		ModifyGraph lsize($trace)=0.9,rgb($trace)=(0,0,0)
    	endif
    	
    	doupdate
    endfor
    
    // go back to root
    setdataFolder "root:"
end