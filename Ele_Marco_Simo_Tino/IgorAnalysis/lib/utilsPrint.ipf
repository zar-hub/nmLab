function addEntriesToTBOX(tbox, coeff, err, [i])
	string tbox
	wave coeff, err
	int i
	
	string entry, lab
	variable j, N
	
	i = paramIsDefault(i) ? 0 : i
	N = dimSize(coeff, 0)
	
	duplicate/free/rmd=[][i] coeff coeff_1d
	redimension/n=(-1,0) coeff_1d
	duplicate/free/rmd=[][i] err err_1d
	redimension/n=(-1,0) err_1d
	
	for(j = 0; j < N; j++)
		
		// correct label for whitespaces
		lab = getDimLabel(coeff_1d, 0, j)
		lab = padString(lab, 12, 0x20) //0x20 is a space
		sprintf entry, "   %s %.3f ± %.3f", lab, coeff_1d[j], err_1d[j]
		appendText/n=$tbox entry
		
	endfor
end

function printCoeff(coeff)
	wave coeff
	int i, N
	string scoeff, app

	N = dimSize(coeff, 0)	
	scoeff = ""
	
	// add label
	//app = getDimLabel(coeff, 0, i)
	//app = padString(app, 12, 0x20) //0x20 is a space
	//scoeff += app
	
	for(i = 0; i < N; i++)
		sprintf app, "%.3f", coeff[i]
		app = padString(app, 9, 0x20) //0x20 is a space
		scoeff += app
	endfor
	
	print scoeff
end

function printInfo(w)
	wave w
	string str = "Rows"

	print "dim \t\t size \t\t offset \t delta \r"
	printf "%s \t %d \t\t %d \t\t %d \r", "Rows", dimSize(w, 0), dimOffset(w, 0), dimDelta(w, 0)
	printf "%s \t %d \t\t %d \t\t %d \r", "Cols", dimSize(w, 1), dimOffset(w, 1), dimDelta(w, 1)
end



