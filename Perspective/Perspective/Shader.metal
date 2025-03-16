//
//  Shader.metal
//  HelloTriangle
//
//

#include <metal_stdlib>
using namespace metal;


struct Uniforms {
    float4x4 projectionMatrix;
    float4x4 rotationMatrix;
};

struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

struct Vertex {
    float4 position;
    float4 color;
};


vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                           constant Vertex *vertices [[buffer(0)]],
                           constant Uniforms &uniforms [[buffer(1)]]
                                   
                                   ) {
    RasterizerData out;
    out.position = uniforms.projectionMatrix * uniforms.rotationMatrix * vertices[vertexID].position;

//    out.position = vertices[vertexID].position;
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}
