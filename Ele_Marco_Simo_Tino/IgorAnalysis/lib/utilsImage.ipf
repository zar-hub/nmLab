function/s getSlice(image, i, [name])
	wave image
	variable i
	
	string name
	if(paramisDefault(name))
		name = nameofWave(image)
		name = name + "_slice" + num2str(i)
	endif 
	
	// duplicate also copies the scaling
	duplicate/o/rmd=[][i] image $name 
	
	// redimention to get a 1D wave
	redimension/n=(-1,0) $name
	return name
	
	// Maybe this is another way to do it using copyscale
	//	Make/o/n=(N) fitres
	//	copyscales/P image fitres
end

function displayImageSlices(image, offset)
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

function imageNoiseStyle(image)
	wave image 
	variable N = dimsize(image, 0)
	variable i
	
	// assume graph is open
	for(i=0; i<dimSize(image, 1); i++)
	//	modifygraph
	endfor
	
end