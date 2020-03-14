precision highp float;

uniform sampler2D renderTexture;
varying vec2 textureCoordinate;

void main (void) {
    vec4 mask = texture2D(renderTexture, textureCoordinate);
    gl_FragColor = vec4(mask.rgb, 1.0);
}
