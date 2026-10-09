#version 120
//Vignetting, applies bloom, applies exposure and tonemaps the final image
#extension GL_EXT_gpu_shader4 : enable
//#define BICUBIC_UPSCALING //Provides a better interpolation when using a render quality different of 1.0, slower
#define CONTRAST_ADAPTATIVE_SHARPENING
#define SHARPENING 0.5
#define LVS_COLOR_GRADE 0.35 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.5 0.6 0.75 1.0]
#define LVS_WARM_HIGHLIGHTS 0.18 //[0.0 0.05 0.1 0.15 0.18 0.2 0.25 0.3 0.4 0.5]
#define LVS_COOL_SHADOWS 0.12 //[0.0 0.05 0.1 0.12 0.15 0.2 0.25 0.3 0.4]
// Optional lightweight spatial anti-aliasing. Use instead of TAA for a sharper, lower-latency image.
//#define LVS_FXAA // Lightweight FXAA post-process

float lvsFxaaLuma(vec3 c){
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 lvsFXAA(sampler2D tex, vec2 uv, vec2 px, vec3 center){
    float lumaM  = lvsFxaaLuma(center);
    float lumaNW = lvsFxaaLuma(texture2D(tex, uv + px * vec2(-1.0, -1.0)).rgb);
    float lumaNE = lvsFxaaLuma(texture2D(tex, uv + px * vec2( 1.0, -1.0)).rgb);
    float lumaSW = lvsFxaaLuma(texture2D(tex, uv + px * vec2(-1.0,  1.0)).rgb);
    float lumaSE = lvsFxaaLuma(texture2D(tex, uv + px * vec2( 1.0,  1.0)).rgb);
    float lumaMin = min(lumaM, min(min(lumaNW,lumaNE), min(lumaSW,lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW,lumaNE), max(lumaSW,lumaSE)));
    float range = lumaMax - lumaMin;
    if (range < max(0.0312, lumaMax * 0.125)) return center;

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
    float reduce = max((lumaNW+lumaNE+lumaSW+lumaSE) * (0.25 * 0.125), 0.0078125);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + reduce);
    dir = clamp(dir * rcpDirMin, vec2(-8.0), vec2(8.0)) * px;

    vec3 rgbA = 0.5 * (
        texture2D(tex, uv + dir * (1.0/3.0 - 0.5)).rgb +
        texture2D(tex, uv + dir * (2.0/3.0 - 0.5)).rgb);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture2D(tex, uv + dir * -0.5).rgb +
        texture2D(tex, uv + dir * 0.5).rgb);
    float lumaB = lvsFxaaLuma(rgbB);
    return (lumaB < lumaMin || lumaB > lumaMax) ? rgbA : rgbB;
}

 //[0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.3 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.4 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.5 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.6 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.7 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.8 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.9 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.0 ]
#define SATURATION 0.00 // Negative values desaturates colors, Positive values saturates color, 0 is no change [-1.0 -0.98 -0.96 -0.94 -0.92 -0.9 -0.88 -0.86 -0.84 -0.82 -0.8 -0.78 -0.76 -0.74 -0.72 -0.7 -0.68 -0.66 -0.64 -0.62 -0.6 -0.58 -0.56 -0.54 -0.52 -0.5 -0.48 -0.46 -0.44 -0.42 -0.4 -0.38 -0.36 -0.34 -0.32 -0.3 -0.28 -0.26 -0.24 -0.22 -0.2 -0.18 -0.16 -0.14 -0.12 -0.1 -0.08 -0.06 -0.04 -0.02 0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0 ]
#define CROSSTALK 0.0 // Desaturates bright colors and preserves saturation in darker areas (inverted if negative). Helps avoiding almsost fluorescent colors [-1.0 -0.98 -0.96 -0.94 -0.92 -0.9 -0.88 -0.86 -0.84 -0.82 -0.8 -0.78 -0.76 -0.74 -0.72 -0.7 -0.68 -0.66 -0.64 -0.62 -0.6 -0.58 -0.56 -0.54 -0.52 -0.5 -0.48 -0.46 -0.44 -0.42 -0.4 -0.38 -0.36 -0.34 -0.32 -0.3 -0.28 -0.26 -0.24 -0.22 -0.2 -0.18 -0.16 -0.14 -0.12 -0.1 -0.08 -0.06 -0.04 -0.02 0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6 0.62 0.64 0.66 0.68 0.7 0.72 0.74 0.76 0.78 0.8 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98 1.0 ]
varying vec2 texcoord;

uniform sampler2D colortex7;
uniform vec2 texelSize;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int isEyeInWater;
#include "lib/color_transforms.glsl"
#include "lib/color_dither.glsl"
#include "/lib/res_params.glsl"
vec4 SampleTextureCatmullRom(sampler2D tex, vec2 uv, vec2 texSize )
{
    // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
    // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
    // location [1, 1] in the grid, where [0, 0] is the top left corner.
    vec2 samplePos = uv * texSize;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;

    // Compute the fractional offset from our starting texel to our original sample location, which we'll
    // feed into the Catmull-Rom spline function to get our filter weights.
    vec2 f = samplePos - texPos1;

    // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
    // These equations are pre-expanded based on our knowledge of where the texels will be located,
    // which lets us avoid having to evaluate a piece-wise function.
    vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
    vec2 w3 = f * f * (-0.5 + 0.5 * f);

    // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
    // simultaneously evaluate the middle 2 samples from the 4x4 grid.
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / (w1 + w2);

    // Compute the final UV coordinates we'll use for sampling the texture
    vec2 texPos0 = texPos1 - vec2(1.0);
    vec2 texPos3 = texPos1 + vec2(2.0);
    vec2 texPos12 = texPos1 + offset12;

    texPos0 *= texelSize;
    texPos3 *= texelSize;
    texPos12 *= texelSize;

    vec4 result = vec4(0.0);
    result += texture2D(tex, vec2(texPos0.x,  texPos0.y)) * w0.x * w0.y;
    result += texture2D(tex, vec2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += texture2D(tex, vec2(texPos3.x,  texPos0.y)) * w3.x * w0.y;

    result += texture2D(tex, vec2(texPos0.x,  texPos12.y)) * w0.x * w12.y;
    result += texture2D(tex, vec2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += texture2D(tex, vec2(texPos3.x,  texPos12.y)) * w3.x * w12.y;

    result += texture2D(tex, vec2(texPos0.x,  texPos3.y)) * w0.x * w3.y;
    result += texture2D(tex, vec2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += texture2D(tex, vec2(texPos3.x,  texPos3.y)) * w3.x * w3.y;

    return result;
}

void main() {
  #ifdef BICUBIC_UPSCALING
    vec3 col = SampleTextureCatmullRom(colortex7,texcoord,1.0/texelSize).rgb;
  #else
    vec3 col = texture2D(colortex7,texcoord).rgb;
  #endif

  #ifdef LVS_FXAA
    col = lvsFXAA(colortex7, texcoord, texelSize, col);
  #endif

  #ifdef CONTRAST_ADAPTATIVE_SHARPENING
    //Weights : 1 in the center, 0.5 middle, 0.25 corners
    vec3 albedoCurrent1 = texture2D(colortex7, texcoord + vec2(texelSize.x,texelSize.y)/MC_RENDER_QUALITY*0.5).rgb;
    vec3 albedoCurrent2 = texture2D(colortex7, texcoord + vec2(texelSize.x,-texelSize.y)/MC_RENDER_QUALITY*0.5).rgb;
    vec3 albedoCurrent3 = texture2D(colortex7, texcoord + vec2(-texelSize.x,-texelSize.y)/MC_RENDER_QUALITY*0.5).rgb;
    vec3 albedoCurrent4 = texture2D(colortex7, texcoord + vec2(-texelSize.x,texelSize.y)/MC_RENDER_QUALITY*0.5).rgb;


    vec3 m1 = -0.5/3.5*col + albedoCurrent1/3.5 + albedoCurrent2/3.5 + albedoCurrent3/3.5 + albedoCurrent4/3.5;
    vec3 std = abs(col - m1) + abs(albedoCurrent1 - m1) + abs(albedoCurrent2 - m1) +
     abs(albedoCurrent3 - m1) + abs(albedoCurrent3 - m1) + abs(albedoCurrent4 - m1);
    float contrast = 1.0 - luma(std)/5.0;
    col = col*(1.0+(SHARPENING+UPSCALING_SHARPNENING)*contrast)
          - (SHARPENING+UPSCALING_SHARPNENING)/(1.0-0.5/3.5)*contrast*(m1 - 0.5/3.5*col);
  #endif

  // LVS cinematic-but-vanilla color grade: warm highlights, cool shadows, restrained saturation.
  float lum = luma(col);
  float shadowMask = 1.0 - smoothstep(0.12, 0.58, lum);
  float highlightMask = smoothstep(0.42, 0.92, lum);
  vec3 warmGrade = vec3(1.0, 0.965, 0.90);
  vec3 coolGrade = vec3(0.92, 0.965, 1.0);
  col *= mix(vec3(1.0), mix(coolGrade, warmGrade, highlightMask), LVS_COLOR_GRADE * max(shadowMask, highlightMask));
  col = mix(col, col * vec3(1.0, 0.98, 0.94), LVS_WARM_HIGHLIGHTS * highlightMask);
  col = mix(col, col * vec3(0.94, 0.98, 1.0), LVS_COOL_SHADOWS * shadowMask);
  vec3 diff = col-lum;
  col = col + diff*(-lum*CROSSTALK + SATURATION);
  //col = -vec3(-lum*CROSSFADING + SATURATION);
	gl_FragColor.rgb = clamp(int8Dither(col,texcoord),0.0,1.0);
  //gl_FragColor.rgb = vec3(contrast);
}
