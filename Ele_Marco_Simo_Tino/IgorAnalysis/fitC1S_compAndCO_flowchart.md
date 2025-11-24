# 🔬 Logic Flow: fitC1S_compAndCO Function

This table summarizes the main sequential and conditional blocks involved in fitting C1s and CO spectroscopic peaks.

| Phase | Step | Logic/Action Summary | Hold/Constrains Status |
| :--- | :--- | :--- | :--- |
| **1. Initialization** | **Setup** | Handle parameters (`dbg`, `quiet`, `res`), initialize working waves (`tcoeff`, `startingCoeff`, components), set up graph visualization, and load global constraints/hold strings. | All initial coefficients are fixed (held). |
| | **Wait Check** | If `wait` parameter is not default, **Return 0**. | N/A |
| **2. CO Peak Detection** | **A0: Initial CO Fit** | Fit **Position, Intensity, and Gaussian width** of the CO peak. Optimize also intensity of C1s peaks. | Fixed lineshape of C1s and CO Lorentian and Asym. |
| | **A1: Detection Logic** | **IF CO Intensity < Threshold:** Fix all CO parameters (`holdCO` = "00"+"11111"), reset CO Position. **ELSE (Peak Found):** Set `holdCO` to fix CO lineshape, but allow **Intensity** to be fitted. | Determines the **`holdCO`** for all subsequent steps. |
| | **(IF DETECTED) A1: Final Fit** | Final fit iteration to optimize **Background and CO peak lineshape** based on the detection result. Let **all the Lineshape, Position and Intensity free**. | N/A |
| **3. C1S Refinement** | **B0: C1S Peak Detection** | Loop through C1S peaks (Note that the Intensity was fitted before). **IF Intensity < Threshold:** Reset position and update **`holdPeaks`** to fix *all* parameters for that specific peak. | Sets **`holdPeaks`** for all subsequent C1S fits. |
| | **B1: Fit Lineshapes** | Fit **Lineshape parameters** (Lor, Asym, Gau) for all *non-removed* C1S peaks. | Position of C1s peaks, and all CO parameters fixed. Background is free. |
| | **B2: Tune Lineshapes** | **No fit.** Manually update `tcoeff` by applying only a **fraction** ($\le 80\%$) of the calculated change ($\Delta$) to the lineshape parameters. | N/A (Manual update/Damping). |
| | **B3: Fit Pos/Intensities**| Fit **Position and Intensity** for all *non-removed* C1S peaks. | Lineshape parameters for C1s peaks and all parameters for CO are held. Background is free |
| | **B4: Tune Positions** | **No fit.** Manually update `tcoeff` by applying only a **fraction** ($50\%$) of the calculated change ($\Delta$) to the position parameters. | N/A (Manual update/Damping). |
| **4. Final Optimization** | **B5: Final Fit** | Fit **Linear Background parameters** and **Intensities** of all peaks (CO and C1S). | All lineshape and position parameters (determined in steps A0-B4) are fixed/held. |
| **5. Conclusion** | **Save** | **IF NOT debug mode:** Save the final `tcoeff` back to the output wave `coeff`. | N/A |
