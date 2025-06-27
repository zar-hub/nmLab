#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "MTHR" // homogeneous names between Mac and Win

// Please do not drag and drop this file - if you have, kill it, then move the ipf file to the User Procedure folder
// and call it from the main procedure window with #include "DS_utils"
// version 2.0
// 31/03/2016
// author: Francesco Presel - f.presel@alice.it

// NOTE: since version 2.0, the integral of dsgn functions is calculated as shown in file dsgnarea.pdf.
// Note that the values calculated before this update should be recalculated.
// The file has been renamed to distinguish this version from the previous one

#include "library"

function dsgn_coef(func) //returns number of coefs/peak of a certain ds function
string func
	if       (grepstring(func,"^dsgnm[a-zA-Z]as.*"))
		return 2
	elseif (grepstring(func,"^dsgnm[a-zA-Z]gs.*"))
		return 3
	else
		return 5
	endif
end function

function dsgn_coef_fname(func,npk,ncoef,coef)
// parses name of the dsgn function; returns (via dsgn_coef_index) the value of the desired coefficient,
// i.e. L,A,G,area,absolute BE
string func
wave coef
variable npk,ncoef //npk>=1;0<=ncoef<=4
//	print func,npk,ncoef //DEBUG
	variable re=grepstring(func,"dsgnm[eE].*")
	variable a=grepstring(func,"dsgnm...[aA].*")
	if (ncoef<0||ncoef>4||npk<1)
//		print "w" //DEBUG
		return nan
	elseif (ncoef<3||(ncoef==3&&a)||(ncoef==4&&(npk==1||!re)))
//	print "a" //DEBUG
		return coef[dsgn_coef_index_fname(func,npk,ncoef,coef)]
	elseif (ncoef==3) // explicit area
//	print "b" //DEBUG
		return coef[dsgn_coef_index_fname(func,npk,3,coef)]*ds_unit_area(coef[dsgn_coef_index_fname(func,npk,0,coef)],coef[dsgn_coef_index_fname(func,npk,1,coef)],coef[dsgn_coef_index_fname(func,npk,2,coef)])
	else //coef==4 && npk>1 && re
//	print "c" //DEBUG
		return coef[dsgn_coef_index_fname(func,1,4,coef)]-coef[dsgn_coef_index_fname(func,npk,4,coef)]
	endif
end function

function write_dsgn_coef_fname(write,func,npk,ncoef,coef)
// parses name of the dsgn function; stores (via dsgn_coef_index) the provided value into the desired coefficient,
// after converting it to the appropriate quantity (input is L,A,G,area,absolute BE).
// Attention: if using dsgnm[eE] functions, store BE of first peak first!
string func
wave coef
variable npk,ncoef //npk>=1;0<=ncoef<=4
variable write
	variable re=grepstring(func,"dsgnm[eE].*")
	variable a=grepstring(func,"dsgnm...[aA].*")
	if (ncoef<0||ncoef>4||npk<1)
		return nan
	elseif (ncoef<3||(ncoef==3&&a)||(ncoef==4&&(npk==1||!re)))
//	print "a" //DEBUG
		coef[dsgn_coef_index_fname(func,npk,ncoef,coef)]=write
	elseif (ncoef==3) // explicit area
//	print "b" //DEBUG
		coef[dsgn_coef_index_fname(func,npk,3,coef)]=write/ds_unit_area(coef[dsgn_coef_index_fname(func,npk,0,coef)],coef[dsgn_coef_index_fname(func,npk,1,coef)],coef[dsgn_coef_index_fname(func,npk,2,coef)])
	else //coef==4 && npk>1 && re
//	print "c" //DEBUG
		coef[dsgn_coef_index_fname(func,npk,4,coef)]=coef[dsgn_coef_index_fname(func,1,4,coef)]-write
	endif
	return 0
end function

function dsgn_coef_index_fname(func,npk,ncoef,coef)
// parses name of the dsgn function; returns (via dsgn_coef_index) the coordinate of the desired coefficient
string func
wave/z coef
variable npk,ncoef //npk>=1;0<=ncoef<=4
	make/n=3/free fix={grepstring(func,"dsgnm.([awlAWL][sS]|[gG][dD]).*"),grepstring(func,"dsgnm.([Aa][sS]|[wlgWLG][dD]).*"),grepstring(func,"dsgnm.([awgAWG][sS]|[lL][dD]).*")}
	variable nsame=sum(fix)
	variable ndiff=5-nsame
	variable nbg
	if (grepstring(func,"dsgnm...[aA]?nb.*"))
		nbg=0
	elseif (grepstring(func,"dsgnm...[aA]?sh.*"))
		nbg=3
	elseif (grepstring(func,"dsgnm...[aA]?p.*"))
		if (!waveexists(coef))
			nbg=nan
		else
			nbg=nan //NOT YET IMPLEMENTED
		endif
	else
		nbg=2
	endif
	variable index=nbg
	return dsgn_coef_index(nbg,npk,ncoef,fix)
end function

function dsgn_coef_index_flag(nbg,npk,ncoef,same)
// returns (via dsgn_coef_index) the coord of the desired coefficient.
variable nbg,npk,ncoef //npk>=1;0<=ncoef<=4
string same // string with binary flag for L,A,G: 1 for same, 0 for different
	variable i=str2num(same)
	make/n=3/free/o flag=0
	flag[0]=(i>=100)
	i=mod(i,100)
	flag[1]=(i>=10)
	i=mod(i,10)
	flag[2]=(i>0)
	return dsgn_coef_index(nbg,npk,ncoef,flag)
end function

function dsgn_coef_index(nbg,npk,ncoef,flag)
wave flag
variable npk,ncoef,nbg //npk>=1;0<=ncoef<=4
	variable nsame=sum(flag)
	variable step=5-nsame
//	print nsame,flag[ncoef]
	if(ncoef<0)
		return nan
	elseif(ncoef<3)
		variable nbgsame=nbg+nsame
		variable ncoefdiff=!ncoef ? 0 : (ncoef-sum(flag,0,(ncoef-1)))
//		print flag
//		print sum(flag,0,(ncoef-1))
		return nbg+(flag[ncoef] ? ncoef-ncoefdiff : (ncoefdiff+nsame+step*(npk-1)))
	elseif(ncoef<5)
//		print "test"
		return nbg+ncoef+step*(npk-1)
	else
		return nan
	endif
end function	

///AREA

threadsafe function ds_normalize(l,a)
variable l,a
	return ds_unit_area(l,a,0.1)
end function

threadsafe function ds_unit_area(l,a,g)
variable l,g,a
make /free/o/n=5 ds_area_tmp
ds_area_tmp[0]=l
ds_area_tmp[1]=a
ds_area_tmp[2]=g
ds_area_tmp[3]=1
ds_area_tmp[4]=0
variable ar=area_asym(ds_area_tmp)
killwaves/z ds_area_tmp
return ar
end function

threadsafe function area_asym(coeftemp,[nbg])
wave coeftemp
variable nbg
	variable int
	if (coeftemp[3+nbg]==0)
		int=0 //be a bit quicker in case of null peak
	else
		if(coeftemp[1+nbg]==0)
			int=1
		else
			variable a=abs(coeftemp[1+nbg])
//			int=1+a*4.36184+a^2*5.22668+a^3*1941.57-a^4*46188.4+a^5*636780-a^6*5.32424e6+a^7*2.85688e7-a^8*9.86011e7+a^9*2.12705e8-a^10*2.61665e8+a^11*1.41608e8
			int=1+a*3.4083+a^2*5.4057+a^3*5.2195+a^4*3.3921+a^5*1.3757
		endif
		int*=abs(coeftemp[3+nbg]*pi*coeftemp[0+nbg]*0.5)
	endif
	return int
end function //area_asym

