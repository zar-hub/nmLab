from PIL import Image
import numpy as np
from matplotlib import cm
from pathlib import Path
from matplotlib import pyplot as plt

# Input files
files = [
    "LEED_2025_04_23_006.tiff",
    "LEED_2025_04_23_007.tiff",
    "LEED_2025_04_23_008.tiff",
    "LEED_2025_04_23_009.tiff",
]

for file in files:
    # Load as grayscale
    img = Image.open(file)
    arr = np.array(img, dtype=np.float32)

    # Normalize to [0, 1]
    arr -= arr.min()
    arr /= arr.max()

    # Apply viridis colormap
    viridis = cm.get_cmap("viridis")
    colored = viridis(arr)[..., :3]  # drop alpha

    # Save viridis-colored image
    colored_img = Image.fromarray((colored * 255).astype(np.uint8), mode="RGB")
    out_path = Path(file).with_stem(Path(file).stem + "_viridis")
    colored_img.save(out_path)
    print(f"Saved: {out_path}")

    # Plot with axes and colorbar
    fig, ax = plt.subplots(figsize=(6, 5))
    im = ax.imshow(arr, cmap="viridis", origin="upper")

    # Save the figure (instead of showing)
    fig_path = Path(file).with_stem(Path(file).stem + "_viridis_plot").with_suffix(".png")
    plt.savefig(fig_path, dpi=500, bbox_inches="tight")
    plt.close(fig)

    print(f"Saved plot with axes: {fig_path}")