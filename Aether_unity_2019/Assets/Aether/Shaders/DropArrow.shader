Shader "Swifter/DropArrow"
{
    Properties
    {
        _Offset ("Offset", Vector) = (0,0,0)
        _FogHeight ("Fog Height", Float) = 3
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend One OneMinusSrcColor

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
                float fog : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _Offset;
            float _FogHeight;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                float3 localPos = v.vertex + _Offset;

                o.vertex = UnityObjectToClipPos(localPos);
                o.fog = localPos.z / _FogHeight;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.fog;
            }
            ENDCG
        }
    }
}
