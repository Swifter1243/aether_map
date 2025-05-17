Shader "Swifter/VFX/RingFlare"
{
    Properties
    {
        _Saturation ("Rainbow Amount", Range(0,1)) = 0.5
        _Color ("Color", Color) = (1,1,1)
        _Intensity ("Intensity", Float) = 3
        _Glow ("Glow", Float) = 32
        _TimeScale ("Time Scale", Float) = 1
        _NoiseScale ("Noise Scale", Float) = 30
        _Flutter ("Flutter", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend One One
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "../Flutter.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float _Saturation;
            float3 _Color;
            float _Intensity;
            float _Glow;
            float _TimeScale;
            float _NoiseScale;
            float _Flutter;

            float3 color(float t)
            {
                return palette(t, 0.5, 0.5, 1, float3(0.00, 0.10, 0.2));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 p = i.uv.xy * 2 - 1;
                float angle = atan2(p.y, p.x);
                angle = angle / UNITY_TWO_PI;

                float n = simplex(float2(_Time.y * _TimeScale, abs(angle) * _NoiseScale));
                float len = length(p);
                float d = max(0, abs(len - 0.5));

                float v = pow(1 - d, _Glow) * n * _Intensity;

                v *= flutter(_Flutter);

                float3 ringCol = lerp(_Color, rainbow(angle), _Saturation);

                return float4(ringCol * v, 0);
            }
            ENDCG
        }
    }
}
