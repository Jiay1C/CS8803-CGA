# Implementation

## Training

- **Gaussian Contribution Computation:**
  - Computes the quadratic form by performing element-wise matrix multiplication of the relative position tensor with the inverse covariance matrix (`sigma_inv`) and summing over the last dimension.
  - Evaluates the Gaussian function using `torch.exp(-0.5 * exponent)` to obtain the contribution `f_i`.
  - Multiplies `f_i` with the Gaussian’s color and accumulates it into the overall image field.

- **Optimization Loop for Synthetic Image:**
  - Reconstructs the image from the current Gaussian parameters.
  - Computes the loss between the reconstructed image and the synthetic target.
  - Zeros out gradients, backpropagates the loss, and performs an optimizer step.
  - Records the current loss value for tracking convergence.

## Rendering

- **Gaussian Splitting Implementation:**
  - The Gaussian function is based on the standard form where `μ` and `σ` control the center and spread, respectively.
  - These computed weights are used to partition contributions of different scene elements (like different models) ensuring that each element is highlighted or attenuated based on spatial or temporal parameters.
  - The splitting is designed to produce smooth transitions between scene components by blending their contributions according to the Gaussian profile.

- **Time-based Animation Control:**
  - The animation is driven by the time variable, which is scaled and wrapped using a function such as `fract(iTime * factor)` to create a looping animation.
  - Time-dependent parameters adjust the Gaussian centers (`μ`) and spreads (`σ`) dynamically, effectively animating the splitting effect over time.
  - The smoothstep functions are also used alongside the Gaussian weights to ensure that transitions between different states (or models) occur gradually.
