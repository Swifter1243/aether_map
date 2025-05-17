Shader "Swifter/VFX/Star"
{
    Properties
    {
        _Bend ("Bend", Float) = 0.5
        _Size ("Size", Float) = 1.35
        _Spread ("Spread", Float) = 0.2
        _Alpha ("Alpha", Float) = 0.5
        _Thickness ("Thickness", Float) = 0.07
        _Flutter ("Flutter", Float) = 0
        _Opacity ("Opacity", Float) = 1
        [Toggle(INVERT)] _Invert ("Invert", Int) = 0
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend One One
        ZWrite Off
        Cull Off

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

            #include "../Flutter.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Bend;
            float _Size;
            float _Spread;
            float _Alpha;
            float _Thickness;
            float _Flutter;
            float _Opacity;
            bool _Invert;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 p = abs(i.uv * 2 - 1);
                float edgeDist = smoothstep(1, 0.5, p.x*p.x + p.y*p.y);
                p *= _Size;

                float s = pow(p.x, _Bend) + pow(p.y, _Bend);
                float d = abs(s - 1) - _Thickness;

                float value = smoothstep(_Spread, 0, d);
                value *= edgeDist;

                value = pow(value * 2, 7);

                value *= flutter(_Flutter);

                float value2 = _Invert ? -value : value;
                return float4(value2, value2, value2, value * _Alpha);
            }
            ENDCG
        }
    }
}
