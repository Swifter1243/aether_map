Shader "Swifter/SimpleSkybox"
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
        [Toggle(SKYBOX_CLOUD_FOG)] _SkyboxCloudFog ("Cloud Fog", Int) = 0
        _SkyboxCloudFogDistance ("Cloud Fog Distance", Float) = 100

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2

        [Toggle(SHADING)] _ShadingEnabled ("Shading Enabled", Int) = 0
        _ShadingAmount ("Shading Amount", Float) = 0.2
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
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
            #pragma multi_compile_instancing
            #pragma shader_feature SKYBOX_HORIZON
            #pragma shader_feature SKYBOX_CLOUDS
            #pragma shader_feature SKYBOX_CLOUD_FOG
            #pragma shader_feature SHADING

            #include "UnityCG.cginc"
            #include "IntroSkybox.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                #if SHADING
                float3 normal : NORMAL;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 viewDir : TEXCOORD0;
                #if SHADING
                float3 normal : TEXCOORD1;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _SkyboxCloudFogDistance;
            float _ShadingAmount;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
                float4 viewDir;
                viewDir.xyz = normalize(viewVector);

                #if SKYBOX_CLOUD_FOG
                viewDir.w = length(viewVector);
                #else
                viewDir.w = 1;
                #endif

                o.viewDir = viewDir;

                #if SHADING
                o.normal = v.normal;
                #endif

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                #if SKYBOX_CLOUD_FOG
                _CloudAmount *= i.viewDir.w / _SkyboxCloudFogDistance;
                #endif

                float4 color = doSkybox(i.viewDir);

                #if SHADING
                float shading = dot(i.normal, float3(0, 1, 0)) * 0.5 + 0.5;
                color.rgb *= lerp(1, shading, _ShadingAmount);
                #endif

                return color;
            }
            ENDCG
        }
    }
}
