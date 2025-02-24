Shader "Custom/SimpleTerrainFog"
{
    Properties
    {
        _SunColor ("Sun Color", Color) = (1,1,1)
        _SunStrength ("Sun Strength", Float) = 1
        _AmbientStrength ("Ambient Strength", Float) = 1
        _FogColor ("Fog Color", Color) = (1,1,1)
        _FogFar ("Fog Far", Float) = 400
        _FogZStart ("Fog Z Start", Float) = 0
        _FogZEnd ("Fog Z End", Float) = 30
    }
    SubShader
    {
        Tags
        {
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
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float distanceFog : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _SunColor;
            float _SunStrength;
            float _AmbientStrength;
            float3 _FogColor;
            float _FogFar;
            float _FogZStart;
            float _FogZEnd;

            v2f vert(appdata v)
            {

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
                float3 viewDir = normalize(viewVector);

                float camDistance = length(viewVector);
                float distanceFog = smoothstep(0, _FogFar, camDistance);
                distanceFog = pow(distanceFog, 3);
                distanceFog = saturate(distanceFog - worldPos.y / 200);

                o.distanceFog = distanceFog;
                o.viewDir = viewDir;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = worldPos;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float heightFog = smoothstep(_FogZEnd, _FogZStart, i.worldPos.y);
                heightFog = pow(heightFog, 10);
                float fog = 1 - ((1 - heightFog) * (1 - i.distanceFog));

                float3 col = 0;

                float sun = dot(i.worldNormal, float3(0,1,0));
                sun = max(sun, 0);

                col += sun * _SunColor * _SunStrength;
                col += _SunColor * _AmbientStrength;

                col = lerp(col, _FogColor, fog);

                return float4(col, 0);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
