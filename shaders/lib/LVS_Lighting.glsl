/*
 * LVS lighting overhaul - original project code.
 * Built around the Chocapic13 V9 lighting pipeline.
 *
 * Goals:
 * - softer, more readable direct sunlight
 * - stronger directional bounce from the sky
 * - warmer, more convincing artificial light
 * - controlled contact darkening without crushing shadows
 * - restrained broad sun highlights for a richer surface response
 */

#define LVS_SUN_SOFTNESS (1.0 - LVS_SOFT_LIGHTING)
#define LVS_SUN_WRAP 0.08
#define LVS_SKY_BOUNCE LVS_SKY_BOUNCE_STRENGTH
#define LVS_GROUND_BOUNCE LVS_GROUND_BOUNCE_STRENGTH
#define LVS_CONTACT_LIFT LVS_SHADOW_LIFT
#define LVS_SPECULAR_STRENGTH LVS_SUN_HIGHLIGHT
#define LVS_SPECULAR_POWER 48.0

vec3 lvsSafeNormalize(vec3 v){
    return v * inversesqrt(max(dot(v,v), 1e-6));
}

float lvsLambert(float ndl){
    float wrapped = (ndl + LVS_SUN_WRAP) / (1.0 + LVS_SUN_WRAP);
    return smoothstep(0.0, 1.0, clamp(wrapped, 0.0, 1.0));
}

float lvsSunResponse(float ndl){
    float d = lvsLambert(ndl);
    // Keeps broad forms readable while preserving strong noon lighting.
    return mix(d, pow(max(d, 0.0), 0.82), LVS_SUN_SOFTNESS);
}

vec3 lvsSkyBounce(vec3 normal, vec3 upLight, vec3 downLight){
    float up = max(normal.y, 0.0);
    float down = max(-normal.y, 0.0);
    return upLight * (up * LVS_SKY_BOUNCE) +
           downLight * (down * LVS_GROUND_BOUNCE);
}

vec3 lvsTorchColor(vec3 base){
    // Slightly warm without turning everything orange.
    vec3 warm = vec3(1.0, 0.72, 0.42);
    return mix(base, base * warm, LVS_TORCH_WARMTH);
}

float lvsContactLift(float skyLight){
    // Prevents caves and shadowed faces from becoming dead black.
    return LVS_CONTACT_LIFT * smoothstep(0.0, 0.65, skyLight);
}

vec3 lvsSunSpecular(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor, float shadowFactor, vec3 albedo){
    vec3 h = lvsSafeNormalize(viewDir + lightDir);
    float ndh = max(dot(normal, h), 0.0);
    float spec = pow(ndh, LVS_SPECULAR_POWER);
    float facing = smoothstep(0.0, 0.55, max(dot(normal, lightDir), 0.0));
    float viewFade = pow(1.0 - max(dot(normal, viewDir), 0.0), 2.0);
    float albedoMask = 1.0 - smoothstep(0.35, 0.92, dot(albedo, vec3(0.2126,0.7152,0.0722)));
    // Mostly visible at grazing angles and on darker/medium materials.
    float amount = spec * facing * (0.35 + 0.65 * viewFade) * (0.35 + 0.65 * albedoMask);
    return lightColor * amount * shadowFactor * LVS_SPECULAR_STRENGTH;
}

vec3 lvsLighting(
    vec3 albedo,
    vec3 normal,
    vec3 viewDir,
    vec3 lightDir,
    vec3 sunColor,
    vec3 ambientLight,
    vec3 skyUp,
    vec3 skyDown,
    float shadowFactor,
    float skyLight,
    float torchLight,
    vec3 torchColor,
    float lightSign
){
    float ndl = max(dot(normal, lightDir), 0.0);
    float direct = lvsSunResponse(ndl);

    // Warm sunrise/sunset and cool moonlight without a costly extra pass.
    float horizonLight = 1.0 - smoothstep(0.10, 0.52, abs(lightDir.y));
    float sunMask = step(0.0, lightSign);
    float moonMask = 1.0 - sunMask;
    vec3 golden = mix(vec3(1.0), vec3(1.08, 0.86, 0.62), horizonLight * LVS_GOLDEN_HOUR * sunMask);
    vec3 moonTint = mix(vec3(0.92, 0.96, 1.0), vec3(0.72, 0.82, 1.0), LVS_MOONLIGHT * moonMask);
    vec3 lightTint = mix(moonTint, golden, sunMask);

    // Keep shadowed areas alive with sky bounce instead of flat ambient fill.
    vec3 bounce = lvsSkyBounce(normal, skyUp, skyDown);
    bounce *= (0.55 + 0.45 * skyLight);

    vec3 directLight = sunColor * lightTint * direct * shadowFactor;
    vec3 specular = lvsSunSpecular(normal, viewDir, lightDir, sunColor * lightTint, shadowFactor, albedo);

    float torch = torchLight;
    vec3 torchLit = lvsTorchColor(torchColor) * torch;

    vec3 result = ambientLight + bounce + directLight + specular + torchLit;
    result += vec3(lvsContactLift(skyLight) + LVS_AMBIENT_LIFT * skyLight);
    // Slightly darker daylight without crushing night lighting.
    result *= mix(1.0, LVS_DAY_DARKEN, sunMask);
    return max(result, vec3(0.0));
}
