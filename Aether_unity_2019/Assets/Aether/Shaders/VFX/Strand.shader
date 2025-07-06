Shader "Swifter/VFX/Strand"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TimeStep ("Time Step", Float) = 0.09
        _Color ("Color", Color) = (1,1,1)
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
            //#include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
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
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _TimeStep;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float timeStepped = round(_Time.y / _TimeStep) * _TimeStep;
                float nTime = (timeStepped * 9.2873) % 20;

                float2 texCoord = i.uv;
                texCoord.y += nTime;
                texCoord.x = (texCoord.x * 2 - 1) * 0.8 + 0.5;
                texCoord.x = saturate(texCoord.x);

                float cutout = tex2D(_MainTex, texCoord).r;
                clip(0.5 - cutout);

                return _Color;
            }
            ENDCG
        }
    }
}
