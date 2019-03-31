precision highp float;

uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

uniform float Time;

const float PI = 3.1415926;
const float duration = 2.0;

vec4 getMask(float time, vec2 textureCoords, float padding) {
    vec2 translation = vec2(sin(time * (PI * 2.0 / duration)),
                            cos(time * (PI * 2.0 / duration)));
    vec2 translationTextureCoords = textureCoords + padding * translation;
    vec4 mask = texture2D(Texture, translationTextureCoords);
    
    return mask;
}

float maskAlphaProgress(float currentTime, float hideTime, float startTime) {
    float time = mod(duration + currentTime - startTime, duration);
    return min(time, hideTime);
}

void main (void) {
    float time = mod(Time, duration);
    
    float scale = 1.2;
    float padding = 0.5 * (1.0 - 1.0 / scale);
    vec2 textureCoords = vec2(0.5, 0.5) + (TextureCoordsVarying - vec2(0.5, 0.5)) / scale;
    
    float hideTime = 0.7;
    float maxAlpha = 0.5;
    float timeGap = 0.3;
    
    vec4 mask = getMask(time, textureCoords, padding);
    float alpha = 1.0;
    
    vec4 resultMask;
    
    for (float f = 0.0; f < duration; f += timeGap) {
        float time0 = f;
        vec4 mask0 = getMask(time0, textureCoords, padding);
        float alpha0 = maxAlpha - maxAlpha * maskAlphaProgress(time, hideTime, time0) / hideTime;
        resultMask += mask0 * alpha0;
        alpha -= alpha0;
    }
    resultMask += mask * alpha;

    gl_FragColor = resultMask;
}
