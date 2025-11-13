#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(const device VertexIn *vertexArray [[buffer(0)]], uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertexArray[vid].position, 0, 1);
    out.texCoord = vertexArray[vid].texCoord;
    return out;
}

// RGBA/RGB Passthrough
fragment float4 fragmentShaderRGBA(VertexOut in [[stage_in]], texture2d<float> tex [[ texture(0) ]]) {
    constexpr sampler samplr(mag_filter::linear, min_filter::linear, mip_filter::none);
    return tex.sample(samplr, in.texCoord);
}

fragment half4 fragmentShaderYUV420(VertexOut in [[stage_in]],
                              texture2d<half, access::sample> texY [[texture(0)]],
                              texture2d<half, access::sample> texU [[texture(1)]],
                              texture2d<half, access::sample> texV [[texture(2)]])
{
    constexpr sampler s (mag_filter::linear, min_filter::linear, mip_filter::none);
    half y = texY.sample(s, in.texCoord).r;
    half u = texU.sample(s, in.texCoord).r - 0.5h;
    half v = texV.sample(s, in.texCoord).r - 0.5h;

    half r = y + 1.402h * v;
    half g = y - 0.344136h * u - 0.714136h * v;
    half b = y + 1.772h * u;

    return half4(r, g, b, 1.0h);
}
