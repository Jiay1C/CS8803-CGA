# Implementation

## Neural Network

- **Custom Model:** [Utah Teapot](https://sketchfab.com/3d-models/utah-teapot-92f31e2028244c4b8ef6cbc07738aee5)
- **Dataset Conversion:** Converts the sampled numpy arrays of points and SDF values into torch tensors and transfers them to the specified device.
- **SineLayer Initialization:** Instantiates a fully connected (linear) layer with the provided input/output dimensions and bias setting.
- **SineLayer Forward Pass:** Applies the linear layer to the input, then:
    - Uses a sine activation scaled by w₀ if it is the first layer.
    - Returns the linear output directly if it is the last layer.
    - For intermediate layers, applies the sine activation scaled by w₀, divides by the skip weight, and adds the original input (skip connection).
- **NeuralSDF Network Construction:** Builds the network sequentially by:
    - Adding a first sine-activated layer,
    - Appending the specified number of hidden sine layers with skip connections weighted by the square root of the layer index plus one,
    - Finishing with a final output layer without activation.
- **Training Loop:** For each iteration, it resets gradients, computes the model’s output on the training data, calculates the mean squared error loss with respect to the target SDF values, backpropagates the loss, and performs an optimizer step.
- **Training Configuration:**
    `
    hidden_features = 16,
    hidden_layers = 3,
    w0 = 15,
    iterations = 40000,
    lr = 1e-5
    `

## Fragment Shader

- **sdfCow:** Rotates and offsets the input point, then feeds it through a  neural network to output the cow’s SDF value.
- **sdfTeapot:** Similar to sdfCow, but with its own set of rotations and network weights to compute the teapot’s SDF.
- **Scene SDF:**
    - *Custom branch:* Combines the plane with two teapot SDFs (each rotated appropriately).
    - *Default branch:* Combines the plane with the bunny and cow SDFs.
- **Ray Marching:** Iteratively steps along the ray by adding the SDF value until it falls below a minimum threshold or the maximum iteration count is reached.
- **Normal Calculation:** Approximates the surface normal using finite differences of the SDF along each axis, then normalizes the resulting gradient.
- **Color Assignment:** Assigns object colors based on position—using HSV conversion in the custom branch and fixed colors in the default branch—before applying Phong lighting.
