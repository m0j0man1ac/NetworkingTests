#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#define IGNORE_TESSELLATION_CBUFFER

TEXTURE2D(_MainTexture); SAMPLER(sampler_MainTexture);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
TEXTURE2D(_HeightMap); SAMPLER(sampler_HeightMap);

CBUFFER_START(UnityPerMaterial)
    float4 _MainTexture_ST;
    float4 _MainTexture_TexelSize;
    float _NormalStrength;
    float _HeightMapAltitude;
    float _CULLING_CAMERA_MODE;
    float3 _SELECTED_CAMERA_WS;
    float _TessellationFactor;
    float _TessellationBias;
    float _TessellationSmoothing;
    float _FrustumCullTolerance;
    float _BackFaceCullTolerance;
    float _WaveHeighMult;
    float _WaveFreqMult;
CBUFFER_END

#include "TessellationFactorsOptimised.hlsl"

// The domain function runs once per vertex in the final, tessellated mesh
// Use it to reposition vertices and prepare for the fragment stage
[domain("tri")] // Signal we're inputting triangles
Interpolators WaveDomain(
    TessellationFactors factors, // The output of the patch constant function
    OutputPatch<TessellationControlPoint, 3> patch, // The Input triangle
    float3 barycentricCoordinates : SV_DomainLocation) // The barycentric coordinates of the vertex on the triangle
{
    UNITY_SETUP_INSTANCE_ID(patch[0]);
    UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        
    Interpolators output = Domain(factors, patch, barycentricCoordinates);
    //Interpolators output;
    
    output.positionWS = output.positionWS + 
        sin(_Time + output.positionWS.x * _WaveFreqMult) * float3(0, 1, 0) * _WaveHeighMult;
        
    //output.positionWS = float3(0, 0, 0);
    output.normalWS = float3(0, 1, 0);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    return output;
}