# Implementation

### 1: SDF Volume Reading (`readSDFVolume`)
- **Purpose**: Convert an SDF sample into a color–density representation.
- **Logic**:
    - **Outside Object**: If the SDF value (`distance`) is ≥ 0, return a zero vector (no color or density).
    - **Inside Object**: For negative SDF values, use the absolute distance to generate an RGB color via the `palette` function and set density (alpha) to 1.0.

---

### 2: CT Volume Reading (`readCTVolume`)
- **Purpose**: Visualize CT scan data from a 3D texture.
- **Logic**:
    - **Normalization & Bounds Check**: Convert the sample position to [0,1] texture coordinates and return zero if outside.
    - **Sampling & Mapping**: Sample the texture (`iVolume`) to obtain a density value. Map this density to an RGB color using the `palette` function.
    - **Enhancement**: Multiply the result by a constant (2.0) to boost the visualization.

---

### 3: Custom Volume Reading (`myReadVolume`)
- **Purpose**: Read volumetric data with adjustable density filtering and color scaling.
- **Logic**:
    - **Normalization & Bounds Check**: Convert the sample position to texture coordinates; discard if out-of-bounds.
    - **Density Adjustment**: Sample the texture, subtract an `offset` from the density value.
    - **Conditional Mapping**: If the adjusted density lies within specified thresholds (`min_density` and `max_density`), map it to a color using `myPalette` (normalized over the density range) and apply a color coefficient.
    - **Fallback**: Return zero if the density is outside the desired range.

---

### 4: Volumetric Ray Marching (Custom Scene in `volumeRendering`)
- **Purpose**: Accumulate color along a ray through a volumetric dataset using an absorption–emission model.
- **Logic**:
    - **Sample Culling**: Skip samples with a y-coordinate below a threshold to avoid processing irrelevant data.
    - **Time-Based Variation**: Compute a time factor using the current time (`iTime`) with an easing function (`easeOutCubic`) to modulate the effect dynamically.
    - **Offset Computation**: Interpolate an offset value between predefined start and end values based on the time factor.
    - **Sample Transformation & Volume Reading**: Transform the sample position with scaling and translation, then obtain volumetric data via `myReadVolume`.
    - **Color Accumulation**: Use an exponential decay (based on step size and density) to update both the accumulated color and the transmittance, mimicking front-to-back compositing.