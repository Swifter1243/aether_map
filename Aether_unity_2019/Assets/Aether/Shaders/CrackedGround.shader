Shader "Swifter/CrackedGround"
{
    Properties
    {
        _CrackDistance ("Crack Distance", Float) = 1
        _CrackSharpness ("Crack Sharpness", Float) = 1
        _CrackAmplitude ("Crack Amplitude", Float) = 1
        _HeightOffset ("Height Offset", Float) = 0
        _FogDistance ("Fog Distance", Float) = 1
        _FogPower ("Fog Power", Float) = 1
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
                float depthFog : TEXCOORD0;
                float distanceFog : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _CrackDistance;
            float _CrackSharpness;
            float _CrackAmplitude;
            float _HeightOffset;
            float _FogDistance;
            float _FogPower;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float dist = length(v.vertex.xz);
                float t = min(1, dist / _CrackDistance);
                t = 1 - t;
                t = pow(t, _CrackSharpness);

                v.vertex.y -= _HeightOffset;

                v.vertex.y *= t * _CrackAmplitude;

                v.vertex.y += _HeightOffset;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depthFog = v.vertex.y;

                float distFog = min(1, dist / _FogDistance);
                distFog = pow(distFog, _FogPower);
                o.distanceFog = distFog;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float v = 1 - abs(i.depthFog /5);
                v *= lerp(1, min(1, i.depthFog), 0.9);

                v = lerp(v, 1, i.distanceFog);

                return v;
            }
            ENDCG
        }
    }
}
