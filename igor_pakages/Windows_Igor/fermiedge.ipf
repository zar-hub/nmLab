#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function Fermi_edge(w,x) : FitFunc 

	// Utile: allineare gli spettri all'EF (parametro 5)
	//Scala energie negative:
	//setscale x, -pnt2x(fermispec,0),-pnt2x(fermispec,numpnts(fermispec)-1), fermispec

          wave w //coefficient wave
          variable x // the independent variable
	variable counter,nstep 
	variable gg,gg4,sigsq,step,x0,integ,ff,factor
	variable k_B= 8.61703e-05 //Boltzmann constant (units eV/K)
  
	// w[0] = intercept of the linear background 
	// w[1] = slope  of the linear background
	// w[2] = absolute temperature
	// w[3] = width of the gaussian entering the convolution (2.35482*sigma)
	// w[4] = width of the Fermi roll-off (the curves report the # of COUNTS, it is not normalized))
	// w[5] = Fermi energy (eV)
  
	w[3]=abs(w[3])
	w[4]=abs(w[4])
	gg=w[3]/2.35482
	sigsq=2*gg*gg
	step=0.2*min(w[3],(3.79e-4*w[2])) //3.79 stems from k_B*(ln((1/.1)-1)-ln((1/.9)-1))

	/////// EXPLANATION: the step has to be chosen as the minimum between the width of the Gaussian function with whicg
	// the Fermi function is convoluted, and the amplitude of the Fermi function between 10% and 90% of the edge height, 
	// i.e between x1 and x2, where x1 and x2 are such that
	/// 1/ [1+exp((E_F-x1)/kT) ]= 0.12   at 0.12 x  edge height
	///   1/ [1+exp((E_F-x2)/kT) ]= 0.88   at 0.88 x edge height

	gg4 = 4*gg //estimated linewidth of the Fermi function (90 to 10%)
	nstep=ceil(2*gg4/step)   // # of steps (divide the interval)
	nstep+=(1-mod(nstep,2))
	x0=-gg4
	counter=1 //integration index
	integ=0

	variable result  
	//now let's assign a value to the output ("result"), according to the value of the gaussian width (w[3])
	if (w[3]!=0)
		do
			ff=1/(1+exp((x-w[5]-x0)/(k_B*w[2])))    // Fermi distribution 
			ff*=exp(-x0*x0/sigsq)   //  convolution with a gaussian (start by multiplying by exp(-8))

				if ((counter==1) || (counter==nstep))  // first or last point
					factor=1  //  to understand the choice of "factor", see the SIMPSON's RULE for numerical integration 
				else
				if (mod(counter,2))  // even points
                    factor=4
				else   // odd points
					factor=2
				endif
				endif
      
			integ+=factor*ff
			x0+=step
			counter+=1
		while (counter<=nstep)

	result = w[4]*integ*step/(3*sqrt(2*Pi)*gg)+w[0]+w[1]*x
	else
	// if w[3] (the gaussian width) is 0, we go back to a perfect Fermi distribution (no convolution with a gaussian)
	result = w[4]/(1+exp((x-w[5]-x0)/(k_B*w[2])))
	endif

	return result
end 



function Fermi_edgeLDOS(w,x) : FitFunc 

	// Utile: allineare gli spettri all'EF (parametro 5)
	//Scala energie negative:
	//setscale x, -pnt2x(fermispec,0),-pnt2x(fermispec,numpnts(fermispec)-1), fermispec

          wave w //coefficient wave
          variable x // the independent variable
	variable counter,nstep 
	variable gg,gg4,sigsq,step,x0,integ,ff,factor
	variable k_B= 8.61703e-05 //Boltzmann constant (units eV/K)
  
	// w[0] = intercept of the linear background 
	// w[1] = slope  of the linear background
	// w[2] = absolute temperature
	// w[3] = width of the gaussian entering the convolution (2.35482*sigma)
	// w[4] = width of the Fermi roll-off (the curves report the # of COUNTS, it is not normalized))
	// w[5] = Fermi energy (eV)
	// w[6] = offset of the linear DOS at EF, at EF
	// w[7] = slope of the linear DOS at EF
  
	w[3]=abs(w[3])
	w[4]=abs(w[4])
	gg=w[3]/2.35482
	sigsq=2*gg*gg
	step=0.2*min(w[3],(3.79e-4*w[2])) //3.79 stems from k_B*(ln((1/.1)-1)-ln((1/.9)-1))

	/////// EXPLANATION: the step has to be chosen as the minimum between the width of the Gaussian function with whicg
	// the Fermi function is convoluted, and the amplitude of the Fermi function between 10% and 90% of the edge height, 
	// i.e between x1 and x2, where x1 and x2 are such that
	/// 1/ [1+exp((E_F-x1)/kT) ]= 0.12   at 0.12 x  edge height
	///   1/ [1+exp((E_F-x2)/kT) ]= 0.88   at 0.88 x edge height

	gg4 = 4*gg //estimated linewidth of the Fermi function (90 to 10%)
	nstep=ceil(2*gg4/step)   // # of steps (divide the interval)
	nstep+=(1-mod(nstep,2))
	x0=-gg4
	counter=1 //integration index
	integ=0

	variable result  
	//now let's assign a value to the output ("result"), according to the value of the gaussian width (w[3])
	if (w[3]!=0)
		do
			ff=1/(1+exp((x-w[5]-x0)/(k_B*w[2])))   *   ( w[6] + w[7]*(x-w[5]-x0) )  // Fermi distribution  * L DOS 
			ff*=exp(-x0*x0/sigsq)   //  convolution with a gaussian (start by multiplying by exp(-8))

				if ((counter==1) || (counter==nstep))  // first or last point
					factor=1  //  to understand the choice of "factor", see the SIMPSON's RULE for numerical integration 
				else
				if (mod(counter,2))  // even points
					factor=4
				else   // odd points
					factor=2
				endif
			endif
      
			integ+=factor*ff
			x0+=step
			counter+=1
		while (counter<=nstep)

	result = w[4]*integ*step/(3*sqrt(2*Pi)*gg)+w[0]+w[1]*x
	else
	// if w[3] (the gaussian width) is 0, we go back to a perfect Fermi distribution (no convolution with a gaussian)
	result = w[4]/(1+exp((x-w[5]-x0)/(k_B*w[2])))
	endif

	return result
end 