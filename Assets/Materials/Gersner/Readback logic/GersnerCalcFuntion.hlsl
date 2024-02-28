#define PI 3.14159265359

//Gersner Wave Function for multiple waves
float3 GerstnerWavePosition(float4 wave, float3 p)
{
    float steepness = wave.z;
    float wavelength = wave.w;
    float k = 2 * PI / wavelength;
    float c = sqrt(9.8 / k);
    float2 d = normalize(wave.xy);
    float f = k * (dot(d, p.xz) - c * _Time);
    float a = steepness / k;
    
 //   tangent += float3(
	//	-d.x * d.x * (steepness * sin(f)),
	//	d.x * (steepness * cos(f)),
	//	-d.x * d.y * (steepness * sin(f))
	//);
 //   binormal += float3(
	//	-d.x * d.y * (steepness * sin(f)),
	//	d.y * (steepness * cos(f)),
	//	-d.y * d.y * (steepness * sin(f))
	//);

    return float3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a * cos(f))
	);
}

//summing multiple waves
float3 SummedGerstnerPosition(float3 position, int backstepIterations,
    float4 waveA, float4 waveB, float4 waveC)
{
    position.y = 0;
    float3 p = position;
	
    //backstep 1
    p -= GerstnerWavePosition(waveA, position);
    p -= GerstnerWavePosition(waveB, position);
    p -= GerstnerWavePosition(waveC, position);
    
    p.y = 0;
    float3 newPos = p;

    //backstep 2
    p += GerstnerWavePosition(waveA, newPos);
    p += GerstnerWavePosition(waveB, newPos);
    p += GerstnerWavePosition(waveC, newPos);

    return p;
}