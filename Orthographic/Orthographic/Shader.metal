

#include <metal_stdlib>
using namespace metal;


struct Uniforms {
    float4x4 projectionMatrix;
    float4x4 rotationMatrix;
    float4x4 viewMatrix;
};

struct RasterizerData {
    float4 position [[position]];
    float2 textureCoordinate;
};

struct Vertex {
    float4 position;
    float2 textureCoordinate;
};


vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                           constant Vertex *vertices [[buffer(0)]],
                           constant Uniforms &uniforms [[buffer(1)]]
                                   
                                   ) {
    RasterizerData out;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.rotationMatrix * vertices[vertexID].position;
    out.textureCoordinate = vertices[vertexID].textureCoordinate;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[texture(0)]]
                               )  {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}
