import numpy as np

# Paper with the correction map
# https://doi.org/10.1016/j.ultramic.2013.04.005
# coordinates in pixels of 00 spot

def transform_coordinates(x_id: float, y_id: float, x_c: float, y_c: float, beta: float, k: float, kappa: float) -> tuple[float, float]:
    """
    Implements the forward coordinate transformation protocol.

    This function follows a five-step mathematical protocol to transform an initial
    set of coordinates (x_id, y_id) into a final set (x_or, y_or) using various
    geometric and trigonometric operations.

    Args:
        x_id: The initial x-coordinate from the 'id' system.
        y_id: The initial y-coordinate from the 'id' system.
        x_c: The x-coordinate of the center point 'C'.
        y_c: The y-coordinate of the center point 'C'.
        beta: The rotation angle beta in radians.
        k: The constant 'K'.
        kappa: The rotation angle kappa in radians.

    Returns:
        A tuple containing the final transformed coordinates (x_or, y_or).
    """
    # Pre-calculate sin and cos for efficiency
    sin_beta = np.sin(beta)
    cos_beta = np.cos(beta)
    sin_kappa = np.sin(kappa)
    cos_kappa = np.cos(kappa)

    # --- Equation (1) ---
    # Calculate the intermediate coordinates (x_I, y_I).
    x_i = x_id + (-x_c + sin_beta * k * sin_kappa)
    y_i = -y_id + (y_c + cos_beta * k * sin_kappa)
    
    # --- Equation (2) ---
    # Rotate the intermediate coordinates (x_I, y_I) by the angle beta.
    x_ii = cos_beta * x_i - sin_beta * y_i
    y_ii = sin_beta * x_i + cos_beta * y_i
    
    # --- Equation (3) ---
    # Calculate the z_II component.
    z_ii_squared_arg = k**2 - x_ii**2 - y_ii**2
    z_ii_squared_arg = np.abs(z_ii_squared_arg)
        
    z_ii = np.sqrt(z_ii_squared_arg)
    
    # --- Equation (4) ---
    # Calculate the next set of intermediate coordinates (x_III, y_III).
    x_iii = x_ii
    y_iii = y_ii * cos_kappa - z_ii * sin_kappa
    
    # --- Equation (5) ---
    # Calculate the final output coordinates (x_or, y_or).
    x_or = cos_beta * x_iii + sin_beta * y_iii + x_c
    y_or = sin_beta * x_iii - cos_beta * y_iii + y_c
    
    return (x_or, y_or)

def inverse_transform_coordinates(x_or: float, y_or: float, x_c: float, y_c: float, beta: float, k: float, kappa: float) -> tuple[float, float] | None:
    """
    Implements the inverse of the coordinate transformation protocol.

    This function reverses the five-step protocol to transform (x_or, y_or) 
    back into the original coordinates (x_id, y_id).

    Args:
        x_or: The "output" x-coordinate from the 'or' system.
        y_or: The "output" y-coordinate from the 'or' system.
        x_c: The x-coordinate of the center point 'C'.
        y_c: The y-coordinate of the center point 'C'.
        beta: The rotation angle beta in radians.
        k: The constant 'K'.
        kappa: The rotation angle kappa in radians.

    Returns:
        A tuple containing the original coordinates (x_id, y_id), or None if
        the input coordinates are outside the valid domain of the transformation.
    """
    # Pre-calculate sin and cos for efficiency
    sin_beta = np.sin(beta)
    cos_beta = np.cos(beta)
    sin_kappa = np.sin(kappa)
    cos_kappa = np.cos(kappa)

    # --- Inverse of Equation (5) ---
    # Solve for (x_III, y_III) from (x_or, y_or).
    # This involves a translation and an inverse rotation/reflection.
    x_or_trans = x_or - x_c
    y_or_trans = y_or - y_c
    
    # The matrix in step 5 is its own inverse.
    x_iii = cos_beta * x_or_trans + sin_beta * y_or_trans
    y_iii = sin_beta * x_or_trans - cos_beta * y_or_trans

    # --- Inverse of Equations (4) and (3) ---
    # Solve for (x_II, y_II) from (x_III, y_III).
    x_ii = x_iii
    
    # We need to find z_III. From the forward transform, we know x_II^2 + y_II^2 + z_II^2 = K^2
    # and rotations preserve length, so x_III^2 + y_III^2 + z_III^2 = K^2.
    z_iii_squared_arg = k**2 - x_iii**2 - y_iii**2
    # if np.any(z_iii_squared_arg < 0):
    #     # The input (x_or, y_or) is not a valid output of the forward function.
    #     return None
        
    z_iii = np.sqrt(z_iii_squared_arg) # Take the positive root.

    # The forward transform was a rotation of the coordinate system by kappa.
    # The inverse is a rotation by -kappa.
    # y_ii = y_iii * cos_kappa + z_iii * sin_kappa
    y_ii =( y_iii  + z_iii * sin_kappa) / cos_kappa
    
    # --- Inverse of Equation (2) ---
    # Solve for (x_I, y_I) from (x_II, y_II).
    # This is an inverse 2D rotation (i.e., rotation by -beta).
    x_i = cos_beta * x_ii + sin_beta * y_ii
    y_i = -sin_beta * x_ii + cos_beta * y_ii
    
    # --- Inverse of Equation (1) ---
    # Solve for (x_id, y_id) from (x_I, y_I).
    x_id = x_i + x_c - sin_beta * k * sin_kappa
    y_id = -(y_i - y_c - cos_beta * k * sin_kappa)

    return (x_id, y_id)