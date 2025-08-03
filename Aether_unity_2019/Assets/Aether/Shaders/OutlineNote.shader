Shader "Swifter/OutlineNote"
{
    Properties
    {
        _CoreColor ("Core Color", Color) = (0,0,0)
        _Color ("Border Color", Color) = (1,1,1)
        _BorderWidth ("Border Width", Float) = 0.1

        [Header(Note)][Space(10)]
        _Cutout ("Cutout", Range(0,1)) = 0
        [Toggle(DEBRIS)] _Debris ("Debris", Int) = 0
        _CutPlane ("Cut Plane", Vector) = (0, 0, 1, 0)
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
            #pragma shader_feature DEBRIS

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                #if DEBRIS
                float3 localPos : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID // Insert for GPU instancing
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _CoreColor;

            // Register GPU instanced properties (apply per-note)
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o); // Insert for GPU instancing
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                #if DEBRIS
                o.localPos = v.vertex.xyz;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);

                #if DEBRIS
                float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
                float3 samplePoint = i.localPos + CutPlane.xyz * CutPlane.w;
                float planeDistance = dot(samplePoint, CutPlane.xyz) / length(CutPlane.xyz);
                float c = planeDistance - Cutout * 0.25;
                clip(c);
                #else
                clip(1 - Cutout - 0.01);
                #endif

                return float4(_CoreColor, 0);
            }
            ENDCG
        }
        Pass
        {
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature DEBRIS

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                #if DEBRIS
                float3 localPos : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID // Insert for GPU instancing
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _BorderWidth;

            // Register GPU instanced properties (apply per-note)
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o); // Insert for GPU instancing
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);

                float borderWidth = _BorderWidth;
                borderWidth *= 1 - Cutout;
                v.vertex.xyz *= 1 + borderWidth;

                o.vertex = UnityObjectToClipPos(v.vertex);
                #if DEBRIS
                o.localPos = v.vertex.xyz;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                #if DEBRIS
                float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
                float3 samplePoint = i.localPos + CutPlane.xyz * CutPlane.w;
                float planeDistance = dot(samplePoint, CutPlane.xyz) / length(CutPlane.xyz);
                float c = planeDistance - Cutout * 0.25;
                clip(c);
                #else
                clip(1 - Cutout - 0.01);
                #endif

                return float4(Color, 0);
            }
            ENDCG
        }
    }
}
