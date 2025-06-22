Shader "Swifter/VFX/ShockwaveParticle"
{
    Properties
    {
        _Distortion ("Distortion (In Meters)", Float) = 1
        _RingSharpness ("Ring Sharpness", Float) = 4
    }
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
        }
        GrabPass { "_GrabTexture1" }
        ZWrite Off

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
                float4 color : COLOR;
                float4 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 center : TEXCOORD1;
                float2 uv : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GrabTexture1);
            float _Distortion;
            float _RingSharpness;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 center = v.texcoord0.xyz;
                float2 uv = float2(v.texcoord0.w, v.texcoord1.x);

                o.worldPos = v.vertex;
                o.center = center;
                o.uv = uv;
                return o;
            }

            float2 worldToScreen(float3 pos) {
                float4 v = ComputeGrabScreenPos(UnityWorldToClipPos(pos));
                return v.xy / v.w;
            }

            float4 sampleScreen(float2 screenUV)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture1, screenUV);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float2 centerUV = i.uv * 2 - 1;
                float circleDist = 1 - abs(0.5 - min(1, length(centerUV))) * 2;
                float ring = smoothstep(0, 1, pow(circleDist, _RingSharpness));

                float distortion = _Distortion;
                float3 samplePos = (i.worldPos - i.center) * (1 + ring * distortion) + i.center;
                float2 screenUV = worldToScreen(samplePos);

                return sampleScreen(screenUV);
            }
            ENDCG
        }
    }
}
