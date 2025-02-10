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
    float2 pixelPosition;
    float2 textureCoordinate;
};

// Drawable Render Pass
vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                           constant Vertex *vertices [[buffer(0)]],
                                   constant uint2 *viewportSizePointer [[buffer(1)]]
                                   ) {
    float2 pixelPosition = vertices[vertexID].pixelPosition;
    float2 viewportSize = float2(*viewportSizePointer);
    RasterizerData out;
    out.position = float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelPosition / (viewportSize / 2.0);
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

// Grayscale compute kernel
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

kernel void
grayscaleKernel(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                uint2                          gid        [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    half  gray     = dot(inColor.rgb, kRec709Luma);
    outTexture.write(half4(gray, gray, gray, 1.0), gid);
}
