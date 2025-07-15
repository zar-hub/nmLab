# Installation
Copy all the files to 
```
Documents\WaveMetrics\Igor Pro 9 User Files\User Procedures
```
and also copy `Dsgn_MTHR` to

```
Documents\WaveMetrics\Igor Pro 9 User Files\User Extensions
```

Include the packages inside Igor's Procedure window: press *Ctr-M* and add the following:
```
#include "fermiedge"
#include "DS_utils"
```
and press compile.
If it doesn't compile:
1. close and reopen Igor
2. MAKE SURE YOU ARE USING THE 32-bit VERSION OF IGOR