//
//  default.metal
//  testMetalRender
//
//  Created by Lyman Li on 2020/5/3.
//  Copyright © 2020 Lyman Li. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 position;
    float2 texCoords;
} VertexIn;

typedef struct {
    float4 position [[position]];
    float2 texCoords;
} VertexOut;

typedef struct {
    float4x4 matrix;
} Constants;

typedef struct {
    float4 position [[position]];
    float2 texCoords;
    float2 overlayTexCoords;
} OverlayVertexOut;

// default

vertex VertexOut defaultVertexShader(const device VertexIn *vertexArray [[buffer(0)]],
                                     unsigned int vertexID [[vertex_id]]) {
    VertexOut vertexOut;
    vertexOut.position = vertexArray[vertexID].position;
    vertexOut.texCoords = vertexArray[vertexID].texCoords;
    return vertexOut;
}

fragment float4 defaultFragmentShader(VertexOut vertexIn [[stage_in]],
                                      texture2d <float, access::sample> inputImage [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 color = inputImage.sample(textureSampler, vertexIn.texCoords);
    return color;
}


// overlay

vertex OverlayVertexOut overlayVertexShader(const device VertexIn *vertexArray [[buffer(0)]],
                                            constant Constants *constants [[buffer(1)]],
                                            unsigned int vertexID [[vertex_id]]) {
    OverlayVertexOut vertexOut;
    vertexOut.position = vertexArray[vertexID].position;
    vertexOut.texCoords = vertexArray[vertexID].texCoords;
    float4 overlayTexCoords = float4(vertexArray[vertexID].texCoords.x,
                                     vertexArray[vertexID].texCoords.y,
                                     0,
                                     1);
    vertexOut.overlayTexCoords = (constants->matrix * overlayTexCoords).xy;
    return vertexOut;
}

fragment float4 overlayFragmentShader(OverlayVertexOut vertexIn [[stage_in]],
                                      texture2d <float, access::sample> inputImage [[texture(0)]],
                                      texture2d <float, access::sample> overlayImage [[texture(1)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 backgroundColor = inputImage.sample(textureSampler, vertexIn.texCoords);
    float4 overlayColor = overlayImage.sample(textureSampler, vertexIn.overlayTexCoords);
    return overlayColor * overlayColor.a + backgroundColor * (1 - overlayColor.a);
}
