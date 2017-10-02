// Depth to view/world space position conversion example
#include "UnityCG.cginc"

sampler2D _MainTex;
sampler2D _CameraDepthTexture;

half _Intensity;

struct Varyings
{
    float4 position : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    float3 ray : TEXCOORD1;
};

// Vertex shader that procedurally outputs a full screen triangle
Varyings Vertex(uint vertexID : SV_VertexID)
{
    // Render settings
    float far = _ProjectionParams.z;
    float2 orthoSize = unity_OrthoParams.xy;
    float isOrtho = unity_OrthoParams.w; // 0: perspective, 1: orthographic

    // Vertex ID -> clip space vertex position
    float x = (vertexID != 1) ? -1 : 3;
    float y = (vertexID == 2) ? -3 : 1;
    float4 vpos = float4(x, y, 1, 1);

    // Perspective: view space vertex position of the far plane
    float3 rayPers = mul(unity_CameraInvProjection, vpos) * far;

    // Orthographic: view space vertex position
    float3 rayOrtho = float3(orthoSize * vpos.xy, 0);

    Varyings o;
    o.position = vpos;
    o.texcoord = (vpos.xy + 1) / 2;
    o.ray = lerp(rayPers, rayOrtho, isOrtho);
    return o;
}

float3 ComputeViewSpacePosition(Varyings input)
{
    // Render settings
    float near = _ProjectionParams.y;
    float far = _ProjectionParams.z;
    float isOrtho = unity_OrthoParams.w; // 0: perspective, 1: orthographic

    // Z buffer sample
    float z = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.texcoord);

    // Perspective: view space position = ray * depth
    float3 vposPers = input.ray * Linear01Depth(z);

    // Orthographic: linear depth (with reverse-Z support)
#if defined(UNITY_REVERSED_Z)
    float depthOrtho = -lerp(far, near, z);
#else
    float depthOrtho = -lerp(near, far, z);
#endif

    // Orthographic: view space position
    float3 vposOrtho = float3(input.ray.xy, depthOrtho);

    // Result: view space position
    return lerp(vposPers, vposOrtho, isOrtho);
}

half4 VisualizePosition(Varyings input, float3 pos)
{
    half4 source = tex2D(_MainTex, input.texcoord);
    half3 color = pow(abs(cos(pos * UNITY_PI * 4)), 20);
    return half4(lerp(source.rgb, color, _Intensity), source.a);
}
