Shader "Swifter/OpalTerrain"
{
    Properties
    {
        _Depth ("Depth", Float) = 1
        _NoiseScale ("Noise Scale", Float) = 1
        _SurfaceScale ("Surface Scale", Float) = 3
        _DetailScale ("Detail Scale", Float) = 1
        _AngleRainbowInfluence ("Angle Rainbow Influence", Float) = 5
        _NoiseRainbowInfluence ("Noise Rainbow Influence", Float) = 2
        _SurfaceDistortion ("Surface Distortion", Float) = 0.1
        _FBM ("FBM", Float) = 3
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
                float3 lineDir : TEXCOORD0;
                float3 linePoint : TEXCOORD1;
                float3 planeNormal : TEXCOORD2;
                float3 planePoint : TEXCOORD3;
                float3 localPos : TEXCOORD4;
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

            float3 intersectLineWithPlane(in float3 planePoint, in float3 planeNormal, in float3 linePoint, in float3 lineDir)
            {
                float denom = dot(planeNormal, lineDir);
                float t = dot(planeNormal, planePoint - linePoint) / denom;
                return linePoint + t * lineDir;
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                float3 planePoint = -v.normal * _Depth;
                float3 localCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 viewVector = v.vertex - localCameraPos;
                float3 viewDir = normalize(viewVector);

                o.planeNormal = v.normal;
                o.planePoint = planePoint;
                o.lineDir = viewDir;
                o.linePoint = localCameraPos;
                o.localPos = v.vertex;

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 intersectionPoint = intersectLineWithPlane(i.planePoint, i.planeNormal, i.linePoint, i.lineDir);

                float3 surfaceN = voronoi(i.localPos * _NoiseScale * _SurfaceScale);
                float3 n1 = voronoi(intersectionPoint * _NoiseScale * _DetailScale + surfaceN.z * _SurfaceDistortion);
                float3 n2 = voronoi(intersectionPoint * _NoiseScale + n1.x * _FBM + surfaceN.z * _SurfaceDistortion);

                float d = dot(i.planeNormal, i.lineDir) * _AngleRainbowInfluence;
                d += n2.x * _NoiseRainbowInfluence;

                float3 hue = rainbow(d);
                float saturation = pow(surfaceN.y, 2) * n2.x;

                float3 col = lerp(1, hue, saturation);

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
