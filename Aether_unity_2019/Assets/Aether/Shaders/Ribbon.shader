Shader "Swifter/Ribbon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Clip ("Clip", Range(0,1)) = 0

        [Header(Fog)][Space(10)]
        [Toggle(FOG_ENABLED)] _FogEnabled ("Enabled", Int) = 0
        _FogColor ("Fog Color", Color) = (1,1,1)
        _FogFar ("Fog Far", Float) = 400
        _FogZStart ("Fog Z Start", Float) = 0
        _FogZEnd ("Fog Z End", Float) = 30
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
            #pragma shader_feature FOG_ENABLED

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
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
                #if FOG_ENABLED
                float3 pos : TEXCOORD2;
                float distanceFog : TEXCOORD3;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Clip;

            float3 _FogColor;
            float _FogFar;
            float _FogZStart;
            float _FogZEnd;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                v.vertex.xyz += simplex(v.vertex.xyz * 0.003 + _Time.y * 0.1) * 4;
                v.vertex.xyz += simplex(v.vertex.xyz * 0.1 + _Time.y * 0.3) * 2;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;

                #if FOG_ENABLED
                o.pos = v.vertex.xyz;

                float3 viewVector = v.vertex.xyz - _WorldSpaceCameraPos;

                float camDistance = length(viewVector);
                float distanceFog = smoothstep(0, _FogFar, camDistance);
                distanceFog = pow(distanceFog, 3);

                o.distanceFog = distanceFog;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float tex = tex2D(_MainTex, i.uv.yx).r;

                clip(1 - tex - _Clip);

                float3 col = i.color;

                #if FOG_ENABLED
                float heightFog = smoothstep(_FogZEnd, _FogZStart, i.pos.y);
                heightFog = pow(heightFog, 10);
                float fog = 1 - ((1 - heightFog) * (1 - i.distanceFog));
                col = lerp(col, _FogColor, fog);
                #endif

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
