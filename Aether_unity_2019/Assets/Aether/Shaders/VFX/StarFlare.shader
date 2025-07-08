Shader "Swifter/VFX/StarFlare"
{
Properties
    {
        _Sharpness ("Sharpness", Float) = 15
        _Brightness ("Brightness", Float) = 3
        _Color ("Color", Color) = (1,1,1)
        _Alpha ("Alpha", Float) = 0
        _Flutter ("Flutter", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2

        [Header(Graphic)][Space(10)]
        [Toggle(GRAPHIC)] _GraphicEnabled ("Enable Graphic", Int) = 0
        _GraphicNoise1Scale ("Noise 1 Scale", Float) = 8
        _GraphicNoise2Scale ("Noise 2 Scale", Float) = 15
        _GraphicNoise2Influence ("Noise 2 Influence", Float) = 0.4
        _GraphicNoiseInfluence ("Overall Noise Influence", Float) = 0.3
        _GraphicCutoff ("Cutoff", Float) = 0.6
        _GraphicSharpness ("Sharpness", Float) = 2

        [Header(Blend)][Space(10)]
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("BlendOp", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 1

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend [_BlendSrc] [_BlendDst]
        BlendOp [_BlendOp]
        ZWrite Off
        ZTest [_ZTest]
        Cull [_Cull]

        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            Pass [_StencilPass]
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature GRAPHIC

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "../Flutter.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Sharpness;
            float _Brightness;
            float3 _Color;
            float _Alpha;
            float _Flutter;

            float _GraphicNoise1Scale;
            float _GraphicNoise2Scale;
            float _GraphicNoise2Influence;
            float _GraphicNoiseInfluence;
            float _GraphicCutoff;
            float _GraphicSharpness;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            inline float posterize(float x, float n)
            {
                return round(x * n) / n;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 p = abs(i.uv * 2 - 1);

                float l = length(p);
                float d = saturate(1 - l);
                float r = pow(1. - p.x * p.y, _Sharpness);
                float v = r * d * d * _Brightness;

                v *= flutter(_Flutter);

                #if GRAPHIC
                float2 fireP = p * _GraphicNoise1Scale - _Time.y * 6;

                float n = simplex(fireP);

                fireP = p * _GraphicNoise2Scale - _Time.y * 3;

                n -= voronoi(fireP + n) * _GraphicNoise2Influence;

                v += n * _GraphicNoiseInfluence;

                v -= _GraphicCutoff;

                v = saturate(v);

                v = posterize(v, 3);

                v *= _GraphicSharpness;
                #endif

                return float4(v * _Color,v * _Alpha);
            }
            ENDCG
        }
    }
}
