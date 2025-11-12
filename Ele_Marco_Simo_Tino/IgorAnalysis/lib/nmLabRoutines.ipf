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
	appendtoGraph src, res, C1, C2, C3, OC1, OC2, OC3
	duplicate/free coeff tcoeff delta startingCoeff
	ModifyGraph lsize(res)=1.3,rgb(res)=(1,16019,65535)
	ModifyGraph lsize(C1)=1.3,rgb(C1)=(0,65535,0),lsize(C2)=1.3,rgb(C2)=(65535,43690,0),lsize(C3)=1.3,rgb(C3)=(65535,0,52428)
	ModifyGraph mode(C1)=7,usePlusRGB(C1)=1,hbFill(C1)=2,plusRGB(C1)=(3,52428,1,16384),mode(C2)=7,usePlusRGB(C2)=1,hbFill(C2)=2,plusRGB(C2)=(52428,34958,1,16384),mode(C3)=7,usePlusRGB(C3)=1,hbFill(C3)=2,plusRGB(C3)=(52428,1,41942,16384)
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
	
	Make/O/T/free peakConstrains={\
		"K6 > -284.8",\
		"K6 < -284.0",\
		"K8 > -283.9",\
		"K8 < -283.9",\
		"K10 > -283.9",\
		"K10 < -283.1"\
	}
	Make/O/T/free LSConstrains={\
		"K2 > 0.1",\
		"K2 < 0.3",\
		"K3 > 0.05",\
		"K3 < 25",\
		"K4 > 0.1",\
		"K4 < 0.6"\
	}
	Make/O/T/free IntensityConstrains={\
		"K5 > 0.05",\
		"K7 > 0.05",\
		"K9 > 0.05"\
	}
	
	// 1) feel free to fit all peaks, but not lineshapes
	// keep gaussian free... do not overconstrain
	string hold = "00110010101"
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src
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
	
	if(areaC1 / areaTot < thresholdArea || coeff[5] < thresholdIntensity) // no peak found, so hold the intensity to zero
		coeff[5] = 0.1
		coeff[6] = startingCoeff[6]
		holdPeaks = sBWO(holdPeaks, "00000110000") 
		flagRemoved++
	endif
	if(areaC2 / areaTot < thresholdArea || coeff[7] < thresholdIntensity) // no peak found, so hold the intensity to zero
		coeff[7] = 0.1
		coeff[8] = startingCoeff[8]
		holdPeaks = sBWO(holdPeaks, "00000001100") 
		flagRemoved++
	endif
	if(areaC3 / areaTot < thresholdArea || coeff[9] < thresholdIntensity) // no peak found, so hold the intensity to zero
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
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src/c=LSConstrains
	replaceText "optimized lineshape, intensity"
	//print "3) optimized lineshape, intensity"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	// toVarySlowly parameters can change only of percDelta
	// at each iteration
	
	delta =  (coeff - startingCoeff) 
	coeff[2] = startingCoeff[2] + delta[2] * 0.1   // Lor
	coeff[3] = startingCoeff[3] + delta[3] * 0.2 // asym
	coeff[4] = startingCoeff[4] + delta[4] * 0.5  // Gau
	
	replaceText "tuned back lineshape"
	//Print "3.5) tuned back lineshape"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	// 4) Fit the positions
	hold = "11111000000"
	hold = sBWO(hold, holdPeaks)
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src
	replaceText "optimized intensity, position,\nshape locked exept gau"
	//print "4) optimized intensity, position, shape locked exept gau"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	delta =  (coeff - startingCoeff) 
	coeff[6] = startingCoeff[6] + delta[6] * 0.1   	// C1
	coeff[8] = startingCoeff[8] + delta[8] * 0.1 		// C2
	coeff[10] = startingCoeff[10] + delta[10] * 0.1  // C3
	
	replaceText "tuned back positions"
	//print "4) tuned back positions"
	plotPeaksC1S_comp(coeff, res)
	//printcoeff(coeff)
	updateAndSleep(sleepTime)
	
	// 5) Fit only bg and intensities
	hold = sBWO("00111010101", holdPeaks)
	FuncFit/Q/N=2/h=hold dsgnmBas_MTHR coeff, src/I=1/W=std // /c=IntensityConstrains
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