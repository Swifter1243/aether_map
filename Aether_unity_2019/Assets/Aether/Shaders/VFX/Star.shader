Shader "Swifter/VFX/Star"
{
    Properties
    {
        _Bend ("Bend", Float) = 0.5
        _Size ("Size", Float) = 1.35
        _Spread ("Spread", Float) = 0.2
        _Alpha ("Alpha", Float) = 0.5
        _Thickness ("Thickness", Float) = 0.07
        _Flutter ("Flutter", Float) = 0
        _Softness ("Softness", Float) = 7
        _Opacity ("Opacity", Float) = 1
        [Toggle(CLAMP)] _Clamp ("Clamp", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4

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
        Cull Off

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
            #pragma shader_feature CLAMP

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

            float _Bend;
            float _Size;
            float _Spread;
            float _Alpha;
            float _Thickness;
            float _Flutter;
            float _Opacity;
            float _Softness;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 p = abs(i.uv * 2 - 1);
                float edgeDist = smoothstep(1, 0.5, p.x*p.x + p.y*p.y);
                p *= _Size;

                float s = pow(p.x, _Bend) + pow(p.y, _Bend);
                float d = abs(s - 1) - _Thickness;

                float value = smoothstep(_Spread, 0, d);
                value *= edgeDist;

                value = pow(value * 2, _Softness);

                value *= flutter(_Flutter);

                #if CLAMP
                value = saturate(value) * _Opacity;
                #else
                value = max(0, value) * _Opacity;
                #endif

                return float4(value, value, value, value * _Alpha);
            }
            ENDCG
        }
    }
}
