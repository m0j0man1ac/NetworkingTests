Shader "Custom/CustomTesselationSinWave"
{
    Properties{
        _TestingProperty("Test", float) = 1
        _FactorEdge1("Edge factors", Vector) = (1, 1, 1, 0)
        //_FactorEdge2("Edge 2 factor", Float) = 1
        //_FactorEdge3("Edge 3 factor", Float) = 1
        _FactorInside("Inside factor", Float) = 1
        // This keyword enum allows us to choose between partitioning modes. It's best to try them out for yourself
        [KeywordEnum(INTEGER, FRAC_EVEN, FRAC_ODD, POW2)] _PARTITIONING("Partition algoritm", Float) = 0
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

            #include "HijackDomainWave.hlsl"
            ENDHLSL
        }
    }
}
