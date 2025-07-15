import tkinter as tk
from tkinter import filedialog
import numpy as np
import scipy.ndimage
import scipy.optimize as opt
import sys
from PIL import Image
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import RegularPolygon
from matplotlib.collections import PatchCollection
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from tabulate import tabulate

OVERLAY_COLOR = "#ff00ff"

def translate_collection(collection, dx, dy):
    """
    Translates a Matplotlib collection by a given delta_x and delta_y.
    This works by updating the offset coordinates of each element.

    Args:
        collection (matplotlib.collections.Collection): The collection to move.
        dx (float): The distance to move along the x-axis.
        dy (float): The distance to move along the y-axis.
    """
    current_offsets = collection.get_offsets()
    new_offsets = current_offsets + np.array([dx, dy])
    collection.set_offsets(new_offsets)

def scale_collection(collection, scale_factor, ax, center = None):
    """
    Scales a Matplotlib collection by a given factor around its center.
    This method applies a transformation matrix to the collection. This scales
    both the size of the individual patches and their spacing.

    Args:
        collection (matplotlib.collections.Collection): The collection to scale.
        scale_factor (float): The factor to scale by (e.g., 1.5 for 150%).
        ax (matplotlib.axes.Axes): The axes the collection belongs to.
    """
    # Calculate the geometric center of the collection's elements.
    #center = np.mean(collection.get_offsets())
    if center is None:
        center = np.mean(collection.get_offsets(), axis = 0)
    print(center)
    # Create an affine transformation that scales around the center point.
    # It's a combination of three steps:
    # 1. Translate the collection to the origin.
    # 2. Scale the collection.
    # 3. Translate the collection back to its original center.
    transform = (
        mpl.transforms.Affine2D().translate(-center[0], -center[1])
        + mpl.transforms.Affine2D().scale(scale_factor)
        + mpl.transforms.Affine2D().translate(center[0], center[1])
    )

    
    # Combine the new scaling transform with the existing axes data transform.
    collection.set_transform(mpl.transforms.Affine2D().translate(-center[0], -center[1]))

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

# --- Draggable Hexagon Grid Class ---
class DraggableHexGrid:
    def __init__(self, grid1, grid2, centers1, centers2, canvas):
        self.grid1 = grid1
        self.grid2 = grid2
        self.centers1 = centers1
        self.centers2 = centers2
        self.canvas = canvas
        self.scale = 1
        self.position = [0,0]
        self.is_dragging = False
        self.press_pos = None
        self.original_offsets = None
        self.conncted = False
       
        # this controller should be 
        # activated manually

    def connect(self):
        self.cid_press = self.canvas.mpl_connect('button_press_event', self.on_press)
        self.cid_release = self.canvas.mpl_connect('button_release_event', self.on_release)
        self.cid_motion = self.canvas.mpl_connect('motion_notify_event', self.on_motion)
        self.cid_scroll = self.canvas.mpl_connect('scroll_event', self.on_scroll)
        self.connected = True

    def disconnect(self):
        if not self.connect:
            return
        self.canvas.mpl_disconnect(self.cid_press)
        self.canvas.mpl_disconnect(self.cid_release)
        self.canvas.mpl_disconnect(self.cid_motion)
        self.canvas.mpl_disconnect(self.cid_scroll)

    def on_press(self, event):
        if event.inaxes is None: return
        contains, _ = self.grid1.contains(event)
        contains = contains or self.grid2.contains(event)
        if not contains: return
        self.is_dragging = True
        self.press_pos = np.array([event.xdata, event.ydata])

        if self.grid1.contains(event):
            self.original_offsets = self.centers1.get_offsets()
        else:
            self.original_offsets = self.centers2.get_offsets()

    def on_motion(self, event):
        if not self.is_dragging or event.inaxes is None: return
        current_pos = np.array([event.xdata, event.ydata])
        delta = current_pos - self.press_pos
        translate = mpl.transforms.Affine2D().translate(*delta)
        tdata = event.inaxes.transData

        if self.grid1.contains(event)[0]:
            self.grid1.set_transform(translate + tdata)
            self.centers1.set_offsets(self.original_offsets + delta)

        if self.grid2.contains(event)[0]:
            self.grid2.set_transform(translate + tdata)
            self.centers2.set_offsets(self.original_offsets + delta)

        self.canvas.draw_idle()

    def on_scroll(self, event):
        return

    def on_release(self, event):
        self.is_dragging = False
        self.press_pos = None
        self.original_offsets = None

# --- Pan and Zoom Class (unchanged) ---
class PanAndZoom:
    def __init__(self, ax, image):
        self.ax = ax
        self.fig = ax.get_figure()
        self.press = None
        self.fitted_points = []
        self.xlim_original = ax.get_xlim()
        self.ylim_original = ax.get_ylim()
        self.circ_indicator = mpl.patches.Circle((0,0),
            facecolor='none', edgecolor=OVERLAY_COLOR,
            linewidth=1, alpha=0.7, zorder = 2)
        self.ax.add_patch(self.circ_indicator)
        self.image = np.array(image)
        self.basename = None

        self.connected = True
        self.is_panning = False
        self.is_fitting = True
        self.connect()


    def connect(self):
        self.cid_press = self.fig.canvas.mpl_connect('button_press_event', self.on_press)
        self.cid_release = self.fig.canvas.mpl_connect('button_release_event', self.on_release)
        self.cid_motion = self.fig.canvas.mpl_connect('motion_notify_event', self.on_motion)
        self.cid_scroll = self.fig.canvas.mpl_connect('scroll_event', self.on_scroll)
        self.cid_dblclick = self.fig.canvas.mpl_connect('button_press_event', self.on_double_click)
        self.cid_keypress = self.fig.canvas.mpl_connect('key_press_event', self.on_keypress)
        self.connected = True

    def disconnect(self):
        if not self.connected:
            return
        self.fig.canvas.mpl_disconnect(self.cid_press)
        self.fig.canvas.mpl_disconnect(self.cid_release)
        self.fig.canvas.mpl_disconnect(self.cid_motion)
        self.fig.canvas.mpl_disconnect(self.cid_scroll)
        self.fig.canvas.mpl_disconnect(self.cid_dblclick)
        self.fig.canvas.mpl_disconnect(self.cid_keypress)

    def on_double_click(self, event):
        if event.inaxes is self.ax and event.dblclick:
            self.ax.set_xlim(self.xlim_original)
            self.ax.set_ylim(self.ylim_original)
            self.fig.canvas.draw_idle()

    def on_keypress(self, event):
        if self.is_fitting and event.key == "ctrl+z":
            if len(self.fitted_points) > 0:
                last = self.fitted_points.pop()
                last["contour"].remove()
                last["marker"].remove()

            self.fig.canvas.draw_idle()
            print("Removed {}".format(last["name"]))
            return

            print("Can't remove last fitted point: no points available")


           

    def on_press(self, event):
        # Ignore clicks on the grid
        if hasattr(event, 'artist') and isinstance(event.artist, PatchCollection): return
        if event.inaxes != self.ax: return
        if self.is_fitting and event.key == "shift":
            print("-------------")
            print("Fitting {} at mouse location".format(self.basename))
            shape = np.array(self.image).shape
            h, w  = shape[0], shape[1]
            Y, X = np.indices((h, w))
            # we use event data and not
            # the indicator because its more
            # stable, but should be same thing
            r = self.circ_indicator.get_radius()
            
            # generate a square of indices and 
            # translate it to the correct spot
            d = int(2 * r)
            X, Y = np.indices((d, d))
            X = X + int(event.xdata - r) 
            Y = Y + int(event.ydata - r)
            
            # initial guess
            offset = self.image[Y, X].min()
            amplitude = self.image[Y, X].max()
            sigma = r / 2


            initial_guess = (
                amplitude,
                event.xdata,
                event.ydata,
                sigma,
                sigma,
                0,
                offset)

            # bounds = (
            #     [amplitude / 2,
            #     event.xdata - r,
            #     event.ydata - r,
            #     r / 10, r / 10, -1, 0],
            #     [amplitude,
            #     event.xdata + r,
            #     event.ydata + r,
            #     3 * r, 3 * r, 1, amplitude / 10])

            data_noisy = self.image[Y, X].ravel()
            popt, pcov = opt.curve_fit(twoD_Gaussian, (X, Y), data_noisy, p0=initial_guess)
        
            results =[
            ["amplitude", amplitude, popt[0]] ,
            ["center x", event.xdata, popt[1]],
            ["center y", event.ydata, popt[2]],
            ["sigma x", sigma, popt[3]],
            ["sigma y", sigma, popt[4]],
            ["theta", 0, popt[5]],
            ["offset", offset, popt[6]]]
            name = self.basename + '_' + str(len(self.fitted_points))
            print("name : " + name)
            print('parameter, initial, final')
            for a in results:
                print("{}, \t{:.2f}, \t{:.2f}".format(*a))
            print("-------------")

            # expand the print area
            d = int(6 * r)
            X, Y = np.indices((d, d))
            X = X + int(event.xdata - 3 * r) 
            Y = Y + int(event.ydata - 3 * r)
            data_fitted = twoD_Gaussian((X, Y), *popt)
            contour = self.ax.contour(X, Y, data_fitted.reshape(d, d), 1, colors='w')
            # self.ax.annotate("Center", (popt[1], popt[2]), color=OVERLAY_COLOR)
            marker = self.ax.scatter(popt[1], popt[2], c = OVERLAY_COLOR, marker='x')

            fit_res = {
                "id" : len(self.fitted_points),
                "name" : name, 
                "center" : (popt[1], popt[2]),
                "popt" : results,
                "contour" : contour,
                "marker" : marker,
            }

            self.fitted_points.append(fit_res)
            self.fig.canvas.draw_idle()

        self.is_panning = True
        self.press = event.xdata, event.ydata

    def on_motion(self, event):
        if event.inaxes != self.ax: return

        if self.is_fitting:
            self.circ_indicator.set(
                center = (event.xdata, event.ydata)
            )

        if self.is_panning:
            xpress, ypress = self.press
            dx = event.xdata - xpress
            dy = event.ydata - ypress
            cur_xlim = self.ax.get_xlim()
            cur_ylim = self.ax.get_ylim()
            self.ax.set_xlim([x - dx for x in cur_xlim])
            self.ax.set_ylim([y - dy for y in cur_ylim])
        self.fig.canvas.draw_idle()

    def on_release(self, event):
        self.is_panning = False
        self.press = None

    def on_scroll(self, event):
        if event.inaxes != self.ax: return
        
        if self.is_fitting and event.key == 'shift':
            scale_factor = 1 if event.button == 'up' else -1
            r = self.circ_indicator.get_radius()
            self.circ_indicator.set_radius(r + scale_factor)
        else:
            scale_factor = 1.1 if event.button == 'up' else 1 / 1.1
            cur_xlim, cur_ylim = self.ax.get_xlim(), self.ax.get_ylim()
            xdata, ydata = event.xdata, event.ydata
            new_width = (cur_xlim[1] - cur_xlim[0]) * scale_factor
            new_height = (cur_ylim[1] - cur_ylim[0]) * scale_factor
            relx = (cur_xlim[1] - xdata) / (cur_xlim[1] - cur_xlim[0])
            rely = (cur_ylim[1] - ydata) / (cur_ylim[1] - cur_ylim[0])
            self.ax.set_xlim([xdata - new_width * (1 - relx), xdata + new_width * relx])
            self.ax.set_ylim([ydata - new_height * (1 - rely), ydata + new_height * rely])
        self.fig.canvas.draw_idle()

# === Console Widget ===
class Console(tk.Text):
    def __init__(self, *args, **kwargs):
        kwargs.update({"state": "disabled"})
        tk.Text.__init__(self, *args, **kwargs)
        self.bind("<Destroy>", self.reset)
        self.old_stdout = sys.stdout
        sys.stdout = self
    
    def delete(self, *args, **kwargs):
        self.config(state="normal")
        self.delete(*args, **kwargs)
        self.config(state="disabled")
    
    def write(self, content):
        self.config(state="normal")
        self.insert("end", content)
        self.config(state="disabled")
        self.see(tk.END)
    
    def reset(self, event):
        sys.stdout = self.old_stdout