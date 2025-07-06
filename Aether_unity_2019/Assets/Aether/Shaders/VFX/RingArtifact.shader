Shader "Swifter/VFX/RingArtifact"
{
    Properties
    {
        _Saturation ("Saturation", Range(0,1)) = 0.4
        _Intensity ("Intensity", Float) = 3
        _End ("End", Float) = 0.3
        _Power ("Power", Float) = 3
        _Scale ("Scale", Float) = 4
        _Flutter ("Flutter", Float) = 0
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
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend One One
        BlendOp [_BlendOp]
        ZWrite Off
        ZTest [_ZTest]

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

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"
            #include "../Flutter.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            float _Saturation;
            float _Intensity;
            float _End;
            float _Power;
            float _Scale;
            float _Flutter;
            bool _Invert;

            fixed4 frag(v2f i) : SV_Target
            {
                float2 p = i.uv.xy * 2 - 1;

                float len = length(p);
                float d = max(0, abs(len - 0.5));

                float vStart = smoothstep(0, _End, len);
                float vEnd = smoothstep(1, _End, len);

                float v = pow(vStart * vEnd, _Power) * _Intensity;

                v *= flutter(_Flutter);

                v = max(0, v);

                float3 ringCol = lerp(1, rainbow(len * _Scale), _Saturation);

                return float4(ringCol * v * i.color.rgb, 0);
            }
            ENDCG
        }
    }
}
