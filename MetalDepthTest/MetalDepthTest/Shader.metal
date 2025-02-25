//
//  Shader.metal
//  HelloTriangle
//
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;


struct RasterizerData {
    float4 position [[position]];
    float2 textureCoordinate;
};

struct Vertex {
    float3 pixelPosition;
    float2 textureCoordinate;
};


vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                           constant Vertex *vertices [[buffer(0)]],
                                   constant uint2 *viewportSizePointer [[buffer(1)]]
                                   ) {
    float2 pixelPosition = vertices[vertexID].pixelPosition.xy;
    float2 viewportSize = float2(*viewportSizePointer);
    RasterizerData out;
    out.position = float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelPosition / (viewportSize / 2.0);
    out.position.z = vertices[vertexID].pixelPosition.z;
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[texture(0)]]
                               ) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}
