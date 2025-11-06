function editCoeffListBox(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	
	Variable row = lba.row
   Variable col = lba.col
   WAVE/T/Z listWave = lba.listWave
   WAVE/Z selWave = lba.selWave
   
   SVAR s_edit=$getGlobalVar("G_sEdit")
   SVAR sCoeffName=$getGlobalVar("G_sCoeffName")
   wave slice_coeff = $sCoeffName
   
   switch( lba.eventCode )
        case -1: // control being killed
            break
        case 1:
            //selWave[][1,2][0]=selWave & ~1
            // stop edit when cell loses focus
            // so that bg color is visible
            break
        case 6: // begin edit
            s_edit=listWave[row][col]
            break
        case 7: // finish edit
        		if(col == 0) // save only when col > 0
        			break
        		endif
        	
				if(numtype(str2num(listWave[row][col]))==2)
                    listWave[row][col]=s_edit
                else
                    listWave[row][col]=num2str(str2num(listWave[row][col]))	
                endif
            break
    endswitch
 
    return 0
end

// wrapper for buttons
function procFitControlButtons(ba)
    STRUCT WMButtonAction &ba
    
    wave	/T w_coeffList =	:PANELCTL:w_waveselection
    wave 	w_selection =		:PANELCTL:w_selection
    
    switch( ba.eventCode )
        case 2: // mouse up     
            if(stringmatch(ba.ctrlName, "buttonMainAction")) 
            	
            endif
            break
        case -1: // control being killed
            break
    endswitch
 
    return 0
end


function initFitControlPanel(fit_coeff)
	wave fit_coeff
	
	// Initialize global variables
	nvar i_slice = 	$getGlobalVar("G_vSliceCounter")
	nvar N_slice = 	$getGlobalVar("G_vNumSlices")
	SVAR sCoeffName =	$getGlobalVar("G_sCoeffName")
	sCoeffName = nameofWave(fit_coeff)

	// Initialize local variables
	variable i, N_coeff = dimsize(fit_coeff, 0)
	string cName
	
	newDataFolder/o		PANELCTL
	make/o/n=5/T 		:PANELCTL:w_titles 		/wave=w_titles
	make/o/n=(0,5)/T  :PANELCTL:w_coeffList 	/wave=w_coeffList
	make/o/n=(0,5) 	:PANELCTL:w_selection 	/wave=w_selection
   w_titles={"name","value","min","max","% of Δ"}
	
	// init fit procedure controls
   Button buttonStart,size={54.00,20.00},title="Start"
   Button buttonStop,size={54.00,20.00},title="Stop"
   Button buttonStep,size={54.00,20.00},title="Step"
   Button buttonUpdateGraph,size={54.00,20.00},title="Draw"
   SetVariable slice title="current slice",value=i_slice
   SetVariable slice bodyWidth=40, pos={0,30}
   
   listBox listBoxCoeff, mode=6, widths={25,50,25,25,25}, pos={0, 60}
   listBox listBoxCoeff, size={275, 200}, editstyle=1
   listBox listBoxCoeff, listwave=w_coeffList, titlewave=w_titles
   listBox listBoxCoeff, selwave=w_selection
   listBox listBoxCoeff, proc=editCoeffListBox
   
	// populate coeff list
	for(i=0;i<N_coeff;i=i+1)
		cName = "K" + num2str(i)
		w_coeffList[i][0] = cName
		w_coeffList[i][1] = num2str(fit_coeff[i])
		w_coeffList[i][2,4] ={{"2"},{"5"},{"1"}}
		w_selection[i][] = {{0x80},{2},{2},{2},{2}}
	endfor	
end

