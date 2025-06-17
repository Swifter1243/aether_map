Shader "Swifter/GraphicText"
{
    Properties
    {
        _MainTex ("Font Atlas", 2D) = "white" {}
        _Glow ("Glow", Range(0,1)) = 0
        _Opacity ("Opacity", Range(0,1)) = 1
        _Sharpness ("Sharpness", Float) = 0.05
        _DistortionStrength ("Distortion Strength", Float) = 0.002
        _DistortionScale ("Distortion Scale", Float) = 50
        _DistortionInterval ("Distortion Interval", Float) = 0.2
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend One One

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 atlas : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 atlas : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float _Opacity;
            float _Glow;
            float _Sharpness;
            float _DistortionStrength;
            float _DistortionScale;
            float _DistortionInterval;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.atlas = v.atlas;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float2 uv = i.atlas;
                float d = (floor(_Time.y / _DistortionInterval) * _DistortionInterval * 20) % 20;
                float n = simplex(uv * _DistortionScale + d).x;
                float a = UNITY_TWO_PI * n;
                uv += float2(cos(a), sin(a)) * _DistortionStrength;

                float sdf = tex2D(_MainTex, uv).a;

                float value = smoothstep(0.5 - _Sharpness, 0.5 + _Sharpness, sdf);
                value *= _Opacity;

                return float4(value, value, value, value * _Glow);
            }
            ENDCG
        }
    }
}
