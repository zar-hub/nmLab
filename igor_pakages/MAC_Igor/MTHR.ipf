#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Please do not drag and drop this file - if you have, kill it, then move the ipf file to the User Procedure folder
// and call it from the main procedure window with #include "MTHR"
// version 2.0
// 14/04/2016
// author: Francesco Presel - f.presel@alice.it

// Contains some wrapper functions to provide non-threadsafe functions (for Gobal Fit xop)
// as well as the _MTHR-appended functions to make win functions work on mac.

//	function Dsgn_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgn(w,x)
//	end
//	function Dsgnnb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnnb(w,x)
//	end
//	function Dsgnmeas_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmeas(w,x)
//	end
//	function Dsgnmeasnb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmeasnb(w,x)
//	end
//	function Dsgnmead1_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmead1(w,x)
//	end
//	function Dsgnmead1nb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmead1nb(w,x)
//	end
//	function Dsgnmead2nb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmead2nb(w,x)
//	end
//	function Dsgnmead2_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmead2(w,x)
//	end
//	function Dsgnmegs_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmegs(w,x)
//	end
//	function Dsgnmegsnb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmegsnb(w,x)
//	end
//	function Dsgnmbas_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbas(w,x)
//	end
//	function Dsgnmbasnb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbasnb(w,x)
//	end
//	function Dsgnmbad1_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbad1(w,x)
//	end
//	function Dsgnmbad1nb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbad1nb(w,x)
//	end
//	function Dsgnmbad2nb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbad2nb(w,x)
//	end
//	function Dsgnmbad2_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbad2(w,x)
//	end
//	function Dsgnmbgs_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbgs(w,x)
//	end
//	function Dsgnmbgsnb_1THR(w,x):FitFunc
//	wave w
//	variable x
//		return dsgnmbgsnb(w,x)
//	end

#if !exists("dsgn_MTHR")
	threadsafe function Dsgn_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgn(w,x)
	end
	threadsafe function Dsgnnb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnnb(w,x)
	end
	threadsafe function Dsgnmeas_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmeas(w,x)
	end
	threadsafe function Dsgnmeasnb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmeasnb(w,x)
	end
	threadsafe function Dsgnmead1_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmead1(w,x)
	end
	threadsafe function Dsgnmead1nb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmead1nb(w,x)
	end
	threadsafe function Dsgnmead2nb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmead2nb(w,x)
	end
	threadsafe function Dsgnmead2_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmead2(w,x)
	end
	threadsafe function Dsgnmegs_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmegs(w,x)
	end
	threadsafe function Dsgnmegsnb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmegsnb(w,x)
	end
	threadsafe function Dsgnmbas_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbas(w,x)
	end
	threadsafe function Dsgnmbasnb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbasnb(w,x)
	end
	threadsafe function Dsgnmbad1_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbad1(w,x)
	end
	threadsafe function Dsgnmbad1nb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbad1nb(w,x)
	end
	threadsafe function Dsgnmbad2nb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbad2nb(w,x)
	end
	threadsafe function Dsgnmbad2_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbad2(w,x)
	end
	threadsafe function Dsgnmbgs_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbgs(w,x)
	end
	threadsafe function Dsgnmbgsnb_MTHR(w,x):FitFunc
	wave w
	variable x
		return dsgnmbgsnb(w,x)
	end

#endif