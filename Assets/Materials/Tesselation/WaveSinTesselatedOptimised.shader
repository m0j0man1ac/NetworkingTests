Shader"Custom/WaveSinTesselatedOptimised"
{
    Properties{
        _MainTexture("Main texture", 2D) = "white" {}
        [NoScaleOffset] _NormalMap("Normal map", 2D) = "white" {}
        _NormalStrength("Normal strength", Float) = 1
        [NoScaleOffset] _HeightMap("Height map", 2D) = "white" {}
        _HeightMapAltitude("Height map altitude", Float) = 0
        // This keyword enum allows us to choose between calculating normals from a normal map or the height map
        [KeywordEnum(MAP, HEIGHT)] _GENERATE_NORMALS("Normal mode", Float) = 0
        //change tessellation calculations from view camera to a selected camera
        [KeywordEnum(USE_CURRENT_CAMERA, USE_ONLY_MAINCAM)] _CULLING_CAMERA_MODE("Culling Camera Mode", Float) = 0
        _SELECTED_CAMERA_WS("Camera World Space", Vector) = (0,0,0,0)
        _TessellationFactor("Tessellation Factor", float) = 1
        _TessellationBias("Tessellation Bias", float) = 0
        _FrustumCullTolerance("Cull Tolerance", float) = 20
        //_FactorEdge1("Edge factors", Vector) = (1, 1, 1, 0)
        //_FactorEdge2("Edge 2 factor", Float) = 1
        //_FactorEdge3("Edge 3 factor", Float) = 1
        //_FactorInside("Inside factor", Float) = 1
        // This keyword enum allows us to choose between partitioning modes. It's best to try them out for yourself
        [KeywordEnum(INTEGER, FRAC_EVEN, FRAC_ODD, POW2)] _PARTITIONING("Partition algoritm", Float) = 0
        _WaveHeighMult("Wave Amp", float) = 1
        _WaveFreqMult("Wave Freq", float) = 1
    }
    SubShader{
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        Pass 
        {
            Name"ForwardLit"
            Tags
            {"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma target 5.0 // 5.0 required for tessellation

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            // Material keywords
            #pragma shader_feature_local _PARTITIONING_INTEGER _PARTITIONING_FRAC_EVEN _PARTITIONING_FRAC_ODD _PARTITIONING_POW2

            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain WaveDomain
            #pragma fragment Fragment

            #include "HijackDomainWaveOptimised.hlsl"
            ENDHLSL
        }
    }
}
