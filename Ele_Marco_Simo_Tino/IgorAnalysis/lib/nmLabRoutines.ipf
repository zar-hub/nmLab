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

function plotPeaksC1S_comp(coeff, res)
	wave coeff, res
	wave C1 = $"C1"
	wave C2 = $"C2"
	wave C3 = $"C3"
	
	duplicate/free coeff tcoeff
	
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
end

function plotPeaksC1S_compAndCO(coeff, res, [plot, app])
	// plot 	= "comp" (default) plot each component separately
	//			= "c1s" plot peak used in CO estimation
	// 			= "bg" plot only bg and CO peak
	//			= "all"
	// app = 1 append the waves to the current graph
	
	wave coeff, res
	string plot
	int app
	if (paramisDefault(plot))
		plot = "comp"
	endif
	
	wave CO = $getGlobalWave("CO", like = res, folder = ":internal")
	wave C1 = $getGlobalWave("C1", like = res, folder = ":internal")
	wave C2 = $getGlobalWave("C2", like = res, folder = ":internal")
	wave C3 = $getGlobalWave("C3", like = res, folder = ":internal")

	duplicate/free coeff tcoeff
	make/free toZeroList = {0,1,5,10,15,20}
	
	// reset all components
	C1 = 0
	C2 = 0
	C3 = 0
	CO = 0
	
	// always plot CO	
	tcoeff = coeff
	for (int i : toZeroList)
		tcoeff[i] = 0
	endfor
	tcoeff[5] = coeff[5]
	CO = dsgnmBad2_MTHR(tcoeff, x)
	
	if (cmpstr(plot, "comp")  == 0 || cmpstr(plot, "all") == 0) // plot components
		tcoeff = coeff
		for (int i : toZeroList)
			tcoeff[i] = 0
		endfor
		tcoeff[10] = coeff[10]
		C1 = dsgnmBad2_MTHR(tcoeff, x)
		
		tcoeff = coeff
		for (int i : toZeroList)
			tcoeff[i] = 0
		endfor
		tcoeff[15] = coeff[15]
		C2 = dsgnmBad2_MTHR(tcoeff, x)
		
		tcoeff = coeff
		for (int i : toZeroList)
			tcoeff[i] = 0
		endfor
		tcoeff[20] = coeff[20]
		C3 = dsgnmBad2_MTHR(tcoeff, x)
		
		tcoeff = coeff
		res = dsgnmBad2_MTHR(tcoeff, x)
	endif
	
	if(cmpstr(plot, "bg")  == 0)
		tcoeff = coeff
		// remove C1S peaks
		tcoeff[10] = 0
		tcoeff[15] = 0
		tcoeff[20] = 0
		res = dsgnmBad2_MTHR(tcoeff, x)
	endif
	
	if(!paramisDefault(app))
		appendtoGraph CO, C1S, C1, C2, C3
	endif
end

function fitC1S_comp(coeff, src, [res, wait, dbg, sleepTime])
	// Expects an open graph to plot the fit process to.
	// Data is appended to default axis names, so one should 
	// leave them for this function to handle and plot to other 
	// axis in the same graph.
	wave coeff, src, res
	int wait, dbg
	variable sleepTime
	string name = nameofWave(src)
	
	
	if(paramisDefault(res))
		duplicate/o src res
	endif
	
	if(!paramisDefault(dbg))
		display 			// enable when debugging
	endif
	
	if(paramisDefault(sleepTime))
		sleepTime = 0
	endif
	
	duplicate/o src, C1, C2, C3, OC1, OC2, OC3
	appendtoGraph src, $nameOfWave(res), C1, C2, C3, OC1, OC2, OC3
	duplicate/free coeff tcoeff delta startingCoeff
	ModifyGraph lsize($nameOfWave(res))=1.3,rgb($nameOfWave(res))=(1,16019,65535)
	ModifyGraph lsize(C1)=1.3,rgb(C1)=(0,65535,0),lsize(C2)=1.3,rgb(C2)=(65535,43690,0),lsize(C3)=1.3,rgb(C3)=(65535,0,52428)
	ModifyGraph mode(C1)=7,usePlusRGB(C1)=1,hbFill(C1)=2,plusRGB(C1)=(3,52428,1,16384),mode(C2)=7,usePlusRGB(C2)=1,hbFill(C2)=2,plusRGB(C2)=(52428,34958,1,16384),mode(C3)=7,usePlusRGB(C3)=1,hbFill(C3)=2,plusRGB(C3)=(52428,1,41942,16384)
	ModifyGraph lstyle(OC1)=7, lstyle(OC2)=7, lstyle(OC3)=7
	textBox/A=RT/n=infoTBox "Initial values"
	
	//print "Initial values"
	//printcoeff(coeff)
	
	
	plotPeaksC1S_comp(coeff, res)
	OC1 = C1
	OC2 = C2
	OC3 = C3
	updateAndSleep(sleepTime)
	
	if(!paramisDefault(wait))
		return 0
	endif
	
	wave std = $getbinStd(src)
	ErrorBars/L=0.5/Y=3 $nameofWave(src) Y,wave=(std,std)
	
	// FITTING PROCEDURE
	// 1) Evaluate peaks presence without lineshape
	// 2) Set to zero "bad" peaks
	// 3) Fit lineshape with weight factor
	// 4) Optimize bg and intensities
	
	Make/O/T/free allConstrains={\
		"K2 > 0.1",\
		"K2 < 0.3",\
		"K3 > 0.05",\
		"K3 < 25",\
		"K4 > 0.1",\
		"K4 < 0.6",\
		"K6 > -284.8",\
		"K6 < -284.0",\
		"K8 > -284",\
		"K8 < -283.5",\
		"K10 > -283.9",\
		"K10 < -283",\
		"K5 > 0.05",\
		"K7 > 0.05",\
		"K9 > 0.05"\
	}
	
	duplicate/o/t allConstrains, compConstrains
	
	// 1) feel free to fit all peaks, but not lineshapes
	// keep gaussian free... do not overconstrain
	string hold = "00110010101"
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src/c=compatibleConstrains
	replaceText "lineshape fixed,\noptimized intensity\nto find peaks"
	//print "1) lineshape fixed, optimized intensity to find peaks"
	//printcoeff(coeff)
	plotPeaksC1S_comp(coeff, res)
	updateAndSleep(sleepTime)

	// 2) find peaks: if too small remove them
	// optimizing intensity, position and bg
	string holdPeaks = "00000000000"
	variable thresholdArea = 0.05
	variable thresholdIntensity = 2
	variable thresholdPosDelta = 0.005
	variable areaC1, areaC2, areaC3, areaTot 
	int flagRemoved = 0
	
	int i
	for (i = 6; i<=8; i=i+2) // 6, 8, 10 peak positions
		if (abs(coeff[i]- startingCoeff[i]) > thresholdPosDelta)
			coeff[i] = startingCoeff[i]
		endif
	endfor
	
	areaC1 = area(C1, -288, -282)
	areaC2 = area(C2, -288, -282)
	areaC3 = area(C3, -288, -282)
	areaTot = areaC1 + areaC2 + areaC3
	
	if(dbg)
		print areaC1 / areaTot, areaC2 / areaTot, areaC3 / areaTot
	endif
	
	if(coeff[5] < thresholdIntensity) // no peak found, so hold the intensity to zero
		coeff[5] = 0.1
		coeff[6] = startingCoeff[6]
		holdPeaks = sBWO(holdPeaks, "00000110000") 
		flagRemoved++
	endif
	if(coeff[7] < thresholdIntensity) // no peak found, so hold the intensity to zero
		coeff[7] = 0.1
		coeff[8] = startingCoeff[8]
		holdPeaks = sBWO(holdPeaks, "00000001100") 
		flagRemoved++
	endif
	if(coeff[9] < thresholdIntensity) // no peak found, so hold the intensity to zero
		coeff[9] = 0.1
		coeff[10] = startingCoeff[10]
		holdPeaks = sBWO(holdPeaks, "00000000011")
		flagRemoved++ 
	endif
	
	// fit lineshape
	if (flagRemoved)
		replaceText "removed some peaks"
		plotPeaksC1S_comp(coeff, res)
		updateAndSleep(sleepTime)
	endif
	
	// 3) Fit lineshapes and apply weight factor
	hold = sBWO("11000010101", holdPeaks)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src/c=compatibleConstrains
	replaceText "optimized lineshape, intensity"
	//print "3) optimized lineshape, intensity"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	// toVarySlowly parameters can change only of percDelta
	// at each iteration
	
	delta =  (coeff - startingCoeff) 
	coeff[2] = startingCoeff[2] + delta[2] * 0.2   // Lor
	coeff[3] = startingCoeff[3] + delta[3] * 0.5 // asym
	coeff[4] = startingCoeff[4] + delta[4] * 0.6  // Gau
	
	replaceText "tuned back lineshape"
	//Print "3.5) tuned back lineshape"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	// 4) Fit the positions
	hold = "11111000000"
	hold = sBWO(hold, holdPeaks)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src /c=compatibleConstrains
	replaceText "optimized intensity, position,\nshape locked exept gau"
	//print "4) optimized intensity, position, shape locked exept gau"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	delta =  (coeff - startingCoeff) 
	coeff[6] = startingCoeff[6] + delta[6] * 0.5   	// C1
	coeff[8] = startingCoeff[8] + delta[8] * 0.5 		// C2
	coeff[10] = startingCoeff[10] + delta[10] * 0.5  // C3
	
	replaceText "tuned back positions"
	//print "4) tuned back positions"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	// 5) Fit only bg and intensities
	hold = sBWO("00111010101", holdPeaks)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src/I=1/W=std /c=compatibleConstrains
	replaceText "optimized intensity and position, shape locked"
	//print "5) optimized intensity, shape locked"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	TextBox/K/N=infoTBox
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
	
	duplicate/o src C1S, CO, mask, bg
	duplicate/free coeff tcoeff startingCoeff delta
	
	if(paramisDefault(res))
		duplicate/o src res
	endif
	
	if (paramIsDefault(sleepTime))
		sleepTime = 0
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
		"K4 > 0.17",\
		"K4 < 0.25",\
		"K6 < -286.4",\
		"K6 > -287.6"\
	}
	Make/O/T/free co_constrains={\
		"K4 > 0.17",\
		"K4 < 0.25",\
		"K6 < -286.4",\
		"K6 > -287.6"\
	}
	
	// prepare for fitting
	tcoeff = coeff
	tcoeff[10] = 0
	bg = dsgnmBad2_MTHR(tcoeff, x)
	updateAndSleep(sleepTime)
	
	// try to fit only position and intensity
	string hold="001100011111"
	FuncFit/Q/N=0/h=hold dsgnmBad2_MTHR tcoeff[0,6] src /M=mask/c=co_constrains
	bg = dsgnmBad2_MTHR(tcoeff, x)
	coeff[0,6] = tcoeff[p]	// save coeff
	updateAndSleep(sleepTime)
	
	
	if(coeff[5] < 8) // no peak found, so hold the intensity to zero
		coeff[5] = 0.1
		hold = "001111111101"
	else // peak found, so feel free to keep fitting it
		FuncFit/Q/N=0 Dsgn_MTHR coeff[0,6] src /M=mask/c=constrains
		hold = "001110111101"	
	endif
	
	tcoeff = coeff
	tcoeff[10] = 0
	tcoeff[0,6] = coeff[p]
	bg = Dsgn_MTHR(tcoeff, x)
	C1S = src - bg
	updateAndSleep(sleepTime)
	
	// only fit C1S
	FuncFit/Q/N=2 dsgnnb_MTHR coeff[7,11], C1S
	updateAndSleep(sleepTime)
	
	// allow lineshape parameter to vary only by 10 %
	//make/free toVarySlowly = {2,3,4,7,8,9}
	variable percDelta = 0.2
	make/free toVarySlowly = {2,3,4,6,7,8,9,11}
	delta =  (coeff - startingCoeff) * percDelta
	for(int i : toVarySlowly)
		coeff[i] = startingCoeff[i] + delta[i]
	endfor
	
	// fit both
	FuncFit/h=hold/Q/N=2 dsgnmBad2_MTHR coeff src
	
	// update stuff again
	removefromGraph mask, bg
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

function C1S_compPlusCO(w, x)
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = dsgnmBad2_MTHR(c1s_co_coeff, x) + dsgnmBasnb_MTHR(c1s_comp_coeff, x)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = bg intercept
	//CurveFitDialog/ w[1] = bg slope
	//CurveFitDialog/ w[2] = Lor CO 
	//CurveFitDialog/ w[3] = Asy CO
	//CurveFitDialog/ w[4] = Gau CO
	//CurveFitDialog/ w[5] = Int CO
	//CurveFitDialog/ w[6] = pos CO
	//CurveFitDialog/ w[7] = Lor C1S 
	//CurveFitDialog/ w[8] = Asy C1S
	//CurveFitDialog/ w[9] = Gau C1S
	//CurveFitDialog/ w[10] = Int C1S
	//CurveFitDialog/ w[11] = pos C1S
	//CurveFitDialog/ w[12] = bg intercept
	//CurveFitDialog/ w[13] = bg slope
	//CurveFitDialog/ w[14] = Lor C1S_comp 
	//CurveFitDialog/ w[15] = Asy C1S_comp
	//CurveFitDialog/ w[16] = Gau C1S_comp
	//CurveFitDialog/ w[17] = Int C1
	//CurveFitDialog/ w[18] = pos C1
	//CurveFitDialog/ w[19] = Int C2
	//CurveFitDialog/ w[20] = pos C2
	//CurveFitDialog/ w[21] = Int C3
	//CurveFitDialog/ w[22] = pos C3
	
	duplicate/free/rmd=[0, 11] w, c1s_co_coeff
	duplicate/free/rmd=[12, 22] w, c1s_comp_coeff
	return dsgnmBad2_MTHR(c1s_co_coeff, x) + dsgnmBas_MTHR(c1s_comp_coeff, x)
end 


function createCompAndCOConstrains()
	Make/O/T constrains_bg={\
		"K0 > 100",\
		"K1 < -0.8"\
	}
	Make/O/T constrains_co={\
		"K2 > 0.08",\
		"K2 < 0.14",\
		"K3 > 0.24",\
		"K4 > 0.17",\
		"K4 < 0.25",\
		"K5 > 0.05",\
		"K6 < -286",\
		"K6 > -287.6"\
	}
	Make/O/T constrains_c1={\
		"K7 > 0.1",\
		"K7 < 0.3",\
		"K8 > 0.05",\
		"K8 < 0.8",\
		"K9 > 0.1",\
		"K9 < 0.6",\
		"K10 > 0.05",\
		"K11 > -284.8",\
		"K11 < -284.0"\
	}
	Make/O/T constrains_c2={\
		"K12 > 0.1",\
		"K12 < 0.3",\
		"K13 > 0.05",\
		"K13 < 0.8",\
		"K14 > 0.1",\
		"K14 < 0.6",\
		"K15 > 0.05",\
		"K16 > -284",\
		"K16 < -283.5"\
	}
	Make/O/T constrains_c3={\
		"K17 > 0.1",\
		"K17 < 0.3",\
		"K18 > 0.05",\
		"K18 < 0.8",\
		"K19 > 0.1",\
		"K19 < 0.6",\
		"K20 > 0.05",\
		"K21 > -283.9",\
		"K21 < -283"\
	}
	Make/O/T constrains_fixLineshape={\
		"K12 > K7",\
		"K12 < K7",\
		"K17 > K7",\
		"K17 < K7",\
		"K13 > K8",\
		"K13 < K8",\
		"K18 > K8",\
		"K18 < K8",\
		"K14 > K9",\
		"K14 < K9",\
		"K19 > K9",\
		"K19 < K9"\
	}
	moveToFolder(":options", nameofWave(constrains_bg))
	moveToFolder(":options", nameofWave(constrains_co))
	moveToFolder(":options", nameofWave(constrains_c1))
	moveToFolder(":options", nameofWave(constrains_c2))
	moveToFolder(":options", nameofWave(constrains_c3))
	moveToFolder(":options", nameofWave(constrains_fixLineshape))
end

function fitC1S_compAndCO(coeff, src, [res, wait, dbg, sleepTime, quiet])
	wave coeff, src, res
	int wait, dbg
	variable sleepTime, quiet
	
	if(!paramisDefault(dbg))
		display
	endif

	if(paramisDefault(res))
		wave res = $getGlobalWave("res", like = src, folder = ":internal")
	endif
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	quiet = paramisDefault(quiet) ? 1 : quiet
	
	// init waves
	duplicate/free coeff tcoeff startingCoeff delta
	wave CO = $getGlobalWave("CO", like = src, folder = ":internal")
	wave C1 = $getGlobalWave("C1", like = src, folder = ":internal")
	wave C2 = $getGlobalWave("C2", like = src, folder = ":internal")
	wave C3 = $getGlobalWave("C3", like = src, folder = ":internal")
	wave OC1 = $getGlobalWave("OC1", like = src, folder = ":internal")
	wave OC2 = $getGlobalWave("OC2", like = src, folder = ":internal")
	wave OC3 = $getGlobalWave("OC3", like = src, folder = ":internal")
	wave std = $movetoFolder(":internal", getbinStd(src))
	
	appendtoGraph src, res, CO, C1, C2, C3, OC1, OC2, OC3
	
	// Components
	ModifyGraph lsize($nameOfWave(res))=1.3,rgb($nameOfWave(res))=(1,16019,65535)
	ModifyGraph lsize(C1)=1.3,rgb(C1)=(0,65535,0),lsize(C2)=1.3,rgb(C2)=(65535,43690,0),lsize(C3)=1.3,rgb(C3)=(65535,0,52428)
	ModifyGraph mode(C1)=7,usePlusRGB(C1)=1,hbFill(C1)=2,plusRGB(C1)=(3,52428,1,16384),mode(C2)=7,usePlusRGB(C2)=1,hbFill(C2)=2,plusRGB(C2)=(52428,34958,1,16384),mode(C3)=7,usePlusRGB(C3)=1,hbFill(C3)=2,plusRGB(C3)=(52428,1,41942,16384)
	ModifyGraph lstyle(OC1)=7, lstyle(OC2)=7, lstyle(OC3)=7
	
	// CO and C1S
	ModifyGraph mode(CO)=7,lsize(CO)=1.3,rgb(CO)=(1,34817,52428)
	ModifyGraph hbFill(CO)=2, plusRGB(CO)=(1,34817,52428,16384), usePlusRGB(CO)=1
	
	// Errors
	ErrorBars/L=0.5/Y=3 $nameofWave(src) Y,wave=(std,std)
	
	textBox/C/A=LT/n=infoTBox "Initial values"
	plotPeaksC1S_compAndCO(coeff, res, plot = "all")
	OC1 = C1
	OC2 = C2
	OC3 = C3
	updateAndSleep(sleepTime)
	
	if(!paramisDefault(wait))
		return 0
	endif
	
	// Get constrains
	if (!waveexists($":options:constrains_bg"))
		if(!quiet)
			print "Creating default constrains"
		endif
		createCompAndCOConstrains()
	endif
	wave constrains_bg = $":options:constrains_bg"
	wave constrains_co = $":options:constrains_co"
	wave constrains_c1 = $":options:constrains_c1"
	wave constrains_c2 = $":options:constrains_c2"
	wave constrains_c3 = $":options:constrains_c3"
	wave constrains_fixLineshape = $":options:constrains_fixLineshape"
	concatenate/o {constrains_bg, constrains_co, constrains_c1,constrains_c2,constrains_c3,constrains_fixLineshape}, allConstrains 
	
	// Get globalHold
	svar globalHold = $getGlobalString("globalHold", folder = ":options", ifUndef="00"+"00000"+"00000"+"00000"+"00000")
	if(!quiet)
		print "globalHold : ", globalHold
	endif
	
	// Fit parameters and options
	make/free allPeaks_C1S = {10,15,20}
	make/free lorIndex = {7, 12, 17}
	variable thresholdIntensity = 1.5 * mean(std)
	
	// Flags and counters
	int i, flagRemoved
	
	// Helpers
	string hold, holdCO
	
	// === STARTING THE FIT ===
	tcoeff = coeff
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// A0) Fit only position, intensity and gaussian of CO peak
	if(!quiet)
		print "A0) Check for CO peak"
	endif
	replaceText "Check for CO peak"
	hold="00"+"11000"+"11101"+"11101"+"11101"
	hold = sBWO(hold, globalHold)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q=(quiet)/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std//M=mask
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)

	// A1) Peak detection logic for CO peak
	// -	always optimize linear bg and intensities of c1s peaks
	//	- 	optimize CO lineshape and position only if co peak found
	if(!quiet)
		print "A1) Apply peak detection logic for CO peak"
	endif
	
	if(tcoeff[5] < thresholdIntensity) // no peak found, so hold the intensity to zero and fix lineshape
		//print "no peak found"
		if(!quiet)
			printf "A1) --- No CO peak detected. Intensity %.2f less than threshold %f\n", tcoeff[5], thresholdIntensity
		endif
		tcoeff[5] = 0.1
		tcoeff[6] = startingCoeff[6]
		hold = "0011111"+"11101"+"11101"+"11101"
		holdCO = "00"+"11111" // do not fit CO parameters anymore
	else // peak found, fit all the parameters of CO and free 
		if(!quiet)
			printf "A1) --- CO peak detected. Intensity %.2f compared to threshold %f\n", tcoeff[5], thresholdIntensity
			print "A1) --- Optimizing CO lineshape"
		endif
		replaceText "Optimizing lineshape\nafter peak detection for CO"
		hold = "00"+"00000"+"11101"+"11101"+"11101"
		holdCO = "00"+"11101" // fit only intensity
		// Now fit bg and CO one last time to fully optimize
		// the background depending on peak detection result
		hold = sBWO(hold, globalHold)
		getCompatibleConstrains(hold, allConstrains)
		FuncFit/Q=(quiet)/N=0/h=hold dsgnmBad2_MTHR tcoeff src/c=compatibleConstrains/I=1/w=std
		plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
		updateAndSleep(sleepTime)
	endif
	
	// ___ FITTING C1S PEAKS ___
	
	
	// 2) find peaks: if too small remove them
	// optimizing intensity, position and bg
	if(!quiet)
		print "B0) Apply peak detection logic for C1S peaks"
	endif

	i = 0 // loop counter
	flagRemoved = 0
	string holdPeaks = "00"+"00000"+"00000"+"00000"+"00000"	 // begin with every peak free
	string thisPeak, prefix
	for (int j : allPeaks_C1S) // peak coeff
		//if (abs(tcoeff[j+1]- startingCoeff[j+1]) > thresholdPosDelta) 
		//	tcoeff[j+1] = startingCoeff[j+1]
		//endif
		if(tcoeff[j] < thresholdIntensity) // no peak found, so hold the intensity to zero
			if(!quiet)
				printf "B0) --- No C%d peak detected. Intensity %.2f compared to threshold %f\n", i, tcoeff[j], thresholdIntensity
			endif
			tcoeff[j] = 0.1
			tcoeff[j+1] = startingCoeff[j+1]
			prefix = "00" + "00000" + replicateString("00000", i)
			thisPeak = prefix + "11111" // hold peak parameters
			//print thisPeak
			holdPeaks = sBWO(holdPeaks, thisPeak) 
			flagRemoved++
		endif
		i = i+1 // increment loop counter
	endfor
	
	// fit lineshape
	if (flagRemoved)
		if(!quiet)
			print "B0) --- holdPeaks : ", holdPeaks
		endif
		replaceText "2) removed some peaks"
		plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
		updateAndSleep(sleepTime)
	endif
	
	// B1) Fit C1S peaks lineshapes
	// this is done first because peak position should vary
	// less than the lineshape
	hold = "00"+"11111"+"00001"+"00001"+"00001"
	hold = sBWO(hold, holdPeaks)
	hold = sBWO(hold, globalHold)
	
	if(!quiet)
		print "B1) Fit all C1S peaks with fixed lineshapes"
		print "B1) --- hold : ", hold
	endif
	replaceText "B1) Fit all C1S peaks with fixed lineshapes"
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q=(quiet)/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// B2) Tune back C1S peaks lineshape
	// toVarySlowly parameters can change only of percDelta
	// at each iteration
	if(!quiet)
		print "B2) Tune back C1S peaks lineshape" 
	endif
	replaceText "B2) Tune back C1S peaks lineshape" 
	delta =  (tcoeff - startingCoeff) 
	
	for(int j : lorIndex)
		tcoeff[j] = startingCoeff[j] + delta[j] * 0.25   // Lor
		tcoeff[j+1] = startingCoeff[j+1] + delta[j+1] * 0.5 // asym
		tcoeff[j+2] = startingCoeff[j+2] + delta[j+2] * 0.8  // Gau
	endfor
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// B3) Fit C1S peaks positions and intensities
	if(!quiet)
		print "B3) Fit C1S peaks positions and intensities" 
	endif
	replaceText "B3) Fit C1S peaks positions and intensities"
	hold = "00"+"11111"+"11100"+"11100"+"11100"
	hold = sBWO(hold, holdPeaks)
	hold = sBWO(hold, globalHold)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q=(quiet)/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// B4) Tune back C1S peaks positions
	if(!quiet)
		print "B4) Tune back C1S peaks positions" 
	endif
	replaceText "B4) Tune back C1S peaks positions"
	delta =  (tcoeff - startingCoeff) 
	make/free posIndex = {11, 16, 21}
	for(int j : posIndex)
		tcoeff[j] = startingCoeff[j] + delta[j] * 0.5   // position
	endfor
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// B5) Fit linear bg and intensities of CO and C1S peaks
	if(!quiet)
		print "B5) Fit linear bg and intensities of CO and C1S peaks" 
	endif
	replaceText "B5) Fit linear bg and intensities of CO and C1S peaks"
	hold = holdCO+"11101"+"11101"+"11101"
	//hold = "11"+"11111"+"11101"+"11101"+"11101"
	hold = sBWO(hold, holdPeaks)
	hold = sBWO(hold, globalHold)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q=(quiet)/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// save stuff
	if(paramIsDefault(dbg))
		coeff = tcoeff
	endif
	TextBox/K/N=infoTBox
end
