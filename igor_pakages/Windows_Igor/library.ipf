#pragma rtGlobals=1		// Use modern global access method.

// Please do not drag and drop this file - if you have, kill it, then move the ipf file to the User Procedure folder
// and call it from the main procedure window with #include "library"
// version 2.0
// 31/03/2016
// author: Francesco Presel - f.presel@alice.it


// This file contains some generic functions for Igor, such as shortcuts for
// original Igor functions which have particularly counter-intuitive syntax


function /t wavefromgraph(name,[index])
// This function returns a list of all
// waves displayed inside window NAME
string name
variable index
  return stringfromlist(index,wavelist("*",";",("WIN:"+name)))
end function

function /t wavelistfromgraph(name)
// This function returns a list of all
// waves displayed inside window NAME
string name
  return wavelist("*",";",("WIN:"+name))
end function

threadsafe function isnan(i)
// Like corresponding C function
variable i
return numtype(i)==2?1:0
end function

threadsafe function strcmp(a,b)
string a,b
return cmpstr(a,b)
end function

threadsafe function /t num2padstr(num,pad)
// like num2istr, but prepends 0s in order to make length >=pad
variable num,pad
string str=num2istr(num)
for(;strlen(str)<pad;)
	str="0"+str
endfor
return str
end function

threadsafe function AppendToWaveS(wv,s)
wave/t wv
string s
	variable last=numpnts(wv)
	insertpoints last,1,wv
	wv[last]=s
end function

threadsafe function AppendToWaveN(wv,n)
wave wv
variable n
	variable last=numpnts(wv)
	insertpoints last,1,wv
	wv[last]=n
end function

threadsafe function def_nint()
	return 10000
end function
threadsafe function def_nfwhm()
	return 10
end function

//threadsafe function /s pad_to_3 (i)
//variable i
//string padded
//if (i<0)
// padded="999"
//else
//if (i<10)
// padded="00"+num2istr(i)
//else
//if (i<100)
// padded="0"+num2istr(i)
//else
//if (i<1000)
// padded=num2istr(i)
//else
// padded="999"
//endif
//endif
//endif
//endif
//return padded
//end function

threadsafe function /t RemoveEndingN(str,rem)
//remove #ren characters from the end of str
string str
variable rem
	string cut=str
	variable i
	for(i=0;i<rem;i+=1)
		cut=removeending(cut)
	endfor
return cut
end function


threadsafe function parsenum(str,ind)
// returns number beginning at ind in string str
string str
variable ind
	string cchar=""
	string knum=""
	variable j=ind
	do //guarda che schifo mi tocca fare per greppare K\([0-9]+\)
	//	print "parsenum:",knum,";",cchar //DEBUG
		knum+=cchar
		cchar=str[j]
	//	print "parsenum2:",knum,";",cchar //DEBUG
		j+=1 //start reading just after after the K
	while (grepstring(cchar,"[0-9]")&&j<=strlen(str))
	return str2num(knum)
end function


//-----------------------//
//       UTILITIES       // 
//-----------------------//

threadsafe function/s name_of_peak(prefix,p)
// retrieve name of each wave hosting a single peak
string prefix
variable p
	return prefix+"_peak"+num2istr(p+1)
end function

function/t tracefromgraph(name)
string name
	return stringfromlist(0,TraceNameList(name, ";", 1+4 ))
end function

threadsafe function make_safe(wname,[npts])
//if wave $wname does not exist yet, create it; if needed extend it to npts points length
string wname
variable npts
	variable exist
	if (waveexists($wname))
		wave w=$wname
		variable n=numpnts(w)
		if(n<npts)
			exist=1
			insertpoints n,(npts-n),w
		else
			exist=0
		endif
	else
		exist=2
		make/o/n=(npts)/d $wname
	endif
return exist
end function


/////////////////////////////////////////////
//   PHYSICAL FORMULAE   //
/////////////////////////////////////////////

threadsafe function exposure_L(p,t,[torr])
variable p,t,torr
    return t*p*1e6*(torr?1:0.75006)
end function
