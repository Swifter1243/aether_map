Shader "Swifter/Lattice"
{
    Properties
    {
        _ShockwaveSource ("Shockwave Source", Vector) = (0,0,0)
        _ShockwaveDistance ("Shockwave Distance", Float) = 10
        _ShockwaveWidth ("Shockwave Width", Float) = 4
        _ShockwaveBrightness ("Shockwave Brightness", Float) = 1
        _PerspectiveWarp ("Perspective Warp", Float) = 1
        _Border ("Border", Float) = 0.1

    	[Header(Sky)][Space(20)]
        _HorizonCol ("Horizon Color", Color) = (1,1,1)
        _SkyCol ("Sky Color", Color) = (1,1,1)
        _HueSaturation ("Hue Saturation", Float) = 0.7
        _Voronoi1Scale ("Voronoi 1 Scale", Float) = 20
        _Voronoi2Scale ("Voronoi 2 Scale", Float) = 3
        _Simplex1Scale ("Simplex 1 Scale", Float) = 3
        _FBM ("Fractional Brownian Motion", Float) = 0.3
        _TimeScale ("Time Scale", Float) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup

            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"

            // VivifyTemplate Libraries
            //#include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "IntroSkybox.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _ShockwaveSource;
            float _ShockwaveDistance;
            float _ShockwaveWidth;
            float _ShockwaveBrightness;
            float _PerspectiveWarp;
            float _Border;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex.w *= _PerspectiveWarp;

                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 viewVector = o.worldPos - _WorldSpaceCameraPos;
                o.viewDir = normalize(viewVector);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 toSource = _ShockwaveSource - i.worldPos;
                toSource = float3(toSource.x, toSource.y, 0);
                float sourceDist = length(toSource);
                float toWave = abs(sourceDist - _ShockwaveDistance);
                float waveAmount = max(0, 1 - (toWave / _ShockwaveWidth));

                float3 col = doSkybox(i.viewDir);
                col *= waveAmount * _ShockwaveBrightness;

                col *= max(0, dot(i.worldNormal, normalize(toSource)));

                float border = abs(min(min(min(i.uv.x, 1 - i.uv.x), i.uv.y), 1 - i.uv.y));
                col *= step(border, _Border);

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
