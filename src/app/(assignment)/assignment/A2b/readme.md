# Implementation

## NeRF Model Implementation

- **Positional Encoding:**
    - Iterates over the defined frequency range (`n_freqs`) to generate sinusoidal features.
    - For each frequency, computes both sine and cosine of the scaled input tensor.
    - Concatenates the original input with all sinusoidal components to produce a richer, higher-dimensional feature representation.

- **Volume Rendering:**
    - Applies a sigmoid function to the first three outputs to obtain RGB colors and a ReLU to the fourth to ensure non-negative density (`sigma`).
    - Computes the distance between consecutive depth samples and extends the distance array to account for the final sample.
    - Uses the density values to calculate transmittance along the ray via an exponential decay and cumulative product.
    - Integrates the weighted colors along the ray to yield the final rendered pixel color (`rgb_map`).

- **Training Step:**
    - Generates ray origins and directions from the camera pose and intrinsic parameters.
    - Renders the scene by sampling along rays using the volume rendering process.
    - Computes the mean squared error (MSE) loss between the rendered image and the ground truth.
    - Performs backpropagation and updates model weights using the optimizer.

## Rendering with GLSL

- **Time-based Weights Calculation:**
    - The time parameter `t` is derived from `fract(iTime * 0.05)`, creating a repeating cycle between 0 and 1.
    - For each model (lego, hotdog, chair, drum), weights are computed using `smoothstep()` functions. These functions define specific intervals over `t` so that each model is activated smoothly over different time segments.

- **Conditional Network Queries:**
    - A small threshold `ep` (epsilon) ensures that only models with significant weights contribute.
    - Depending on the weight, the code calls functions like `queryLegoNetwork(p)`, `queryHotdogNetwork(p)`, etc.
    - The output from each model is multiplied by its respective weight and accumulated into the final volume `vec4 vol`.

- **Integration with Volumetric Ray Marching:**
    - The blended volume output is then used in a front-to-back ray marching loop.
    - Each sample point along a ray is transformed (e.g., rotated), passed through the blending logic, and then activated with `sigmoid()` for RGB and `relu()` for density (sigma).
    - The final color is accumulated based on the transmittance along the ray, providing smooth visual transitions between different scene models.