attribute vec3 position;
attribute vec2 inputTextureCoordinate;
varying vec2 textureCoordinate;

void main (void) {
    textureCoordinate = inputTextureCoordinate;
    gl_Position = vec4(position.x, position.y, position.z, 1.0);
}
