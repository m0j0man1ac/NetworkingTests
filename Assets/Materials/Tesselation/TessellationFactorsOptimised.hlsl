// MIT License

// Copyright (c) 2021 NedMakesGames

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef TESSELLATION_FACTORS_INCLUDED
#define TESSELLATION_FACTORS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
#ifdef LIGHTMAP_ON
    float2 lightmapUV : TEXCOORD1;
#endif
#ifdef REQUIRES_VERTEX_COLORS
    float4 color : COLOR;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct TessellationFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct TessellationControlPoint
{
    float4 positionCS : SV_Position;
    float3 positionWS : INTERNALTESSPOS;
    float3 normalWS : NORMAL;
    float4 tangentWS : TANGENT;
    float2 uv : TEXCOORD0;
#ifdef LIGHTMAP_ON
    float2 lightmapUV : TEXCOORD1;
#endif
#ifdef REQUIRES_VERTEX_COLORS
    float4 color : COLOR;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Interpolators
{
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4); // Lightmap UVs or light probe color
    float4 fogFactorAndVertexLight : TEXCOORD5;
    float4 positionCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#ifdef IGNORE_TESSELLATION_CBUFFER
#else    
// Properties
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
    //float _WaveHeighMult;
    //float _WaveFreqMult;
CBUFFER_END
#endif

//define use viewpoint camera or a specific camera for debugging the culling from another angle
#if defined(USE_CURRENT_CAMERA)
    #define CAMERA_POS _WorldSpaceCameraPos
#elif defined(USE_ONLY_MAINCAM)
    #define CAMERA_POS _SELECTED_CAMERA_WS
#else
    #define CAMERA_POS _WorldSpaceCameraPos
#endif

float3 GetViewDirectionFromPosition(float3 positionWS)
{
    return normalize(CAMERA_POS - positionWS);
}

float4 GetShadowCoord(float3 positionWS, float4 positionCS)
{
    // Calculate the shadow coordinate depending on the type of shadows currently in use
    #if SHADOWS_SCREEN
        return ComputeScreenPos(positionCS);
    #else
        return TransformWorldToShadowCoord(positionWS);
    #endif
}

TessellationControlPoint Vertex(Attributes input)
{
    TessellationControlPoint output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

    output.positionWS = posnInputs.positionWS;
    output.positionCS = posnInputs.positionCS;
    output.normalWS = normalInputs.normalWS;
    
    output.tangentWS = float4(normalInputs.tangentWS, input.tangentOS.w); // tangent.w containts bitangent multiplier
    output.uv = TRANSFORM_TEX(input.uv, _MainTexture); // Apply texture tiling and offset
#ifdef LIGHTMAP_ON
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
#endif
#ifdef REQUIRES_VERTEX_COLORS
    output.color = input.color;
#endif
        
    return output;
}

#define TOLERANCE _FrustumCullTolerance
    
//return true if the point is outside the boundsset by variables
bool IsOutOfBounds(float3 p, float3 lower, float3 higher)
{
    return p.x < lower.x || p.x > higher.x || p.y < lower.y || p.y > higher.y || p.z < lower.z || p.z > higher.z;
}

// returns true if given vertex is outside camera frustum
bool IsPointOutsideFrustum(float4 positionCS, float tolerance)
{
    float3 culling = positionCS.xyz;
    float w = positionCS.w;
    // UNITY RAW FAR CLIP is either 0 or 1, depending on graphics API
    // most use 0, however OpenGL uses 1
    float3 lowerBounds = float3(-w, -w, -w * UNITY_RAW_FAR_CLIP_VALUE) - float3(1,1,1)*tolerance;
    float3 higherBounds = float3(w, w, w) + float3(1,1,1)*tolerance;
    return IsOutOfBounds(culling, lowerBounds, higherBounds);
}
    
// returns true if the points in this triangle are facing away, and wound counter-clockwise
bool ShouldBackFaceCull(float4 p0PositionCS, float4 p1PositionCS, float4 p2PositionCS, float tolerance)
{
    float3 point0 = p0PositionCS.xyz / p0PositionCS.w;
    float3 point1 = p1PositionCS.xyz / p1PositionCS.w;
    float3 point2 = p2PositionCS.xyz / p2PositionCS.w;
        
    // in clip space, the view direciton is float3(0,0,1), so we can just test z
    #if UNITY_REVERSED_Z
        return cross(point1 - point0, point2 - point0).z < -tolerance;
    #else
        return cross(point1 - point0, point2 - point0).z > tolerance;
    #endif
}
    
    // returns true if patch should be clipped due to frustum or winding (backface) culling
    bool ShouldClipPatch(float4 p0PositionCS, float4 p1PositionCS, float4 p2PositionCS)
    {
        bool allOutside = IsPointOutsideFrustum(p0PositionCS, TOLERANCE) &&
        IsPointOutsideFrustum(p1PositionCS, TOLERANCE) &&
        IsPointOutsideFrustum(p2PositionCS, TOLERANCE);
    
        return allOutside || ShouldBackFaceCull(p0PositionCS, p1PositionCS, p2PositionCS, TOLERANCE);
    }
    
    //calculate the tesselation factor for an edge
    //this function needs world and clip space positions
    float EdgeTesselationFactor(float scale, float bias, 
        float3 p0PositionWS, float3 p0PositionCS, float3 p1PositionWS, float3 p1PositionCS)
    {
        float length = distance(p0PositionWS, p1PositionWS);
        float distanceToCamera = distance(CAMERA_POS, (p0PositionWS + p1PositionWS) * 0.5);
        float factor = length / (scale * distanceToCamera * distanceToCamera);
        
        return max(1, factor + bias);
    }

// The patch constant function runs once per triangle, or "patch"
// It runs in parallel to the hull function
TessellationFactors PatchConstantFunction(
    InputPatch<TessellationControlPoint, 3> patch)
{
    UNITY_SETUP_INSTANCE_ID(patch[0]); // Set up instancing
    
    // Calculate tessellation factors
    TessellationFactors f;
    // check if should be culled
    if (ShouldClipPatch(patch[0].positionCS, patch[1].positionCS, patch[2].positionCS))
    {
        f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0; //cull
    }
    else
    {   
        f.edge[0] = EdgeTesselationFactor(_TessellationFactor, _TessellationBias,
            patch[1].positionWS, patch[1].positionCS, patch[2].positionWS, patch[2].positionCS);
        f.edge[1] = EdgeTesselationFactor(_TessellationFactor, _TessellationBias,
            patch[2].positionWS, patch[2].positionCS, patch[0].positionWS, patch[0].positionCS);
        f.edge[2] = EdgeTesselationFactor(_TessellationFactor, _TessellationBias,
            patch[0].positionWS, patch[0].positionCS, patch[1].positionWS, patch[1].positionCS);
        
        f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) / 3;
    }
            
    return f;
}

// The hull function runs once per vertex. You can use it to modify vertex
// data based on values in the entire triangle
[domain("tri")] // Signal we're inputting triangles
[outputcontrolpoints(3)] // Triangles have three points
[outputtopology("triangle_cw")] // Signal we're outputting triangles
[patchconstantfunc("PatchConstantFunction")] // Register the patch constant function
// Select a partitioning mode based on keywords
#if defined(_PARTITIONING_INTEGER)
[partitioning("integer")]
#elif defined(_PARTITIONING_FRAC_EVEN)
[partitioning("fractional_even")]
#elif defined(_PARTITIONING_FRAC_ODD)
[partitioning("fractional_odd")]
#elif defined(_PARTITIONING_POW2)
[partitioning("pow2")]
#else 
[partitioning("fractional_odd")]
#endif
TessellationControlPoint Hull(
    InputPatch<TessellationControlPoint, 3> patch, // Input triangle
    uint id : SV_OutputControlPointID) // Vertex index on the triangle
{

    return patch[id];
}

// Call this macro to interpolate between a triangle patch, passing the field name
#define BARYCENTRIC_INTERPOLATE(fieldName) \
	patch[0].fieldName * barycentricCoordinates.x + \
	patch[1].fieldName * barycentricCoordinates.y + \
	patch[2].fieldName * barycentricCoordinates.z

// The domain function runs once per vertex in the final, tessellated mesh
// Use it to reposition vertices and prepare for the fragment stage
    [domain("tri")] // Signal we're inputting triangles
    Interpolators Domain(TessellationFactors factors, // The output of the patch constant function
        OutputPatch<TessellationControlPoint, 3> patch, // The Input triangle
        float3 barycentricCoordinates : SV_DomainLocation) // The barycentric coordinates of the vertex on the triangle
    { 

        Interpolators output;

    // Setup instancing and stereo support (for VR)
        UNITY_SETUP_INSTANCE_ID(patch[0]);
        UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    
        float3 positionWS = BARYCENTRIC_INTERPOLATE(positionWS);
        float3 normalWS = BARYCENTRIC_INTERPOLATE(normalWS);
        float3 tangentWS = BARYCENTRIC_INTERPOLATE(tangentWS.xyz);
        
        float2 uv = BARYCENTRIC_INTERPOLATE(uv); // Interpolate UV
        // Sample the height map and offset position along the normal vector accordingly
        float height = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, uv, 0).r * _HeightMapAltitude;
        positionWS += normalWS * height;

        output.uv = uv;
        output.positionCS = TransformWorldToHClip(positionWS);
        output.normalWS = normalWS;
        output.positionWS = positionWS;
        output.tangentWS = float4(tangentWS, patch[0].tangentWS.w);
    
    #ifdef LIGHTMAP_ON
        output.lightmapUV = BARYCENTRIC_INTERPOLATE(lightmapUV);
    #else
        OUTPUT_SH(output.normalWS, output.vertexSH);
    #endif
        float fogFactor = ComputeFogFactor(output.positionCS.z);
        float3 vertexLight = VertexLighting(output.positionWS, output.normalWS);
        output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);
    
        return output;
    }

    // Sample the height map, using mipmaps
    float SampleHeight(float2 uv)
    {
        return SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv).r;
    }

    // Calculate a normal vector by sampling the height map
    float3 GenerateNormalFromHeightMap(float2 uv)
    {
        // Sample the height from adjacent pixels
        float left = SampleHeight(uv - float2(_MainTexture_TexelSize.x, 0));
        float right = SampleHeight(uv + float2(_MainTexture_TexelSize.x, 0));
        float down = SampleHeight(uv - float2(0, _MainTexture_TexelSize.y));
        float up = SampleHeight(uv + float2(0, _MainTexture_TexelSize.y));

        // Generate a tangent space normal using the slope along the U and V axes
        float3 normalTS = float3((left - right) / (_MainTexture_TexelSize.x * 2), (down - up) / (_MainTexture_TexelSize.y * 2), 1);

        normalTS.xy *= _NormalStrength; // Adjust the XY channels to create stronger or weaker normals
        return normalize(normalTS);
    }

    float4 Fragment(Interpolators input) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        
        float4 mainSample = SAMPLE_TEXTURE2D(_MainTexture, sampler_MainTexture, input.uv);

        float3x3 tangentToWorld = CreateTangentToWorld(input.normalWS, input.tangentWS.xyz, input.tangentWS.w);
        // Calculate a tangent space normal either from the normal map or the height map
    #if defined(_GENERATE_NORMALS_MAP)
        float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _NormalStrength);
    #elif defined(_GENERATE_NORMALS_HEIGHT)
        float3 normalTS = GenerateNormalFromHeightMap(input.uv);
    #else
        float3 normalTS = float3(0, 0, 1);
    #endif
        float3 normalWS = normalize(TransformTangentToWorld(normalTS, tangentToWorld)); // Convert to world space

    // Fill the various lighting and surface data structures for the PBR algorithm
        InputData lightingInput = (InputData) 0; // Found in URP/Input.hlsl
        lightingInput.positionWS = input.positionWS;
        lightingInput.normalWS = normalize(input.normalWS);
        lightingInput.viewDirectionWS = GetViewDirectionFromPosition(lightingInput.positionWS);
        lightingInput.shadowCoord = GetShadowCoord(lightingInput.positionWS, input.positionCS);
        lightingInput.fogCoord = input.fogFactorAndVertexLight.x;
        lightingInput.vertexLighting = input.fogFactorAndVertexLight.yzw;
        lightingInput.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, lightingInput.normalWS);
        lightingInput.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
        lightingInput.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);

        SurfaceData surface = (SurfaceData) 0; // Found in URP/SurfaceData.hlsl
        surface.albedo = mainSample.rgb;
        surface.alpha = mainSample.a;
        surface.metallic = 0;
        surface.smoothness = 0.5;
        surface.normalTS = normalTS;
        surface.occlusion = 1;

        return UniversalFragmentPBR(lightingInput, surface);
    }

#endif