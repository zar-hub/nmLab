import tkinter as tk
from tkinter import filedialog
import numpy as np
import scipy.ndimage
from PIL import Image
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import RegularPolygon
from matplotlib.collections import PatchCollection
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from Widgets import *
from TiltCorrection import *  
import math
import pickle
import os


# --- Color Constants ---
DARK_GREY = "#2e2e2e"
LIGHT_GREY = "#cccccc"
WHITE = "#ffffff"
BLUE = "#007bff"
GRID_COLOR = "#ff00ff" # Magenta for grid

# --- Main Application ---
# Global references
original_image = None
processed_image = None
pan_zoom1 = pan_zoom2 = None
hex_grid1 = hex_grid2 = None
pathCollection1 = pathCollection2 = None
draggable_grid = None
filename = None
ax1 = ax2 = None

def_style = {
    "bg" : DARK_GREY,
    "fg" : WHITE,
    "font" : ("Helvetica", 11)
}

def imageMap(original_image, xc, yc, beta_in, k_in, kappa_in, xscale, rotation):
    # Calculate the mapping from the original
    # image to the corrected one
    shape = np.array(original_image).shape
    h, w  = shape[0], shape[1]
    Y, X = np.indices((h, w))

    # Apply rotation and zoom to original image  
    originalBuff = np.array(original_image)
    originalBuff = scipy.ndimage.zoom(originalBuff, [1, xscale])
    originalBuff = scipy.ndimage.rotate(originalBuff, rotation)

    X, Y = inverse_transform_coordinates(X, Y, xc, yc, beta_in, k_in, kappa_in)

    # Apply the transformation
    outBuff = scipy.ndimage.map_coordinates(originalBuff, [Y, X])
    return outBuff


def load_image():
    global pan_zoom1, pan_zoom2, hex_grid1, hex_grid2, draggable_grid, original_image
    global ax1, ax2, filename
    file_path = filedialog.askopenfilename()
    if not file_path: return

    try:
        original_image = Image.open(file_path)
    except IOError:
        return

    filename = os.path.basename(file_path)  # Extract filename
    filename, _ = os.path.splitext(filename)
    point_name.delete("1.0", tk.END)          # Clear Text widget
    point_name.insert(tk.END, filename)     

    # just copy the original image for the moment
    processed_image = original_image
    
    # Clear UI
    for widget in plot_frame.winfo_children():
        widget.destroy()

    # Create figure and axes
    fig, (ax1, ax2) = plt.subplots(1, 2)
    fig.patch.set_facecolor(DARK_GREY)
    plt.style.use('dark_background')

    # Display images
    ax1.imshow(original_image)
    ax1.set_title('Original')
    ax2.imshow(processed_image)
    ax2.set_title('Corrected')
    ax1.set_aspect('equal', adjustable='box')
    ax2.set_aspect('equal', adjustable='box')


    # Create Hex Grids
    #create_hex_grids(original_image.size, ax1, ax2)
    create_hex_grid_in_hexagon(original_image.size, ax1, ax2)
    # Attach pan and zoom
    pan_zoom1 = PanAndZoom(ax1, original_image)
    pan_zoom2 = PanAndZoom(ax2, processed_image)
    pan_zoom1.basename = filename
    pan_zoom2.basename = filename
    
    # Attach draggable grid controller
    canvas = FigureCanvasTkAgg(fig, master=plot_frame)
    draggable_grid = DraggableHexGrid(
        hex_grid1, hex_grid2,
        pathCollection1, pathCollection2,
        canvas
    )

    # Configure plots
    for ax in [ax1, ax2]:
        for spine in ax.spines.values():
            spine.set_edgecolor(DARK_GREY)

    plt.tight_layout()
    canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
    canvas.draw()
    toggle_grid() # Update grid visibility based on checkbox
    print("Loaded File", file_path)

def create_hex_grids(image_size, ax1, ax2, hex_radius = 50):
    """Creates normal and fisheye-distorted hexagon grids."""
    global hex_grid1, hex_grid2, pathCollection1, pathCollection2
    w, h = image_size
    
    # Generate hexagon centers
    cols = int(w / (hex_radius * 1.5)) + 2
    rows = int(h / (hex_radius * np.sqrt(3))) + 2
    x_coords = np.arange(-1, cols) * hex_radius * 1.5
    y_coords = np.arange(-1, rows) * hex_radius * np.sqrt(3)
    
    offsets = []
    for i, x in enumerate(x_coords):
        for y in y_coords:
            offsets.append((x, y if i % 2 == 0 else y + hex_radius * np.sqrt(3) / 2))
    offsets = np.array(offsets)

    # --- Grid 1: Normal ---
    patches1 = [RegularPolygon(offset, 6, radius=hex_radius, orientation=np.pi / 2) for offset in offsets]
    # pathCollection1 = ax1.scatter(offsets[:,0], offsets[:,1], color=GRID_COLOR, marker = '.')

    hex_grid1 = PatchCollection(patches1, facecolors='none', edgecolors=GRID_COLOR, linewidth=1, alpha=0.3)
    ax1.add_collection(hex_grid1)

    # --- Grid 2: Fisheye ---
    # We create normal polygons but place them on the fisheye axis.
    # The axis transform handles the distortion during rendering. This is simpler
    # than transforming each vertex for this effect.
    patches2 = [RegularPolygon(offset, 6, radius=hex_radius, orientation=np.pi / 2) for offset in offsets]
    hex_grid2 = PatchCollection(patches2, facecolors='none', edgecolors=GRID_COLOR, linewidth=1, alpha=0.7)
    ax2.add_collection(hex_grid2)
    # pathCollection2 = ax2.scatter(offsets[:,0], offsets[:,1], color=GRID_COLOR, marker = '.')

def create_hex_grid_in_hexagon(image_size, ax1, ax2, grid_radius=5, hex_radius=30):
    """
    Creates a hexagonal grid of hexagons centered on the screen.

    Instead of filling a rectangular area, this function generates hexagon
    coordinates in a hexagonal pattern around a central point.

    Args:
        image_size (tuple): (width, height) of the canvas/figure.
        ax1 (matplotlib.axes.Axes): The axes for the normal grid.
        ax2 (matplotlib.axes.Axes): The axes for the "fisheye" grid.
        grid_radius (int): The radius of the main hexagon, measured in the number
                           of smaller hexagon cells from the center to the edge.
        hex_radius (float): The radius (size) of an individual hexagon cell.
    """
    global hex_grid1, hex_grid2, pathCollection1, pathCollection2
    w, h = image_size
    center_x, center_y = w / 2, h / 2

    offsets = []
    # We use axial coordinates (q, r) to generate a hexagonal shape.
    # This is a more natural way to define a hexagonal area than using cartesian (x,y) loops.
    for q in range(-grid_radius, grid_radius + 1):
        # For each column 'q', we calculate the valid row range 'r'.
        r1 = max(-grid_radius, -q - grid_radius)
        r2 = min(grid_radius, -q + grid_radius)
        for r in range(r1, r2 + 1):
            # Convert the axial (q, r) coordinates to cartesian (x, y) pixel coordinates.
            # This formula is for "flat-top" hexagons, which matches the orientation=np.pi/2.
            x = hex_radius * (3.0 / 2.0 * q)
            y = hex_radius * (np.sqrt(3) / 2.0 * q + np.sqrt(3) * r)
            
            # We add the screen center coordinates to shift the entire grid.
            # This makes the grid "spawn" from the center of the screen.
            offsets.append((x + center_x, y + center_y))

    offsets = np.array(offsets)

    # --- Grid 1: Normal Grid (on the left subplot) ---
    # Create a polygon patch for each hexagon center calculated.
    # The orientation=np.pi/2 makes the hexagons "flat-top".
    patches1 = [RegularPolygon(offset, numVertices=6, radius=hex_radius, orientation=np.pi / 2) for offset in offsets]
    hex_grid1 = PatchCollection(patches1, facecolors='none', edgecolors=GRID_COLOR, linewidth=1, alpha=0.5)
    ax1.add_collection(hex_grid1)

    # This scatter plot draws a small dot at the center of each hexagon.
    pathCollection1 = ax1.scatter(offsets[:, 0], offsets[:, 1], color=GRID_COLOR, marker='.')

    # --- Grid 2: Fisheye Grid (on the right subplot) ---
    # The original code placed a second grid on another axis for a fisheye effect.
    # The fisheye distortion itself would be handled by a custom transform on the `ax2` axis,
    # which is not included here. This code just draws the same grid on the second plot.
    patches2 = [RegularPolygon(offset, numVertices=6, radius=hex_radius, orientation=np.pi / 2) for offset in offsets]
    hex_grid2 = PatchCollection(patches2, facecolors='none', edgecolors=GRID_COLOR, linewidth=1, alpha=0.7)
    ax2.add_collection(hex_grid2)
    pathCollection2 = ax2.scatter(offsets[:, 0], offsets[:, 1], color=GRID_COLOR, marker='.')

    # It's good practice to return the created collections.
    return hex_grid1, pathCollection1, hex_grid2, pathCollection2

def toggle_grid():
    if hex_grid1 and hex_grid2:
        is_visible = show_grid_var.get()
        hex_grid1.set_visible(is_visible)
        hex_grid2.set_visible(is_visible)
        pathCollection1.set_visible(is_visible)
        pathCollection2.set_visible(is_visible)
        if hex_grid1.figure.canvas:
            hex_grid1.figure.canvas.draw_idle()

def toggle_move_grid():
    if pan_zoom1 is None or pan_zoom2 is None: return
    move_grid = move_grid_var.get()
    if move_grid:
        pan_zoom1.disconnect()
        pan_zoom2.disconnect()
        draggable_grid.connect()
    else:
        pan_zoom1.connect()
        pan_zoom2.connect()
        draggable_grid.disconnect()

def toggle_contour_lines():
    if hex_grid1 and hex_grid2:
        is_visible = show_contour_lines.get()
        for item in pan_zoom1.fitted_points:
            item["contour"].set_visible(is_visible)
        pan_zoom1.fig.canvas.draw_idle()
    return

def update_correction(dummy = None):
    if pan_zoom1 is None or pan_zoom2 is None: return
    # update the corrected image
    cur_xlim = pan_zoom2.ax.get_xlim()
    cur_ylim = pan_zoom2.ax.get_ylim()
    pan_zoom2.ax.clear()
    pan_zoom2.ax.add_patch(pan_zoom2.circ_indicator)
    pan_zoom2.ax.add_collection(hex_grid2)
    pan_zoom2.ax.add_collection(pathCollection2)
    pan_zoom2.image = imageMap(
            pan_zoom1.image,
            xc_val.get(),
            yc_val.get(),
            np.radians(beta_val.get()),
            KAPPA_val.get(),
            np.radians(k_val.get()),
            xscale_val.get(),
            rotation_val.get()
        )
    pan_zoom2.ax.imshow(
        pan_zoom2.image,
        )
    pan_zoom2.ax.set_xlim(cur_xlim)
    pan_zoom2.ax.set_ylim(cur_ylim)
    pan_zoom2.fig.canvas.draw_idle()
    return

def update_grid_raius(radius):
    radius = float(radius)
    image_size = original_image.size
    hex_grid1.remove()
    hex_grid2.remove()
    pathCollection1.remove()
    pathCollection2.remove()

    create_hex_grid_in_hexagon(image_size, ax1, ax2, grid_radius=3, hex_radius=radius)
    draggable_grid.grid1 = hex_grid1
    draggable_grid.grid2 = hex_grid2
    draggable_grid.centers1 = pathCollection1
    draggable_grid.centers2 = pathCollection2
    pan_zoom2.fig.canvas.draw_idle()


def twoD_Gaussian(xy, amplitude, xo, yo, sigma_x, sigma_y, theta, offset):
    x, y = xy
    xo = float(xo)
    yo = float(yo)    
    a = (np.cos(theta)**2)/(2*sigma_x**2) + (np.sin(theta)**2)/(2*sigma_y**2)
    b = -(np.sin(2*theta))/(4*sigma_x**2) + (np.sin(2*theta))/(4*sigma_y**2)
    c = (np.sin(theta)**2)/(2*sigma_x**2) + (np.cos(theta)**2)/(2*sigma_y**2)
    g = offset + amplitude*np.exp( - (a*((x-xo)**2) + 2*b*(x-xo)*(y-yo) 
                            + c*((y-yo)**2)))
    return g.ravel()

def save_points():
    # Save correction settings
    settings = {
        'filename' : filename,
        'xscale_val' : xscale_val.get(),
        'rotation_val' : rotation_val.get(),
        'KAPPA_val' : KAPPA_val.get(),
        'xc_val' : xc_val.get(),
        'yc_val' : yc_val.get(),
        'k_val' : k_val.get(),
        'beta_val' : beta_val.get(),
        'grid_radius' : grid_radius.get()
    }

    # Save diffraction spots
    keys = ['id', 'name', 'center', 'popt']
    select_keys = lambda x : { key : x[key] for key in keys}
    points_arr_original =[ select_keys(i) for i in pan_zoom1.fitted_points]
    points_arr_corrected =[ select_keys(i) for i in pan_zoom2.fitted_points]

    # Dump them to binary
    with open(filename + '.pkl', 'wb') as f:
        pickle.dump((settings, points_arr_original, points_arr_corrected), f)
    
    print("---------------")
    print("Saved Settings")
    print("Settings :\n", settings)
    print("Original Image Fits :\n", points_arr_original)
    print("Corrected Image Fits :\n", points_arr_corrected)

def update_pointname(event=None):
    pan_zoom1.basename = point_name.get("1.0", tk.END).strip()
    pan_zoom2.basename = point_name.get("1.0", tk.END).strip()

def load_settings(event=None):
    pickle_f = filedialog.askopenfilename()
    if not pickle_f: return

    with open(pickle_f, 'r+b') as fhand:
        settings, points_arr_original, points_arr_corrected = pickle.load(fhand)

    print("---------------")
    print("Loaded settings")
    print("Settings :\n", settings)
    print("Original Image Fits :\n", points_arr_original)
    print("Corrected Image Fits :\n", points_arr_corrected)

    # Load the settings in the sliders
    for key, value in settings.items():
        # DO NOT SAVE FILENAME
        if key == 'filename':
           continue
        else:
            # tk variables
            globals()[key].set(value)

    # Update and redraw
    update_correction()
    update_grid_raius(grid_radius.get())
    
    # Add points to the graphs
    for fit_res in points_arr_original:
        x, y = fit_res["center"]
        new_marker = pan_zoom1.ax.scatter(x, y, c=OVERLAY_COLOR, marker='x')

    for fit_res in points_arr_corrected:
        x, y = fit_res["center"]
        new_marker = pan_zoom2.ax.scatter(x, y, c=OVERLAY_COLOR, marker='x')
        
    pan_zoom2.fig.canvas.draw_idle()



# --- UI Setup ---
root = tk.Tk()
root.title("Advanced Image Viewer")
root.geometry("1000x1000")
root.configure(bg=DARK_GREY)

# Main frame
plot_frame = tk.Frame(root, bg=DARK_GREY)
plot_frame.pack(side=tk.TOP, expand=True, fill= tk.BOTH)

# Controls frame
controls_frame = tk.Frame(root, bg=DARK_GREY)
controls_frame.pack(side=tk.BOTTOM, pady = 10, fill = tk.X)

# Tools frame
tools_frame = tk.Frame(controls_frame, bg=DARK_GREY)
tools_frame.pack(side=tk.RIGHT, pady = 10, fill = tk.X)

# Control buttons frame
controls_buttons_frame = tk.Frame(controls_frame, bg=DARK_GREY)
controls_buttons_frame.pack(padx = 10, side = tk.RIGHT, fill = tk.BOTH)

# Button
load_button = tk.Button(
    tools_frame, text="Load Image", 
    command=load_image, bg=LIGHT_GREY, fg=DARK_GREY,
    font=("Helvetica", 12, "bold"), relief=tk.FLAT
)
save_button = tk.Button(
    tools_frame, text="Save Points", 
    command=save_points, bg=LIGHT_GREY, fg=DARK_GREY,
    font=("Helvetica", 12, "bold"), relief=tk.FLAT
)
load_settings_button = tk.Button(
    tools_frame, text="Load Settings", 
    command=load_settings, bg=LIGHT_GREY, fg=DARK_GREY,
    font=("Helvetica", 12, "bold"), relief=tk.FLAT
)


# === TOOLS ===
# Checkbox
show_grid_var = tk.BooleanVar(value=True)
move_grid_var =  tk.BooleanVar(value=False)
show_hex_lines = tk.BooleanVar(value=True)
show_contour_lines = tk.BooleanVar(value=True)

point_name = tk.Text( tools_frame, heigh = 1, width=40)
point_name.bind("<KeyRelease>", update_pointname)
point_name.pack()

grid_checkbox = tk.Checkbutton(
    tools_frame, text="Show Hexagon Grid", variable=show_grid_var,
    command=toggle_grid, bg=DARK_GREY, fg=WHITE, selectcolor=DARK_GREY,
    activebackground=DARK_GREY, activeforeground=WHITE, font=("Helvetica", 11)
)

move_grid_checkbox = tk.Checkbutton(
    tools_frame, text="Move Hexagon Grid", variable=move_grid_var,
    command=toggle_move_grid, bg=DARK_GREY, fg=WHITE, selectcolor=DARK_GREY,
    activebackground=DARK_GREY, activeforeground=WHITE, font=("Helvetica", 11)
)

contour_lines_checkbox =  tk.Checkbutton(
    tools_frame, text="Show Contour Lines", variable=show_contour_lines,
    command=toggle_contour_lines, bg=DARK_GREY, fg=WHITE, selectcolor=DARK_GREY,
    activebackground=DARK_GREY, activeforeground=WHITE, font=("Helvetica", 11)
)

# Scales 
xscale_val = tk.DoubleVar(value = 1.1)
rotation_val = tk.DoubleVar()
KAPPA_val = tk.DoubleVar(value = 220)
xc_val = tk.DoubleVar(value = 367)
yc_val = tk.DoubleVar(value = 276)
k_val = tk.DoubleVar()
beta_val = tk.DoubleVar()
grid_radius = tk.DoubleVar(value = 20)

common_scales_style = {
    "length" : 200,
    "orient" : tk.HORIZONTAL,
    **def_style
}
grid_radius_scale = tk.Scale(
    controls_buttons_frame,
    from_= 5,
    to = 200,
    resolution = 0.01,
    variable = grid_radius,
    label = 'Grid Radius [px]',
    command = update_grid_raius,
    **common_scales_style
    )
k_scale = tk.Scale(
    controls_buttons_frame,
    from_= -90,
    to = 90,
    resolution = 0.01,
    variable = k_val,
    label = 'k value [deg]',
    command = update_correction,
    **common_scales_style
    )
KAPPA_scale = tk.Scale(
    controls_buttons_frame,
    from_= 5,
    to = 800,
    resolution = 0.25,
    variable = KAPPA_val,
    label = 'KAPPA value [px]',
    command = update_correction,
    **common_scales_style
    )
xc_scale = tk.Scale(
    controls_buttons_frame,
    from_= 0,
    to = 800,
    resolution = 0.25,
    variable = xc_val,
    label = 'xc value [px]',
    command = update_correction,
    **common_scales_style
    )
yc_scale = tk.Scale(
    controls_buttons_frame,
    from_= 0,
    to = 800,
    resolution = 0.25,
    variable = yc_val,
    label = 'yc value [px]',
    command = update_correction,
    **common_scales_style
    )
beta_scale = tk.Scale(
    controls_buttons_frame,
    from_= -90,
    to = 90,
    resolution = 0.01,
    variable = beta_val,
    label = 'beta value [deg]',
    command = update_correction,
    **common_scales_style
    )

xscale_scale = tk.Scale(
    controls_buttons_frame,
    from_= 0.5,
    to = 2,
    resolution = 0.01,
    variable = xscale_val,
    label = 'xscale [times]',
    command = update_correction,
    **common_scales_style
    )

rotation_scale = tk.Scale(
    controls_buttons_frame,
    from_= -30,
    to = 30,
    resolution = 0.01,
    variable = rotation_val,
    label = 'rotation value [deg]',
    command = update_correction,
    **common_scales_style
    )


# Output
console_text = Console(
    controls_frame, bg=LIGHT_GREY, fg=DARK_GREY,
    font=("Helvetica", 12, "bold")
     )
print("=== LEED IMAGING CORRECTION SCRIPT ===")
print("Load an image to start editing")
print("Proceed to tinker with the parameters from top to bottom")

# Tools
grid_checkbox.pack(padx=10)
move_grid_checkbox.pack(padx=10)
contour_lines_checkbox.pack(padx=10)
save_button.pack(padx = 10)
load_settings_button.pack(padx = 10)
load_button.pack(padx = 10)
# Scales
grid_radius_scale.pack()
xscale_scale.pack()
rotation_scale.pack()
KAPPA_scale.pack()
xc_scale.pack()
yc_scale.pack()
k_scale.pack()
beta_scale.pack()
console_text.pack(side = tk.LEFT)

# Start the application
root.mainloop()