Shader "Swifter/DeathRay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BorderNoiseTimeStep ("Border Noise Time Step", Float) = 0.09
        _BorderNoiseAmount ("Border Noise Amount", Float) = 0.3
        _BorderNoiseScale ("Border Noise Scale", Float) = 10
        _BorderCutoff ("Border Cutoff", Float) = 0.2
        _Posterization ("Posterization", Int) = 2
        _Brightness ("Brightness", Float) = 1
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
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
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

            float _BorderNoiseTimeStep;
            float _BorderNoiseAmount;
            float _BorderNoiseScale;
            float _BorderCutoff;
            float _Posterization;
            float _Brightness;

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

            inline float edgeSmooth(float x, float b)
            {
                return pow(abs(2*x - 1), b);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float timeStepped = round(_Time.y / _BorderNoiseTimeStep) * _BorderNoiseTimeStep;
                float nTime = (timeStepped * 9.2873) % 20;
                
                float2 texCoord = i.uv;
                texCoord.y += nTime;
                texCoord.x = (texCoord.x * 2 - 1) * 0.8 + 0.5;
                texCoord.x = saturate(texCoord.x);
                
                fixed4 col = tex2D(_MainTex, texCoord).r;

                col -= (1 - tex2D(_MainTex, texCoord + float2(0, 0.2)).r) * 0.8;
                
                float n = simplex(float3(i.uv * _BorderNoiseScale, nTime));
                n += simplex(float3(i.uv * _BorderNoiseScale * 2, nTime)) * 0.5;
                
                float fresnel = 1 - edgeSmooth(i.uv.x + (n - 0.75) * _BorderNoiseAmount, 3);
                fresnel -= _BorderCutoff;
                fresnel = round(fresnel * _Posterization * _Brightness) / _Posterization;

                col *= fresnel;

                return col;
            }
            ENDCG
        }
    }
}
