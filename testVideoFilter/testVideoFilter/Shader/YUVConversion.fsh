precision highp float;

uniform sampler2D luminanceTexture;
uniform sampler2D chrominanceTexture;
uniform mat3 colorConversionMatrix;

varying vec2 textureCoordinate;

void main (void) {
    vec3 yuv = vec3(0.0, 0.0, 0.0);
    vec3 rgb = vec3(0.0, 0.0, 0.0);
    
    yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
    yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
    rgb = colorConversionMatrix * yuv;
    
    gl_FragColor = vec4(rgb, 1.0);
}
