Shader "Swifter/SaberTrail"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ChannelDivergence ("Channel Divergence", Float) = 0.1
        _Color ("Saber Color", Color) = (1,1,1)
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent+1000"
        }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        ColorMask RGB

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

            float _ChannelDivergence;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                float3 texCol;
                texCol.r = tex2D(_MainTex, i.uv + float2(0, -_ChannelDivergence)).r;
                texCol.g = tex2D(_MainTex, i.uv).g;
                texCol.b = tex2D(_MainTex, i.uv + float2(0, _ChannelDivergence)).b;

                float4 col = texCol.rgbr;

                col.rgb *= Color;
                col.rgb = lerp(col.rgb, texCol, pow(1 - i.uv.y, 5));

                return col;
            }
            ENDCG
        }
    }
}
