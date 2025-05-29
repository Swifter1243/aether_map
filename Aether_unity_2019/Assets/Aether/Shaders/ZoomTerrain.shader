Shader "Swifter/ZoomTerrain"
{
    Properties
    {
        _GlassRefraction ("Glass Refraction", Float) = 0.4

        [Toggle(DISTANCE_FOG)] _DistanceFogEnabled ("Distance Fog Enabled", Int) = 1
        _FadeDistanceStart ("Fade Distance Start", Float) = 500
        _FadeDistanceEnd ("Fade Distance End", Float) = 800

        [Toggle(HEIGHT_FOG)] _HeightFogEnabled ("Height Fog Enabled", Int) = 0
        _HeightFogStart ("Height Fog Start", Float) = 0
        _HeightFogEnd ("Height Fog End", Float) = 10

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2
    }
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
        }
        GrabPass { "_GrabTexture1" }

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
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup
            #pragma shader_feature DISTANCE_FOG
            #pragma shader_feature HEIGHT_FOG

            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"

            // VivifyTemplate Libraries
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenUV : TEXCOORD1;
                float4 normalScreenUV : TEXCOORD2;
                float3 worldPos : TEXCOORD4;
                #if DISTANCE_FOG
                float distanceFog : TEXCOORD3;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _GlassRefraction;
            float _FadeDistanceStart;
            float _FadeDistanceEnd;
            float _HeightFogStart;
            float _HeightFogEnd;
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GrabTexture1);

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenUV = ComputeScreenPos(o.vertex);

                float3 normalOffsetLocalPos = v.vertex + v.normal * _GlassRefraction;
                float4 normalOffsetClipPos = UnityObjectToClipPos(normalOffsetLocalPos);
                o.normalScreenUV = ComputeScreenPos(normalOffsetClipPos);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos;

                #if DISTANCE_FOG
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
                float viewDistance = length(viewVector);
                o.distanceFog = smoothstep(_FadeDistanceEnd, _FadeDistanceStart, viewDistance);
                #endif

                return o;
            }

            float4 sampleScreen(float2 screenUV)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture1, screenUV);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float2 screenUV = i.screenUV / i.screenUV.w;

                float4 normalScreenUV = i.normalScreenUV / i.normalScreenUV.w;

                float4 col = sampleScreen(normalScreenUV) * 0.8;

                float fog = 1;

                #if DISTANCE_FOG
                fog *= i.distanceFog;
                #endif

                #if HEIGHT_FOG
                float heightFog = smoothstep(_HeightFogStart, _HeightFogEnd, i.worldPos.y);
                heightFog = pow(heightFog, 10);
                fog *= heightFog;
                #endif

                col = lerp(sampleScreen(screenUV), col, fog);

                return col;
            }
            ENDCG
        }
    }
}
