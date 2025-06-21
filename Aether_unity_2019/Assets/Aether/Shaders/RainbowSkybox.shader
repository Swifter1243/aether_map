Shader "Swifter/IntroSkybox"
{
    Properties
    {
        _HorizonCol ("Horizon Color", Color) = (1,1,1)
        _SkyCol ("Sky Color", Color) = (1,1,1)
        _HueSaturation ("Hue Saturation", Float) = 0.7
        _Voronoi1Scale ("Voronoi 1 Scale", Float) = 20
        _Voronoi2Scale ("Voronoi 2 Scale", Float) = 3
        _Simplex1Scale ("Simplex 1 Scale", Float) = 3
        _FBM ("Fractional Brownian Motion", Float) = 0.3
        _TimeScale ("Time Scale", Float) = 1
        [Toggle(SKYBOX_HORIZON)] _SkyboxHorizon ("Horizon", Int) = 1
        [Toggle(SKYBOX_CLOUDS)] _SkyboxClouds ("Clouds", Int) = 1
        _CloudPow ("Cloud Pow", Float) = 3.5
        _CloudAmount ("Cloud Amount", Float) = 1

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Background"
            "Queue"="Background"
        }

        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            Pass [_StencilPass]
        }

        Pass
        {
            ZWrite Off
            Cull Off
            Fog
            {
                Mode Off
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature SKYBOX_HORIZON
            #pragma shader_feature SKYBOX_CLOUDS

            #include "UnityCG.cginc"
            #include "RainbowSkybox.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return doSkybox(i.localPos);
            }
            ENDCG
        }
    }
}
