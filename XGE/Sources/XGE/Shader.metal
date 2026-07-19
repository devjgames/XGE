//
//  Shader.metal
//  XGE
//
//  Created by Douglas McNamara on 9/4/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float3 position;
    float2 textureCoordinate;
    float3 normal;
    float4 color;
};

struct FragmentInput {
    float4 position [[position]];
    float3 objPosition;
    float2 textureCoordinate;
    float3 normal;
    float4 color;
};

struct VertexData {
    float4x4 projection;
    float4x4 view;
    float4x4 model;
    float4x4 modelIT;
    int warpEnabled;
    float warpAmplitude;
    float warpFrequency;
    float warpTime;
    int warpY;
};

struct FragmentData {
    float3 eye;
    float4 ambientColor;
    float4 diffuseColor;
    float4 specularColor;
    float specularPower;
    int textureEnabled;
    int decalEnabled;
    int lightingEnabled;
    int lightCount;
};

struct Light {
    float3 position;
    float4 color;
    float radius;
};

vertex FragmentInput vertexShader(uint vertexID [[vertex_id]],
                                  constant VertexInput *vertices[[buffer(0)]],
                                  constant VertexData &data[[buffer(1)]]) {
    FragmentInput output;
    VertexInput input = vertices[vertexID];
    float4 position = data.model * float4(input.position, 1);
    
    if(data.warpEnabled != 0) {
        float3 b = position.xyz;
        
        position.x = b.x + data.warpAmplitude * sin(b.z * data.warpFrequency + data.warpTime) * cos(b.y * data.warpFrequency + data.warpTime);
        position.y = b.y + data.warpAmplitude * sin(b.x * data.warpFrequency + data.warpTime) * cos(b.z * data.warpFrequency + data.warpTime) * float(data.warpY);
        position.z = b.z + data.warpAmplitude * cos(b.x * data.warpFrequency + data.warpTime) * sin(b.y * data.warpFrequency + data.warpTime);
    }
    output.position = data.projection * data.view * position;
    output.objPosition = position.xyz;
    output.textureCoordinate = input.textureCoordinate;
    output.normal = normalize((data.modelIT * float4(input.normal, 0)).xyz);
    output.color = input.color;
                                           
    return output;
}

fragment float4 fragmentShader(FragmentInput in [[stage_in]],
                               texture2d<half> texture [[texture(0)]],
                               texture2d<half> decal [[texture(1)]],
                               constant FragmentData &data[[buffer(0)]],
                               constant Light *lights[[buffer(1)]]) {
    constexpr sampler s1(min_filter::nearest, mag_filter::nearest, address::repeat);
    float4 color = in.color;
    
    if(data.lightingEnabled != 0) {
        float3 position = in.objPosition;
        float3 normal = normalize(in.normal);
        float3 viewNormal = normalize(data.eye - in.objPosition);
        float4 vertexColor = color;

        color = vertexColor * data.ambientColor;
        for(int i = 0; i != data.lightCount; i++) {
            float3 lightOffset = lights[i].position - position;
            float3 lightNormal = normalize(lightOffset);
            float3 reflectedNormal = reflect(-lightNormal, normal);
            float lDotN = clamp(dot(lightNormal, normal), 0.0, 1.0);
            float spec = clamp(dot(reflectedNormal, viewNormal), 0.0, 1.0);
            float atten = 1.0 - clamp(length(lightOffset) / lights[i].radius, 0.0, 1.0);
            
            color += atten * (lDotN * vertexColor * data.diffuseColor + pow(spec, data.specularPower) * data.specularColor) * lights[i].color;
        }
    }
    
    if(data.textureEnabled != 0) {
        color *= float4(texture.sample(s1, in.textureCoordinate));
    }
    if(data.decalEnabled != 0) {
        float4 d = float4(decal.sample(s1, in.textureCoordinate));
        
        color.rgb = (1.0 - d.a) * color.rgb + d.a * d.rgb;
    }
    return color;
}
                                        


