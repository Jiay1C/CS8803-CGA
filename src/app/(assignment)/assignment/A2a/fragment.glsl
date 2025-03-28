
/////////////////////////////////////////////////////
//// CS 8803/4803 CGAI: Computer Graphics in AI Era
//// Assignment 2A: Volumetric Ray Tracing
/////////////////////////////////////////////////////

precision highp float;              //// set default precision of float variables to high precision

varying vec2 vUv;                   //// screen uv coordinates (varying, from vertex shader)
uniform vec2 iResolution;           //// screen resolution (uniform, from CPU)
uniform float iTime;                //// time elapsed (uniform, from CPU)
uniform highp sampler3D iVolume;    //// volume texture

#define USE_CUSTOM_SCENE

#define E 2.7182818284

/////////////////////////////////////////////////////
//// camera initialization
/////////////////////////////////////////////////////

//// set camera: ro - camera position, ta - camera lookat, cr - camera rotation angle
mat3 setCamera(in vec3 ro, in vec3 ta, float cr)
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = cross(cu,cw);
    return mat3(cu, cv, cw);
}

/////////////////////////////////////////////////////
//// density-to-color conversion
/////////////////////////////////////////////////////

//// Inigo Quilez - https://iquilezles.org/articles/palettes/
//// This function converts a scalar value t to a color
vec3 palette(in float t) 
{
  vec3 a = vec3(0.5, 0.5, 0.5);
  vec3 b = vec3(0.5, 0.5, 0.5);
  vec3 c = vec3(1.0, 1.0, 1.0);
  vec3 d = vec3(0.0, 0.10, 0.20);

  return a + b * cos(6.28318 * (c * t + d));
}

vec3 myPaletteBlend( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 myPalette(in float t)
{
    return myPaletteBlend(t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20) );
}

/////////////////////////////////////////////////////
//// sdf definitions
/////////////////////////////////////////////////////

//// sdf sphere
float sdSphere(vec3 p, float s)
{
    return length(p)-s;
}

//// sdf box
float sdBox(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

/////////////////////////////////////////////////////
//// color and density calculation from volume data
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//// Step 1: calculate color and density from sdf
//// You are asked to convert the negative sdf value to a vec4 with the first three components as color rgb values and the last component as density.
//// For color, you may use the provided palette function to convert the sdf value to an rgb color.
//// For density, we assume it is alway 1.0 inside the object (sdf < 0) and 0.0 outside the object (sdf >= 0).
/////////////////////////////////////////////////////

vec4 readSDFVolume(vec3 p)
{
    //// sdf object
    float distance = sdSphere(p, 1.0); 

    //// convert sdf value to a color

    //// your implementation starts

    if (distance >= 0.0f){
        return vec4(0.0f);
    }
    else{
        return vec4(palette(-distance), 1.0f);
    }

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// Step 2: calculate color and density from CT data
//// You are asked to convert the CT data to a vec4 with the first three components as color rgb values and the last component as density.
//// For density, you should read the density value from the first component of the volumetric texture iVolume with tex_coord.
//// For color, you should use the provided palette function to convert the density value to an rgb color.
//// You may want to multiple the returned vec4 with a constant to enhance the visualization color.
/////////////////////////////////////////////////////

vec4 readCTVolume(vec3 p)
{
    //// normalize coordinates to [0, 1] range
    vec3 tex_coord = (p + vec3(1.0)) * 0.5;
    //// check if tex_coord is outside the box
    if (tex_coord.x < 0.0 || tex_coord.x > 1.0 || 
        tex_coord.y < 0.0 || tex_coord.y > 1.0 || 
        tex_coord.z < 0.0 || tex_coord.z > 1.0) {
        return vec4(0.0);
    }

    //// your implementation starts

    vec4 tex = texture(iVolume, tex_coord);
    float density = tex.x;
    vec4 color = vec4(palette(density), density);

    return color * 2.0f;

    //// your implementation ends
}

vec4 myReadVolume(vec3 p, float offset, float min_density, float max_density, float color_coef)
{
    //// normalize coordinates to [0, 1] range
    vec3 tex_coord = (p + vec3(1.0)) * 0.5;
    //// check if tex_coord is outside the box
    if (tex_coord.x < 0.0 || tex_coord.x > 1.0 ||
    tex_coord.y < 0.0 || tex_coord.y > 1.0 ||
    tex_coord.z < 0.0 || tex_coord.z > 1.0) {
        return vec4(0.0);
    }

    //// your implementation starts

    vec4 tex = texture(iVolume, tex_coord);
    float density = tex.x - offset;

    if (density > min_density && density < max_density){
        vec4 color = vec4(myPalette(density / (max_density - min_density)), density);
        return color * color_coef;
    }

    return vec4(0.0f);

    //// your implementation ends
}

/////////////////////////////////////////////////////
//// Step 3: ray tracing with volumetric data
//// You are asked to implement the front-to-back volumetric ray tracing algorithm to accummulate colors along each ray. 
//// Your task is to accumulate color and transmittance along the ray based on the absorption-emission volumetric model.
//// You may want to read the course slides, Equation (3) in the original NeRF paper, and the A2a document for the rendering model.
/////////////////////////////////////////////////////

// From https://easings.net/#easeOutCubic
float easeOutCubic(float x) {
    return 1.0f - pow(1.0f - x, 3.0f);
}

//// ro - ray origin, rd - ray direction, 
//// near - near bound of t, far - far bound of t, 
//// n_samples - number of samples between near and far
vec4 volumeRendering(vec3 ro, vec3 rd, float near, float far, int n_samples) 
{
    float stepSize = (far - near) / float(n_samples);                           //// step size of each sample

    //// color and transmittance
    vec3 color = vec3(0.0);                                                     //// accumulated color
    float transmittance = 1.0;                                                  //// transmittance

    //// ray marching loop
    for (int i = 0; i < n_samples; i++) {
        float t = near + stepSize * float(i);                                   //// t value along the ray
        vec3 p = ro + t * rd;                                                   //// sample position on the ray

        //// your implementation starts
#ifdef USE_CUSTOM_SCENE

        if (p.y < -1.5f) continue;

        float time = fract(iTime * 0.03f) * 2.0f;
        time = 1.0f - abs(1.0f - time);
        time = clamp(time, 0.0f, 1.0f);
        time = easeOutCubic(time);

        vec3 center = vec3(0.0f, -0.2f, 0.0f);

        float start_offset = 0.4f;
        float end_offset = 0.88f;
        float offset = time * (end_offset - start_offset) + start_offset;

        vec4 vol = myReadVolume(p * 0.3f * time - center, 1.0 - offset, 0.05f, 1.0f, 4.0f);

#else

        vec3 sphere_center = vec3(-2.0f, 0.0f, 0.0f);
        vec4 sphere_vol = readSDFVolume(p - sphere_center);

        vec3 ct_center = vec3(2.0f, 0.0f, 0.0f);
        vec4 ct_vol = readCTVolume(p - ct_center);
        vec4 vol = sphere_vol + ct_vol;

#endif

        float coef = pow(E, -stepSize * vol.w);

        color += transmittance * vol.rgb * (1.0f - coef);

        transmittance *= coef;

        //// your implementation ends

        //// early termination if opacity is high
        if (transmittance < 0.01) break;
    }
    
    //// return color and transmittance
    return vec4(color, 1.0 - transmittance);                                   
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //// normalize fragment coordinates to [-0.5, 0.5] range
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    //// camera 
    float angle = 0.5 * iTime;                                                  //// camera angle
#ifdef USE_CUSTOM_SCENE
    vec3 ta = vec3(0.0, 0.5, 0.0);                                              //// object center
    float radius = 3.5;                                                         //// camera rotation
    float height = 0.2;                                                         //// camera height
#else
    vec3 ta = vec3(0.0, 0.0, 0.0);                                              //// object center
    float radius = 5.5;                                                         //// camera rotation
    float height = 2.2;                                                         //// camera height
#endif
    vec3 ro = ta + vec3(radius * cos(angle), height, radius * sin(angle));      //// camera position
    mat3 ca = setCamera(ro, ta, 0.0);                                           //// camera matrix
    
    //// ray
    vec3 rd = ca * normalize(vec3(uv, 1.0));                                    //// ray direction
    float near = 2.0;                                                           //// near bound
    float far = 8.5;                                                            //// far bound    
    int n_samples = 1024;                                                       //// number of samples along each ray
    
    //// final output color
    fragColor = volumeRendering(ro, rd, near, far, n_samples);                  //// volumetric ray marching
}

void main()
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}