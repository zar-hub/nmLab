#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

function NewImageLSCompatibility(wave image)
	string name = nameofWave(image)
	figure89mm(name = name)
	appendimageCScale(image)
	ModifyImage ''#0 ctab= {-2,2,BlackBody,0},minRGB=(0,0,0),maxRGB=(0,0,0)
	SavePICT/O/P=home/E=-5/TRAN=1/RES=300 as "img:"+name +".png"
end

function NewImageGreyScale(wave image)
	string name = nameofWave(image)
	figure89mm(name = name)
	appendimageCScale(image)
	SavePICT/O/P=home/E=-5/TRAN=1/RES=300 as "img:"+name +".png"
end

function removeBackground(wave coeff, wave image, [variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime

	Print "Removing background using Mulitcomponents and CO of image : ",nameofWave(image)
	duplicate/o image, $(nameOfWave(image) + "_NoBG")
	wave background = $(nameOfWave(image) + "_NoBG")
	
	// get 1D waves
	duplicate/o/rmd=[][0] image, tmpBackground, tmpSlice
	redimension/n=(-1,0) tmpBackground, tmpSlice
	duplicate/o/rmd=[][0] coeff, thisCoeff
	redimension/n=(-1,0) thisCoeff
	
	display/n=tmpGraph tmpBackground, tmpSlice
	int i 
	for(i=0;i<dimsize(image,1);i++)
		thisCoeff[] = coeff[p][i]
		tmpSlice[] = image[p][i]
		plotPeaksC1S_compAndCO(thisCoeff, tmpBackground, plot="bg")
		background[][i] = tmpSlice[p] - tmpBackground[p]
		doUpdate
		Sleep/s sleepTime
	endfor 
	
	cleanupTmpObj()
end

function normalizeArea(wave coeff, wave image, [variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	Print "Normalizing spectra using area: ",nameofWave(image)
	
	duplicate/o image, $(nameOfWave(image) + "_Norm")
	make/o/n=(dimsize(image,1)) $(nameOfWave(image) + "_Norm_Scaling")
	make/o/n=(dimsize(image,1)) $(nameOfWave(image) + "_Norm_LostSignal")
	
	wave normImage = $(nameOfWave(image) + "_Norm")
	wave scaling = $(nameOfWave(image) + "_Norm_Scaling")
	wave lostSignal = $(nameOfWave(image) + "_Norm_LostSignal")
	lostSignal = 0
	
	// temp waves
	duplicate/o/rmd=[][0] image, tmpSlice, tmpFitSlice, tmpResid
	redimension/n=(-1,0) tmpSlice, tmpFitSlice, tmpResid
	duplicate/o/rmd=[][0] coeff, tmpCoeff
	redimension/n=(-1,0) tmpCoeff
	
	display/w=(0,0,400,300)/n=tmpGraph tmpSlice, tmpFitSlice
	display/w=(400,0,800,300)/n=tmpResid tmpResid
	
	int i 
	variable sigma, wmax
	for(i=0;i<dimsize(image,1);i++)
		// remove bg and CO
		tmpCoeff[] = coeff[p][i]
		tmpCoeff[0,1] = 0
		tmpCoeff[5] = 0
		
		// get the slices
		tmpFitSlice = dsgnmBad2_MTHR(tmpCoeff, x)
		tmpSlice = image[p][i]
		tmpResid = tmpSlice[p] - tmpFitSlice[p]
		doUpdate
		Sleep/s sleepTime
		
		wmax = waveMax(tmpFitSlice)
		sigma = sqrt(variance(tmpResid))
		
		if(wmax < sigma)
			scaling[i] = sigma
			lostSignal[i] = 1
		else
			scaling[i] = wmax
			lostSignal[i] = 0
		endif
		
		tmpSlice = tmpSlice[p] / scaling[i]
		tmpFitSlice = tmpFitSlice[p] / scaling[i]
		normImage[][i] = tmpSlice[p]
		
		doUpdate
		Sleep/s sleepTime
	endfor 
	
	cleanupTmpObj()
end

function computeDifference(wave coeff, wave image, [variable n, variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime

	variable A
	n = paramisDefault(n) ? 0 : n
	Print "Computing difference using first fit spectre as reference"
	
	duplicate/o image, $(nameOfWave(image) + "_Diff")
	wave diffImage = $(nameOfWave(image) + "_Diff")
	wave lostSignal = $(nameOfWave(image) + "_LostSignal")

	
	duplicate/o/rmd=[][0] image, tmpSlice, tmpFitSlice
	redimension/n=(-1,0) tmpSlice, tmpFitSlice
	duplicate/o/rmd=[][0] coeff, tmpCoeff
	redimension/n=(-1,0) tmpCoeff
	
	// get n-th tmpSlice witout bg and CO
	tmpCoeff[] = coeff[p][n]
	tmpCoeff[0,1] = 0
	tmpCoeff[5] = 0

	tmpFitSlice = dsgnmBad2_MTHR(tmpCoeff, x)
	A = waveMax(tmpFitSlice)
	tmpFitSlice = tmpFitSlice[p] / A 
	
	display/n=tmpGraph tmpSlice, tmpFitSlice
	
	int i 
	for(i=0;i<dimsize(image,1);i++)
		tmpSlice = image[p][i]
		doupdate
		sleep/s sleepTime
		if(! lostSignal[i])
			diffImage[][i] = tmpSlice[p] - tmpFitSlice[p]
		endif
	endfor
	
	cleanupTmpObj()
end

function fitImageGauss(wave image)

	variable N = dimsize(image, 1)
	variable i
	wave tmpSlice = $getslice(image, 0, name="tmpSlice")
	wave w_coeff = $getglobalWave("W_coef")
	
	duplicate/o tmpSlice tmpx
	tmpx = x 
	
	make/o/n=(4,0) $(nameofWave(image) + "_GaussCoeff"), tmpCoeff
	
	make/o/n=100 tmpFitSlice
	copyscales	tmpSlice tmpFitSlice
	
	wave save_coeff = $(nameofWave(image) + "_GaussCoeff")
	
	display/n=tmpGraph tmpSlice, tmpFitSlice
	save_coeff = 0
	tmpCoeff = 0

	// 1st time is manual
	curvefit/Q gauss tmpSlice
	save_coeff[][0] = w_coeff[p]
	
	for(i=1;i<N;i++)
		tmpSlice[] = image[p][i]
		curvefit/Q gauss tmpSlice//d=tmpFitSlice 
		tmpFitSlice = W_coeff[0]+W_coeff[1]*exp(-((x-W_coeff[2])/W_coeff[3])^2)
		//tmpFitSlice = w_coeff[0] + w_coeff[1] * tmpFitSlice[p]
		concatenate/o {save_coeff, w_coeff}, tmpCoeff
		duplicate/o  tmpCoeff save_coeff
		doUpdate
		sleep/s 0.1
	endfor
	
	cleanupTmpObj()
end

function multiplyByRows(wave image, wave scaling)
	int i 
	for(i=0;i<dimsize(image,1);i++)
		image[][i] = image[p][i] * scaling[i] 
	endfor
end

function divideByRows(wave image, wave scaling)
	int i 
	for(i=0;i<dimsize(image,1);i++)
		image[][i] = image[p][i] / scaling[i] 
	endfor
end

function lineshapeCompatibility(wave coeff, wave image, [variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	string name = nameofWave(image)
	
	// generate resids
	string residName = name + "_RES"
	wave residImage = $residName
	histogram2D(residImage)
	wave hist = $(residName + "_Hist")
	fitImageGauss(hist)
	
	// normalize and make the difference
	removeBackground(coeff, image, sleepTime=sleepTime)
	wave noBg = $(name + "_NoBg")
	normalizeArea(coeff, noBg, sleepTime=sleepTime)
	wave normalized  = $(name + "_NoBg_Norm")
	computeDifference(coeff, normalized, sleepTime=sleepTime)
	
	// scale back the image
	wave diff = $(name + "_NoBg_Norm_Diff")
	duplicate/o diff $(name + "_FixLineShape_RES")
	wave scaling = $(name + "_NoBg_Norm_Scaling")
	wave resultImage = $(name + "_FixLineShape_RES")
	multiplyByRows(resultImage, scaling)
	
	// normlize by sigma
	duplicate/o residImage $(residName + "_Norm")
	duplicate/o resultImage $(name + "_FixLineShape_RES_Norm")
	wave residNorm = $(residName + "_Norm")
	wave resultNorm = $(name + "_FixLineShape_RES_Norm")
	wave sigma = $(name + "_RES_Hist_GaussWidth")
	dividebyRows(residNorm, sigma)
	dividebyRows(resultNorm, sigma)
	
	// display and save
	newimageGreyScale(residImage)
	newimageGreyScale(resultImage)
	newImageLSCompatibility(residNorm)
	newImageLSCompatibility(resultNorm)
end


function batchLineshapeAnalysis([variable sleepTime])
	sleepTime = paramIsDefault(sleepTime) ? 0 : sleepTime
	make/t/free targets = {"SE0523_100_2D", "SE0523_104_2D", "SE0523_108_2D", "SE0523_112_2D", "SE0523_120_2D", "SE0524_004_2D","SE0524_076_2D","SE0524_080_2D","SE0525_003_2D","SE0525_007_2D","SE0525_011_2D","SE0525_015_2D"}
	DFREF saveDFR = GetDataFolderDFR()		// Save
	SetDataFolder root:
	Print "batchLineshapeAnalysis"
	for(string target : targets)
		setDataFolder $("root:"+target+":")
		wave image = $(target)
		wave coeff = $(target + "_COEFF")
		lineshapeCompatibility(coeff, image, sleepTime=sleepTime)
	endfor
	
	
	SetDataFolder saveDFR		// and restore
end