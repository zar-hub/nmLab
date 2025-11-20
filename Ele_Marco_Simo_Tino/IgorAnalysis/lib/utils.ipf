// === UTILITY FUNCTIONS ===
function updateAndSleep(variable t)
	if(t > 0)
		doupdate
		sleep/b/s t
	endif
end

function/s getGlobalWave(string name, [wave like])
	WAVE/Z w = $"name" 
	if(!WaveExists(w)) // create it
		if (!paramIsDefault(like))
			duplicate/o like, w
		else
			make w
		endif
	endif
	
	return name
end

function getNumberFrom(string s, int pos)
	// gets the number from the string s 
	// starting at position pos. Only works
	// with integer numbers
	int N = strlen(s)
	int i
	variable res
	for(i=pos;i<N;i++)
		if(numtype(str2num(s[i])) == 2 ) // Nan found
		break
		endif
	endfor
	
	// return a crazy number if Nan
	res = str2num(s[pos, i-1])
	res = numtype(res) == 2 ? -999 : res
	return res 
end

function/wave getCompatibleConstrains(hold, constrains)
	// Keeps only constrains that are compatible with a give hold string.
	// Generates a copy of constrains

	string hold
	wave/t constrains
	variable i,j, k
	variable N = dimsize(constrains,0)

	string constrain
	duplicate/o/t constrains compatibleConstrains

	for(i=0;i<N;i=i+1)
		
		constrain = compatibleConstrains[i]
		j = strsearch(constrain, "K", 0)
		k = getNumberFrom(constrain, j + 1)
		//print i, j, k, hold[k], constrain
		
		if(k >= strlen(hold))
			Print "Error, hold string is shorter than required parameter"
			return constrains
		endif

		if(cmpstr(hold[k], "1") == 0) // remove parameter if is holding
			deletePoints i, 1, compatibleConstrains
			i=i-1
			N=N-1
		endif
	endfor
	return compatibleConstrains
end

function/s sBWO(s1, s2)
	// string Bit Wise Or
	// assume s1 is longer than s2
	
	string s1, s2
	int N = min(strlen(s1), strlen(s2))
	int i
	variable n1, n2
	string temp, res
	
	if (strlen(s1) < strlen(s2))
		temp = s2
		s2 = s1
		s1 = temp
	endif 	
	
	res = ""
	for(i=0;i<N;i++)
		n1 = str2num(s1[i])
		n2 = str2num(s2[i])
		res = res + num2str(n1 | n2)
		//print i, n1, n2, n1 | n2
	endfor
	
	res = res + s1[N,INF]
	return res
end

function normalize(src)
	wave src
	string dup_name = "Norm_" + nameofwave(src)
	variable m = wavemax(src)
	duplicate/O src, $dup_name
	
	wave dup = $dup_name
	dup = dup / m
end

function	find_max(src) 
	// returns the position
	// of maximum intensity
	wave src
	variable m = wavemax(src)
	findvalue/v =(m) src
	return V_value
end

function displace(src, dx)
	wave src
	variable dx
	variable offset = dimoffset(src, 0)
	variable delta = dimdelta(src, 0)
	offset = offset + dx
	setscale/p x, offset, delta, "", src
end

function/wave new_append(src, s)
	// creates a new empty wave 
	// with the same size as src
	// named src_name + s
	wave src
	string s
	
	string name = nameofwave(src)
	string new = name + s
	duplicate/o src, $new 
	wave new_wave = $new 
	new_wave = Nan
	
	return $new
end

function/wave copy_append(src, s)
	// copies the wave src into
	// a new wave named 
	// src_name + s
	wave src
	string s
	
	string name = nameofwave(src)
	string new = name + s
	duplicate/o src, $new 
	return $new
end

function/wave new_append_coeff(src, coeff, s)
	// creates a new wave of coefficients
	// from coeff.
	// the name is src_name + s
	wave src, coeff
	string s
	
	string name = nameofwave(src)
	string new = name + s
	duplicate/o coeff, $new 
	wave new_wave = $new 
	new_wave = 0
	
	// if 2d wave resize to 2d
	if(dimsize(src, 1))
		variable cols = dimsize(src, 1)
		redimension/n=(-1, cols) $new
	endif
	
	return $new
end

function/wave copy_append_coeff(src, coeff, s)
	wave src, coeff
	string s
	
	string name = nameofwave(src)
	string new = name + s
	
	duplicate/o coeff, $new 
	wave wnew = $new	
	
	// if 2d wave resize to 2d
	if(dimsize(src, 1))
		variable cols = dimsize(src, 1)
		redimension/n=(-1, cols) wnew
		
		// all the extended columns have zeros
		// so copy the initial coeffs
		variable i
		for(i=0;i<cols;i++)
			wnew[][i] = coeff[p]
		endfor
	
	endif
	
	return wnew
end

function plotCoeff(coeff)
	wave coeff
	variable rows = dimsize(coeff, 0)
	variable cols = dimsize(coeff, 1)
	duplicate/o coeff coeffImage
	make/free/n=(cols) slice
	
	variable myMean, myStd, offset
	
	display
	int i
	
	for(i = 0; i < rows; i++)
		slice = coeffImage[i][p]
		myMean = mean(slice)
		myStd = sqrt(variance(slice))
		print myMean, myStd
		offset = 4 * i
		coeffImage[i][] = (coeffImage[i][q] - myMean) / myStd + offset
		
		appendTograph coeffImage[i][]
	endfor 
	
end

function/s getBinStd(wave w)
	variable N = sum(w)
	variable delta = abs(dimDelta(w,0))
	duplicate/o w, px, std
	px = (w / N ) * (1 / delta)
	std = sqrt(w * px * (1 - px))
	return nameofWave(std)
end


function setLabelsFromString(wave w, wave /T labels)
	variable i, N
	N = dimsize(w,0)
	
	for(i = 0; i < N; i++)
		setDimLabel 0, i, $(labels[i]), w
	endfor
end 

Function TransAx_eVtoCm_1(w, val)
    Wave/Z w            // a parameter wave, if desired. Argument must be present for FindRoots.
    Variable val
    
    return val*8065.61042
end

Function/S TickMeV(val)
	variable val
   String TickMeV
   TickMeV = num2str(val * 1000)  // Convert eV to meV
End



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
