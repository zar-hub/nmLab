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
	
	
	wave CO 	= $getGlobalWave("CO", like = res)
	wave C1 	= $getGlobalWave("C1", like = res)
	wave C2 	= $getGlobalWave("C2", like = res)
	wave C3	= $getGlobalWave("C3", like = res)

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



function fitC1S_compAndCO(coeff, src, [res, wait, dbg, sleepTime])
	wave coeff, src, res
	int wait, dbg
	variable sleepTime
	
	duplicate/o src C1S, CO, mask, bg
	duplicate/free coeff tcoeff startingCoeff delta
	
	if(!paramisDefault(dbg))
		display
	endif
	if(paramisDefault(res))
		duplicate/o src res
	endif
	
	if (paramIsDefault(sleepTime))
		sleepTime = 0
	endif

	duplicate/o src, C1, C2, C3, OC1, OC2, OC3	 // components
	duplicate/o src, CO, mask, bg			 // C1S and CO
	duplicate/free coeff tcoeff delta startingCoeff	
	
	appendtoGraph src, $nameOfWave(res), C1, C2, C3, OC1, OC2, OC3
	appendtoGraph CO, mask
	
	// Components
	ModifyGraph lsize($nameOfWave(res))=1.3,rgb($nameOfWave(res))=(1,16019,65535)
	ModifyGraph lsize(C1)=1.3,rgb(C1)=(0,65535,0),lsize(C2)=1.3,rgb(C2)=(65535,43690,0),lsize(C3)=1.3,rgb(C3)=(65535,0,52428)
	ModifyGraph mode(C1)=7,usePlusRGB(C1)=1,hbFill(C1)=2,plusRGB(C1)=(3,52428,1,16384),mode(C2)=7,usePlusRGB(C2)=1,hbFill(C2)=2,plusRGB(C2)=(52428,34958,1,16384),mode(C3)=7,usePlusRGB(C3)=1,hbFill(C3)=2,plusRGB(C3)=(52428,1,41942,16384)
	ModifyGraph lstyle(OC1)=7, lstyle(OC2)=7, lstyle(OC3)=7
	
	// CO and C1S
	ModifyGraph mode(CO)=7,lsize(CO)=1.3,rgb(CO)=(1,34817,52428)
	ModifyGraph hbFill(CO)=2, plusRGB(CO)=(1,34817,52428,16384), usePlusRGB(CO)=1
	
	// STD ESTIMATION
	wave std = $getbinStd(src)
	ErrorBars/L=0.5/Y=3 $nameofWave(src) Y,wave=(std,std)
	
	textBox/A=LT/n=infoTBox "Initial values"
	plotPeaksC1S_compAndCO(coeff, res, plot = "all")
	OC1 = C1
	OC2 = C2
	OC3 = C3
	updateAndSleep(sleepTime)
	
	Make/O/T/free constrains_co={\
		"K2 > 0.08",\
		"K2 < 0.14",\
		"K3 > 0.24",\
		"K4 > 0.17",\
		"K4 < 0.25",\
		"K5 > 0.05",\
		"K6 < -286",\
		"K6 > -287.6"\
	}
	Make/O/T/free constrains_c1={\
		"K7 > 0.1",\
		"K7 < 0.3",\
		"K8 > 0.05",\
		"K8 < 25",\
		"K9 > 0.1",\
		"K9 < 0.6",\
		"K10 > 0.05",\
		"K11 > -284.8",\
		"K11 < -284.0"\
	}
	Make/O/T/free constrains_c2={\
		"K12 > 0.1",\
		"K12 < 0.3",\
		"K13 > 0.05",\
		"K13 < 25",\
		"K14 > 0.1",\
		"K14 < 0.6",\
		"K15 > 0.05",\
		"K16 > -284",\
		"K16 < -283.5"\
	}
	Make/O/T/free constrains_c3={\
		"K17 > 0.1",\
		"K17 < 0.3",\
		"K18 > 0.05",\
		"K18 < 25",\
		"K19 > 0.1",\
		"K19 < 0.6",\
		"K20 > 0.05",\
		"K21 > -283.9",\
		"K21 < -283"\
	}
	Make/O/T/free constrains_fixLineshape={\
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
	
	concatenate/o {constrains_co, constrains_c1,constrains_c2,constrains_c3,constrains_fixLineshape}, allConstrains 
	make/free allPeaks_C1S = {10,15,20}
	
	if(!paramisDefault(wait))
		return 0
	endif
	
	// Put every C1S peak to zero to begin bg estimation
	replaceText "Bg with every C1S peak\nto zero"
	tcoeff = coeff
	//for (int i : allPeaks_C1S)
	//	tcoeff[i] = 0
	//endfor
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// Fit only position, intensity and gaussian of CO peak
	string hold="00"+"11000"+"11101"+"11101"+"11101"
	getCompatibleConstrains(hold, allConstrains)
	
	execute "mask(-285.76, -282) = 0"
	FuncFit/Q/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std//M=mask
	replaceText "Optimized CO peak for bg"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)

	// Peak detection logic for CO peak
	// -	always optimize linear bg and intensities of c1s peaks
	//	- 	optimize CO lineshape and position only if co peak found
	string holdCO
	if(tcoeff[5] < 10) // no peak found, so hold the intensity to zero and fix lineshape
		//print "no peak found"
		tcoeff[5] = 0.1
		tcoeff[6] = startingCoeff[6]
		hold = "0011111"+"11101"+"11101"+"11101"
		holdCO = "11111" // do not fit CO parameters anymore
	else // peak found, fit all the parameters of CO and free 
		hold = "00"+"00000"+"11101"+"11101"+"11101"
		holdCO = "11101" // fit only intensity
	endif
	
	// Now fit bg and CO one last time to fully optimize
	// the background depending on peak detection result
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q/N=0/h=hold dsgnmBad2_MTHR tcoeff src/c=compatibleConstrains/I=1/w=std
	replaceText "background optimization after\npeak detection for CO"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// ___ FITTING C1S PEAKS ___
	
	// 1) Fit all peaks with fixed lineshapes but
	// keep gaussian free to not overconstrain the fit
	hold = "00"+"00000"+"11001"+"11001"+"11001"
	hold = sBWO(hold, holdCO)
	getCompatibleConstrains(hold, allConstrains)
	//print hold
	//execute "print compatibleConstrains"
	FuncFit/Q/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std
	replaceText "1) Fit peaks fixed lineshapes\n but keep gaussian free"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// 2) find peaks: if too small remove them
	// optimizing intensity, position and bg
	variable thresholdArea = 0.05
	variable thresholdIntensity = 2
	variable thresholdPosDelta = 0.005
	variable areaC1, areaC2, areaC3, areaTot 
	int flagRemoved = 0
	
	int i = 0 // loop counter
	flagRemoved = 0
	string holdPeaks = "00"+"00000"+"00000"+"00000"+"00000"	 // begin with every peak free
	string thisPeak, prefix
	for (int j : allPeaks_C1S) // peak coeff
		if (abs(coeff[j+1]- startingCoeff[j+1]) > thresholdPosDelta) 
			coeff[j+1] = startingCoeff[j+1]
		endif
		if(coeff[j] < thresholdIntensity) // no peak found, so hold the intensity to zero
			coeff[j] = 0.1
			coeff[j+1] = startingCoeff[j+1]
			prefix = "00" + replicateString("00000", i)
			thisPeak = prefix + "00011" // hold position and intensity
			//print thisPeak
			holdPeaks = sBWO(holdPeaks, thisPeak) 
			flagRemoved++
		endif
		i = i+1 // increment loop counter
	endfor
	
	// fit lineshape
	if (flagRemoved)
		replaceText "2) removed some peaks"
		plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
		updateAndSleep(sleepTime)
	endif
		
	// 3) Fit lineshapes with position fixed
	hold = "00"+"11111"+"00001"+"00001"+"00001"
	hold = sBWO(hold, holdPeaks)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std
	replaceText "3) Optimized lineshape C1S peaks,\nposition fixed"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// 4) Tuning back lineshape
	// toVarySlowly parameters can change only of percDelta
	// at each iteration
	delta =  (tcoeff - startingCoeff) 
	make/free lorIndex = {7, 12, 17}
	for(int j : lorIndex)
		tcoeff[j] = startingCoeff[j] + delta[j] * 0.2   // Lor
		tcoeff[j+1] = startingCoeff[j+1] + delta[j+1] * 0.5 // asym
		tcoeff[j+2] = startingCoeff[j+2] + delta[j+2] * 0.6  // Gau
	endfor
	replaceText "4) Tuned back lineshape C1S peaks"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// 5) Fit only positions and intensities of C1S peaks
	hold = "11"+"11111"+"11100"+"11100"+"11100"
	hold = sBWO(hold, holdPeaks)
	getCompatibleConstrains(hold, allConstrains)
	FuncFit/Q/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std
	replaceText "Optimized position and intensity,\nshape locked"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// 6) Tuning back peak positions
	delta =  (tcoeff - startingCoeff) 
	make/free posIndex = {11, 16, 21}
	for(int j : posIndex)
		tcoeff[j] = startingCoeff[j] + delta[j] * 0.5   // position
	endfor
	replaceText "6) Tuned back position C1S peaks"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// 7) Fit only bg and intensities
	// Now everything is set up, optimize only bg
	hold = "00"+holdCO+"11101"+"11101"+"11101"
	hold = sBWO(hold, holdPeaks)
	getCompatibleConstrains(hold, allConstrains)
	//print hold
	//execute "print compatibleConstrains"
	FuncFit/Q/N=0/h=hold dsgnmBad2_MTHR tcoeff src /c=compatibleConstrains/I=1/w=std
	replaceText "7) Optimized background and intensities,\n shape locked"
	plotPeaksC1S_compAndCO(tcoeff, res, plot="all")
	updateAndSleep(sleepTime)
	
	// save stuff
	if(paramIsDefault(dbg))
		coeff = tcoeff
	endif
	TextBox/K/N=infoTBox
end
