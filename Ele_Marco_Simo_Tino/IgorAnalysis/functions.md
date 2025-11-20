# 📘 Parsed IPF Functions

| Function Name | Parameters | Description | File |
|---------------|-------------|--------------|------|
| `addEntriesToTBOX` | `tbox, coeff, err, [i]` |  | `utilsPrint.ipf` |
| `C1S_compPlusCO` | `w, x` |  | `nmLabRoutines.ipf` |
| `calibrateImageFLIN` | `string imageName, string FLName, string currentName` | Calibrates an image using - reference FL for image - corrects scaling - normalizes intensity using current in nA | `nmLabUtils.ipf` |
| `copyAllX` | `string folderPath, string name` |  | `nmLabUtils.ipf` |
| `copyToFolder` | `string path, string name` |  | `utilsFolder.ipf` |
| `createFolder` | `wave wav, [wave initial_coeff]` |  | `nmLabUtils.ipf` |
| `displace` | `src, dx` |  | `utils.ipf` |
| `find_max` | `src` | returns the position of maximum intensity | `utils.ipf` |
| `fitC1S_CO` | `coeff, src, [res, wait, dbg, sleepTime]` | Expects an open graph to plot the fit process to. Data is appended to default axis names, so one should leave them for this function to handle and plot to other axis in the same graph. | `nmLabRoutines.ipf` |
| `fitC1S_comp` | `coeff, src, [res, wait, dbg, sleepTime]` | Expects an open graph to plot the fit process to. Data is appended to default axis names, so one should leave them for this function to handle and plot to other axis in the same graph. | `nmLabRoutines.ipf` |
| `fitC1S_compAndCO` | `coeff, src, [res, wait, dbg, sleepTime]` |  | `nmLabRoutines.ipf` |
| `fitC1S_simple` | `coeff, src, [res]` | Expects an open graph to plot the fit process to. Data is appended to default axis names, so one should leave them for this function to handle and plot to other axis in the same graph. | `nmLabRoutines.ipf` |
| `fitImageC1S` | `initial_coeff, src_image, fitType, [start, stop, offset, overclock]` |  | `nmLabUtils.ipf` |
| `getNumberFrom` | `string s, int pos` | gets the number from the string s starting at position pos. Only works with integer numbers | `utils.ipf` |
| `imageSlice` | `image, offset` |  | `utilsImage.ipf` |
| `moveToFolder` | `string path, string name` |  | `utilsFolder.ipf` |
| `normalize` | `src` |  | `utils.ipf` |
| `plotCoeff` | `coeff` |  | `utils.ipf` |
| `plotPeaksC1S_comp` | `coeff, res` |  | `nmLabRoutines.ipf` |
| `plotPeaksC1S_compAndCO` | `coeff, res, [plot, app]` | plot 	= "comp" (default) plot each component separately 			= "c1s" plot peak used in CO estimation 			= "bg" plot only bg and CO peak 			= "all" app = 1 append the waves to the current graph | `nmLabRoutines.ipf` |
| `printCoeff` | `coeff` |  | `utilsPrint.ipf` |
| `printInfo` | `w` |  | `utilsPrint.ipf` |
| `removeAllX` | `string name` |  | `nmLabUtils.ipf` |
| `setLabelsFromString` | `wave w, wave /T labels` |  | `utils.ipf` |
| `startAnalysis` | `wave image, wave FL` |  | `nmLabUtils.ipf` |
| `TransAx_eVtoCm_1` | `w, val` |  | `utils.ipf` |
| `updateAndSleep` | `variable t` |  | `utils.ipf` |
| `UserPauseCheck` | `graphName, autoAbortSecs` |  | `utils.ipf` |
| `UserPauseCheck_ContButtonProc` | `ctrlName` |  | `utils.ipf` |
