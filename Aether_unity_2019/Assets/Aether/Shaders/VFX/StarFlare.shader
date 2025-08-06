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
        [Toggle(CENTER_OCCLUSION)] _CenterOcclusionEnabled ("Center Depth Occlusion", Int) = 0

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
            #pragma shader_feature CENTER_OCCLUSION

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "../Flutter.hlsl"
            #include "../Graphic.cginc"

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
                #if CENTER_OCCLUSION
                float4 middleUV : TEXCOORD1;
                float cameraDist : TEXCOORD2;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #if CENTER_OCCLUSION
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraDepthTexture);
            #endif

            float _Sharpness;
            float _Brightness;
            float3 _Color;
            float _Alpha;
            float _Flutter;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                #if CENTER_OCCLUSION
                float4 midClipPos = UnityObjectToClipPos(float4(0,0,0,1));
                o.middleUV = ComputeScreenPos(midClipPos);
                o.cameraDist = midClipPos.w;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                #if CENTER_OCCLUSION
                float2 middleUV = i.middleUV.xy / i.middleUV.w;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, middleUV);
                float eyeDepth = LinearEyeDepth(depth);
                clip(eyeDepth - i.cameraDist);
                #endif

                float2 p = abs(i.uv * 2 - 1);

                float l = length(p);
                float d = saturate(1 - l);
                float r = pow(1. - p.x * p.y, _Sharpness);
                float v = r * d * d * _Brightness;

                v *= flutter(_Flutter);

                #if GRAPHIC
                doGraphic(v, p);
                #endif

                return float4(v * _Color,v * _Alpha);
            }
            ENDCG
        }
    }
}
