//variables
#define PI 3.14159265
#define maxDist 4
#define animTime 0.5

// The main function for the custom node
void BounceCalcs_float(float Time, float ImpactTime, 
    float3 ImpactPoint, float3 ImpactDir, float3 VertexPos, 
    out float3 OUT)
{
    OUT = VertexPos;
    
    //actual logic    
    float dist = distance(VertexPos, ImpactPoint);
    float strengthMultDist = ((maxDist - dist) * step(dist, maxDist)) / maxDist; //if distance more than returns 0
    strengthMultDist = sin(strengthMultDist/2 * PI);
    
    float timeDif = abs(ImpactTime - Time);
    float normalisedAnimTime = (timeDif * step(timeDif, animTime)) / animTime; //if time dif > animTime returns 0
    float strengthMultTime = sin(normalisedAnimTime * PI);
    
    OUT = VertexPos +  ImpactDir * strengthMultDist * strengthMultTime * 2;
}