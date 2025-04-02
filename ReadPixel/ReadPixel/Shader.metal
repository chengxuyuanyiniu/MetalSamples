//
//  Shader.metal
//
//

#include <metal_stdlib>
using namespace metal;


struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

struct Vertex {
    float4 position;
    float4 color;
};


vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                           constant Vertex *vertices [[buffer(0)]]) {
    RasterizerData out;
    out.position = vertices[vertexID].position;
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}
