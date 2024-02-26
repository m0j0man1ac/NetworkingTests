#include "TessellationFactors.hlsl"

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
    
    output.positionWS += sin(_Time + output.positionWS.x) * float3(0, 1, 0);
        
    //output.positionWS = float3(0, 0, 0);
    output.normalWS = float3(0, 1, 0);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    return output;
}