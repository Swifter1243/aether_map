Shader "Swifter/OpalTerrain"
{
    Properties
    {
        _Depth ("Depth", Float) = 1
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
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
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
                float3 worldPos : TEXCOORD0;
                float3 worldCenter : TEXCOORD1;
                float3 planeNormal : TEXCOORD2;
                float3 planePoint : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Depth;

            float3 intersectLineWithPlane(in float3 planePoint, in float3 planeNormal, in float3 linePoint, in float3 lineDir)
            {
                float denom = dot(planeNormal, lineDir);
                float t = dot(planeNormal, planePoint - linePoint) / denom;
                return linePoint + t * lineDir;
            }

            #define WORLD_CENTER unity_ObjectToWorld._m03_m13_m23

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 planePoint = WORLD_CENTER - worldNormal * _Depth;

                o.worldPos = worldPos;
                o.worldCenter = WORLD_CENTER;
                o.planeNormal = worldNormal;
                o.planePoint = planePoint;

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewVector = i.worldPos - _WorldSpaceCameraPos;
                float3 viewDir = normalize(viewVector);

                float3 intersectionPoint = intersectLineWithPlane(i.planePoint, i.planeNormal, _WorldSpaceCameraPos, viewDir);

                intersectionPoint -= i.worldCenter;

                float n = voronoi(intersectionPoint * 2);

                return n;

                return float4(intersectionPoint, 0);
            }
            ENDCG
        }
    }
}
