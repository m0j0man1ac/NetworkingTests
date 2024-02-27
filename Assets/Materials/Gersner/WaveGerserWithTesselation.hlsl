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
    
    //sin wave params
    //float _WaveHeighMult;
    //float _WaveFreqMult;

    //gersner wave params
    //float4 _WaveDirection;
    ////float _WaveSpeed;
    //float _Wavelength;
    //float _Steepness;
    float4 _WaveA;
    float4 _WaveB;
    float4 _WaveC;
    float _WaveGravity;
    //float _WaveAmplitude;
    float _WaveHorizontalStrength;
    float _WaveVerticalStrength;
CBUFFER_END

#define PI 3.14159265359

#include "TessellationFactorsOptimised.hlsl"

//Gersner Wave Function for multiple waves
float3 GerstnerWave(float4 wave, float3 p, 
    inout float3 tangent, inout float3 binormal)
{
    float steepness = wave.z;
    float wavelength = wave.w;
    float k = 2 * PI / wavelength;
    float c = sqrt(9.8 / k);
    float2 d = normalize(wave.xy);
    float f = k * (dot(d, p.xz) - c * _Time.y);
    float a = steepness / k;
    
    tangent += float3(
		-d.x * d.x * (steepness * sin(f)),
		d.x * (steepness * cos(f)),
		-d.x * d.y * (steepness * sin(f))
	);
    binormal += float3(
		-d.x * d.y * (steepness * sin(f)),
		d.y * (steepness * cos(f)),
		-d.y * d.y * (steepness * sin(f))
	);
    return float3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a * cos(f))
	);
}

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
    
    //MY GERSNER
    /*
    //get wave direction vector from angle in degrees
    float dirAngleRad = _WaveDirection * PI / 180;
    float2 waveDir = float2(sin(dirAngleRad), cos(dirAngleRad));
    
    //get wave input distance for displacement calculation in direction of waves
    float waveInput = waveDir * (output.positionWS.xz - waveDir);
    
    //displacement horizontally
    float2 horizontalDisplace = waveDir * cos(waveInput + _Time * _WaveSpeed) * _WaveHorizontalStrength;
    //diplacement vertically
    float verticalDisplace = sin(waveInput + _Time * _WaveSpeed) * _WaveVerticalStrength;
    
    //finalise world position
    output.positionWS += float3(horizontalDisplace.x, verticalDisplace, horizontalDisplace.y);
    */
    
    //cat like coding
    //position
    //single wave shit
      //  float k = 2 * PI / _Wavelength;
      //  float c = sqrt(_WaveGravity / k);
      //  float2 dir = normalize(_WaveDirection);
      //  float waveInput = k * (dot(dir, output.positionWS.xz) + _Time * c);
      //  float a = _Steepness / k;
      //  output.positionWS.x += dir.x * (a * cos(waveInput)) * _WaveHorizontalStrength;
      //  output.positionWS.y = a * sin(waveInput) * _WaveVerticalStrength;
      //  output.positionWS.z += dir.y * (a * cos(waveInput)) * _WaveHorizontalStrength;
      //  //normals
      //  float3 tangent = float3(
      //      1 - dir.x * dir.x * (_Steepness * sin(waveInput)),
		    //dir.x * (_Steepness * cos(waveInput)),
		    //-dir.x * dir.y * (_Steepness * sin(waveInput))
      //  );
      //  float3 binormal = float3(
      //      -dir.x * dir.y * (_Steepness * sin(waveInput)),
		    //dir.y * (_Steepness * cos(waveInput)),
		    //1 - dir.y * dir.y * (_Steepness * sin(waveInput))
      //  );
      //  float3 normal = normalize(cross(binormal, tangent));
    
    //catlike coding waves
    //support for summing gersner waves
    float3 tangent = float3(1, 0, 0);
    float3 binormal = float3(0, 0, 1);
    float3 p = output.positionWS;
    p += GerstnerWave(_WaveA, output.positionWS, tangent, binormal);
    p += GerstnerWave(_WaveB, output.positionWS, tangent, binormal);
    p += GerstnerWave(_WaveC, output.positionWS, tangent, binormal);
    float3 normal = normalize(cross(binormal, tangent));
    
    //finalise
    output.positionWS = p;
    output.normalWS = normal;
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    return output;
}