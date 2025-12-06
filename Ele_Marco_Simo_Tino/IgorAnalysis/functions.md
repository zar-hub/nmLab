# 📘 Parsed IPF Functions

| Function Name | Parameters | Description | File |
|---------------|-------------|--------------|------|
| `addEntriesToTBOX` | `tbox, coeff, err, [i]` |  | `utilsPrint.ipf` |
| `appendImageCScale` | `wave image` |  | `nmLabUtils.ipf` |
| `batchLineshapeAnalysis` | `[variable sleepTime]` |  | `nmLabLineshapeCompatibility.ipf` |
| `C1S_compPlusCO` | `w, x` |  | `nmLabRoutines.ipf` |
| `calibrateImageFLIN` | `string imageName, string FLName, string currentName` | Calibrates an image using - reference FL for image - corrects scaling - normalizes intensity using current in nA | `nmLabUtils.ipf` |
| `cleanupTmpObj` | `` |  | `utils.ipf` |
| `computeDifference` | `wave coeff, wave image, [variable n, variable sleepTime]` |  | `nmLabLineshapeCompatibility.ipf` |
| `copy_append` | `src, s` | copies the wave src into a new wave named src_name + s | `utils.ipf` |
| `copy_append_coeff` | `src, coeff, s` |  | `utils.ipf` |
| `copyAllX` | `string folderPath, string name` |  | `nmLabUtils.ipf` |
| `copyToFolder` | `string path, string name` |  | `utilsFolder.ipf` |
| `createCompAndCOConstrains` | `` |  | `nmLabRoutines.ipf` |
| `createFolder` | `wave wav, [wave initial_coeff]` |  | `nmLabUtils.ipf` |
| `deleteGraphs` | `strToDelete` |  | `utils.ipf` |
| `deleteWaves` | `strToDelete` |  | `utils.ipf` |
| `displace` | `src, dx` |  | `utils.ipf` |
| `divideByRows` | `wave image, wave scaling` |  | `nmLabLineshapeCompatibility.ipf` |
| `figure89mm` | `[string name, variable ratio, string host]` |  | `nmLabUtils.ipf` |
| `find_max` | `src` | returns the position of maximum intensity | `utils.ipf` |
| `fitC1S_CO` | `coeff, src, [res, wait, dbg, sleepTime]` | Expects an open graph to plot the fit process to. Data is appended to default axis names, so one should leave them for this function to handle and plot to other axis in the same graph. | `nmLabRoutines.ipf` |
| `fitC1S_comp` | `coeff, src, [res, wait, dbg, sleepTime]` | Expects an open graph to plot the fit process to. Data is appended to default axis names, so one should leave them for this function to handle and plot to other axis in the same graph. | `nmLabRoutines.ipf` |
| `fitC1S_compAndCO` | `coeff, src, [res, wait, dbg, sleepTime, quiet]` |  | `nmLabRoutines.ipf` |
| `fitC1S_simple` | `coeff, src, [res]` | Expects an open graph to plot the fit process to. Data is appended to default axis names, so one should leave them for this function to handle and plot to other axis in the same graph. | `nmLabRoutines.ipf` |
| `fitImageC1S` | `initial_coeff, src_image, fitType, [start, stop, offset, overclock, sleepTime, quiet, duplicateInFolder]` |  | `nmLabUtils.ipf` |
| `fitImageGauss` | `wave image` |  | `nmLabLineshapeCompatibility.ipf` |
| `getBinStd` | `wave w` |  | `utils.ipf` |
| `getCompatibleConstrains` | `hold, constrains` | Keeps only constrains that are compatible with a give hold string. Generates a copy of constrains | `utils.ipf` |
| `getGlobalString` | `string name, [string folder, string ifUndef]` |  | `utils.ipf` |
| `getGlobalWave` | `string name, [string folder, wave like]` | Get / create a wave with (name) duplicating [like] in the folder [folder] | `utils.ipf` |
| `getNumberFrom` | `string s, int pos` | gets the number from the string s starting at position pos. Only works with integer numbers | `utils.ipf` |
| `getSlice` | `image, i, [name]` |  | `utilsImage.ipf` |
| `histogram2D` | `wave image` |  | `nmLabUtils.ipf` |
| `imageNoiseStyle` | `image` |  | `utilsImage.ipf` |
| `imageSlice` | `image, offset` |  | `utilsImage.ipf` |
| `lineshapeCompatibility` | `wave coeff, wave image, [variable sleepTime]` |  | `nmLabLineshapeCompatibility.ipf` |
| `MakeEdgesWave` | `centers, edgesWave` |  | `utils.ipf` |
| `MenuItemFitC1STR` | `` |  | `nmLabUtils.ipf` |
| `moveToFolder` | `string path, string name` |  | `utilsFolder.ipf` |
| `multiplyByRows` | `wave image, wave scaling` |  | `nmLabLineshapeCompatibility.ipf` |
| `mystrsearch` | `string s, string c, int start` | return -1 on failure | `utils.ipf` |
| `new_append` | `src, s` | creates a new empty wave with the same size as src named src_name + s | `utils.ipf` |
| `new_append_coeff` | `src, coeff, s` | creates a new wave of coefficients from coeff. the name is src_name + s | `utils.ipf` |
| `NewImageGreyScale` | `wave image` |  | `nmLabLineshapeCompatibility.ipf` |
| `NewImageLSCompatibility` | `wave image` |  | `nmLabLineshapeCompatibility.ipf` |
| `normalize` | `src` |  | `utils.ipf` |
| `normalizeArea` | `wave coeff, wave image, [variable sleepTime]` |  | `nmLabLineshapeCompatibility.ipf` |
| `plotCoeff` | `coeff` |  | `utils.ipf` |
| `plotPeaksC1S_comp` | `coeff, res` |  | `nmLabRoutines.ipf` |
| `plotPeaksC1S_compAndCO` | `coeff, res, [plot, app]` | plot 	= "comp" (default) plot each component separately 			= "c1s" plot peak used in CO estimation 			= "bg" plot only bg and CO peak 			= "all" app = 1 append the waves to the current graph | `nmLabRoutines.ipf` |
| `printCoeff` | `coeff` |  | `utilsPrint.ipf` |
| `printInfo` | `w` |  | `utilsPrint.ipf` |
| `removeAllX` | `string name` |  | `nmLabUtils.ipf` |
| `removeBackground` | `wave coeff, wave image, [variable sleepTime]` |  | `nmLabLineshapeCompatibility.ipf` |
| `sBWO` | `s1, s2` | string Bit Wise Or assume s1 is longer than s2 | `utils.ipf` |
| `setLabelsFromString` | `wave w, wave /T labels` |  | `utils.ipf` |
| `startAnalysis` | `wave image, wave FL` |  | `nmLabUtils.ipf` |
| `TickMeV` | `val` |  | `utils.ipf` |
| `TransAx_eVtoCm_1` | `w, val` |  | `utils.ipf` |
| `updateAndSleep` | `variable t` |  | `utils.ipf` |
| `UserPauseCheck` | `graphName, autoAbortSecs` |  | `utils.ipf` |
| `UserPauseCheck_ContButtonProc` | `ctrlName` |  | `utils.ipf` |
| `waveToHoldString` | `wave w` |  | `utils.ipf` |
