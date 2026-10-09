#define TAA
//#define TAA_UPSCALING // Lowers render resolution and uses TAA to combine several lower resolution images (greatly improves performance). USE THIS INSTEAD OF SHADER RENDER QUALITY OPTION IF YOU WANT TO INCREASE FPS (Leave it to 1). IF YOU WANT TO INCREASE QUALITY DISABLE THIS AND INCREASE SHADER RENDER QUALITY
#ifndef TAA
  #undef TAA_UPSCALING
#endif



#ifdef TAA_UPSCALING
  #define RENDER_SCALE_X 0.7  // X axis render resolution multiplier [0.5 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.6 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.7 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.8  0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.9  0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.  ]
  #define RENDER_SCALE_Y 0.7  // Y axis render resolution multiplier  [0.5 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.6 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.7 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.8  0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.9  0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.  ]
  #define RENDER_SCALE vec2(RENDER_SCALE_X, RENDER_SCALE_Y)
  #define UPSCALING_SHARPNENING 2.0 - RENDER_SCALE_X - RENDER_SCALE_Y
#else
  #define RENDER_SCALE vec2(1.0, 1.0)
  #define UPSCALING_SHARPNENING 0.0
#endif


// LVS user controls
#define LVS_SOFT_LIGHTING 0.72 // [0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.72 0.75 0.8 0.85 0.9 0.95 1.0]
#define LVS_SKY_BOUNCE_STRENGTH 0.38 // [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.38 0.4 0.45 0.5 0.6 0.7 0.8]
#define LVS_GROUND_BOUNCE_STRENGTH 0.16 // [0.0 0.04 0.08 0.12 0.16 0.2 0.24 0.3 0.4]
#define LVS_SHADOW_LIFT 0.055 // [0.0 0.01 0.02 0.03 0.04 0.05 0.055 0.06 0.08 0.1 0.12]
#define LVS_SUN_HIGHLIGHT 0.085 // [0.0 0.02 0.04 0.06 0.08 0.085 0.1 0.12 0.16 0.2]
#define LVS_TORCH_WARMTH 0.18 // [0.0 0.05 0.1 0.15 0.18 0.2 0.25 0.3 0.4]
#define LVS_SUN_SHAFTS
#define LVS_SUN_SHAFT_STRENGTH 0.72 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.72 0.8 0.9 1.0 1.25 1.5 2.0]
#define LVS_SUN_SHAFT_SAMPLES 16 // [6 8 10 12 14 16 20 24 28 32]
#define LVS_SUN_SHAFT_DECAY 0.94 // [0.80 0.82 0.84 0.86 0.88 0.9 0.92 0.94 0.96 0.98]
#define LVS_SUN_SHAFT_GOLD 0.55 // [0.0 0.1 0.2 0.3 0.4 0.5 0.55 0.6 0.7 0.8 1.0]

#define LVS_BIOME_ATMOSPHERE 0 // [0 1]
#define LVS_BIOME_FOG_START 1.0
#define LVS_BIOME_FOG_DENSITY 0.0
#define LVS_BIOME_FOG_COLOR_STRENGTH 0.0
#define LVS_BIOME_FOG_STRENGTH 0.72 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.72 0.8 0.9 1.0 1.2]
#define LVS_BIOME_FOG_SATURATION 0.68 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.68 0.75 0.85 1.0]

#define BLOOM_QUALITY 1. // Reduces the resolution at which bloom is computed. (0.5 = half of default resolution) [0.5 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.6 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.7 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.8  0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.9  0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.  ]
#define VL_RENDER_RESOLUTION 0.5 // Reduces the resolution at which volumetric fog is computed. (0.5 = half of default resolution) [0.25 0.5 1.0]
