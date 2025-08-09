Shader "Swifter/Gemstone"
{
    Properties
    {
        _Depth ("Depth", Float) = 3
        _NoiseScale ("Noise Scale", Float) = 0.5
        _SurfaceScale ("Surface Scale", Float) = 3
        _DetailScale ("Detail Scale", Float) = 1
        _AngleRainbowInfluence ("Angle Rainbow Influence", Float) = 5
        _NoiseRainbowInfluence ("Noise Rainbow Influence", Float) = 2
        _SurfaceDistortion ("Surface Distortion", Float) = 0.1
        _Darkness ("Darkness", Float) = 1.5
        _FBM ("FBM", Float) = 2
        _IOR ("Refractive Index", Float) = 1.45
        _Color ("Color", Color) = (1,1,1)
        _Brightness ("Brightness", Float) = 1
        _LightingInfluence ("Lighting Influence", Range(0,1)) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2

        [Header(Fog)][Space(10)]
        _FogColor ("Fog Color", Color) = (1,1,1)

        [Toggle(DISTANCE_FOG)] _DistanceFogEnabled ("Distance Fog Enabled", Int) = 1
        _FadeDistanceStart ("Fade Distance Start", Float) = 500
        _FadeDistanceEnd ("Fade Distance End", Float) = 800

        [Toggle(HEIGHT_FOG)] _HeightFogEnabled ("Height Fog Enabled", Int) = 0
        _HeightFogStart ("Height Fog Start", Float) = 0
        _HeightFogEnd ("Height Fog End", Float) = 10

    	[Header(Blend)][Space(10)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Float) = 6

        [Header(Note)][Space(10)]
        [Toggle(NOTE)] _IsNote ("Is Note", Int) = 0
        _Cutout ("Cutout", Range(0,1)) = 0
        [Toggle(DEBRIS)] _Debris ("Debris", Int) = 0
        _CutPlane ("Cut Plane", Vector) = (0, 0, 1, 0)
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
        Blend [_SrcBlend] [_DstBlend]
        Cull [_Cull]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature DISTANCE_FOG
            #pragma shader_feature HEIGHT_FOG
            #pragma shader_feature NOTE
            #pragma shader_feature DEBRIS

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
                float3 localNormal : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                #if DISTANCE_FOG || HEIGHT_FOG
                float3 worldPos : TEXCOORD4;
                #endif
                #if DISTANCE_FOG
                float distanceFog : TEXCOORD5;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
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
            float _IOR;
            #if !NOTE
            float3 _Color;
            #endif
            float _Brightness;
            float _LightingInfluence;

            float3 _FogColor;
            float _FadeDistanceStart;
            float _FadeDistanceEnd;
            float _HeightFogStart;
            float _HeightFogEnd;

            #if NOTE
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
            UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 localCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 viewVector = v.vertex - localCameraPos;
                float3 viewDir = normalize(viewVector);

                o.localNormal = v.normal;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = viewDir;
                o.localPos = v.vertex;

                #if DISTANCE_FOG || HEIGHT_FOG
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                #endif

                #if HEIGHT_FOG
                o.worldPos = worldPos;
                #endif

                #if DISTANCE_FOG
                float3 worldViewVector = worldPos - _WorldSpaceCameraPos;
                float viewDistance = length(worldViewVector);
                o.distanceFog = smoothstep(_FadeDistanceEnd, _FadeDistanceStart, viewDistance);
                #endif

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                #if NOTE
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                #else
                float3 Color = _Color;
                #endif

                float3 refraction = refract(i.viewDir, i.localNormal, 1 / _IOR);
                float3 incoming = refraction;

                float incomingDepth = -dot(incoming, i.localNormal);
                float3 scaledIncoming = incoming * (_Depth / incomingDepth);
                float3 intersectionPoint = i.localPos + scaledIncoming;

                float3 surfaceN = voronoi(i.localPos * _NoiseScale * _SurfaceScale);
                float3 n1 = voronoi(intersectionPoint * _NoiseScale * 2 + surfaceN.z * _SurfaceDistortion);

                #if NOTE
                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float c = 0;

                #if DEBRIS
                    float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
                    float3 samplePoint = i.localPos + CutPlane.xyz * CutPlane.w;
                    float planeDistance = dot(samplePoint, CutPlane.xyz) / length(CutPlane.xyz);
                    c = planeDistance - Cutout * 0.4;
                #else
                    c = surfaceN - Cutout;
                #endif
                c += (voronoi(i.localPos * 8 + 8) - 0.3) * 0.1;

                clip(c);

                #endif

                float d = dot(i.localNormal, i.viewDir) * _AngleRainbowInfluence;
                d += n1.x * _NoiseRainbowInfluence;

                float3 hue = rainbow(d);
                float saturation = pow(surfaceN.y, 2) * n1.x;

                float3 blackCol = hue * pow(saturation, 3);
                float3 whiteCol = lerp(Color, hue, saturation);
                float3 col = lerp(blackCol, whiteCol, pow(n1.y, _Darkness));

                col *= _Brightness;

                float lighting = dot(i.worldNormal, float3(0.2, 1, 0)) * 0.5 + 0.5;
                col *= lerp(1, lighting, _LightingInfluence);

                #if DISTANCE_FOG || HEIGHT_FOG
                float fog = 1;

                #if DISTANCE_FOG
                fog *= i.distanceFog;
                #endif

                #if HEIGHT_FOG
                float heightFog = smoothstep(_HeightFogStart, _HeightFogEnd, i.worldPos.y);
                heightFog = pow(heightFog, 10);
                fog *= heightFog;
                #endif

                col = lerp(_FogColor, col, fog);
                #endif

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
