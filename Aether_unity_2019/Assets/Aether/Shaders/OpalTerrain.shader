Shader "Swifter/OpalTerrain"
{
    Properties
    {
        _Depth ("Depth", Float) = 7
        _NoiseScale ("Noise Scale", Float) = 0.5
        _SurfaceScale ("Surface Scale", Float) = 3
        _DetailScale ("Detail Scale", Float) = 1
        _AngleRainbowInfluence ("Angle Rainbow Influence", Float) = 5
        _NoiseRainbowInfluence ("Noise Rainbow Influence", Float) = 2
        _SurfaceDistortion ("Surface Distortion", Float) = 0.1
        _Darkness ("Darkness", Float) = 3
        _FBM ("FBM", Float) = 3
        _IQR ("Refractive Index", Float) = 1.45
        _Color ("Color", Color) = (1,1,1)
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

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD0;
                float3 localPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Depth;
            float _NoiseScale;
            float _SurfaceScale;
            float _DetailScale;
            float _AngleRainbowInfluence;
            float _NoiseRainbowInfluence;
            float _SurfaceDistortion;
            float _FBM;
            float _Darkness;
            float _IQR;
            float3 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                float3 localCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 viewVector = v.vertex - localCameraPos;
                float3 viewDir = normalize(viewVector);

                o.normal = v.normal;
                o.viewDir = viewDir;
                o.localPos = v.vertex;

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 refraction = refract(i.viewDir, i.normal, 1 / _IQR);
                float3 incoming = refraction;

                float incomingDepth = -dot(incoming, i.normal);
                float3 scaledIncoming = incoming * (_Depth / incomingDepth);
                float3 intersectionPoint = i.localPos + scaledIncoming;

                float3 surfaceN = voronoi(i.localPos * _NoiseScale * _SurfaceScale);
                float3 n1 = voronoi(intersectionPoint * _NoiseScale * _DetailScale + surfaceN.z * _SurfaceDistortion);
                float3 n2 = voronoi(intersectionPoint * _NoiseScale + n1.x * _FBM + surfaceN.z * _SurfaceDistortion);

                float d = dot(i.normal, i.viewDir) * _AngleRainbowInfluence;
                d += n2.x * _NoiseRainbowInfluence;

                float3 hue = rainbow(d);
                float saturation = pow(surfaceN.y, 2) * n2.x;

                float3 blackCol = hue * pow(saturation, 3);
                float3 whiteCol = lerp(_Color, hue, saturation);
                float3 col = lerp(blackCol, whiteCol, pow(n2.y, _Darkness));

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
