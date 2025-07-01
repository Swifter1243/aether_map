Shader "Swifter/VFX/GraphicFire"
{
    Properties
    {
        _Noise1Scale ("Noise 1 Scale", Float) = 3
        _Noise2Scale ("Noise 2 Scale", Float) = 8
        _TimeScale ("Time Scale", Float) = 1.5
        _FBM ("Fractional Brownian Motion", Float) = 0.2
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
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

            float _Noise1Scale;
            float _Noise2Scale;
            float _TimeScale;
            float _FBM;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 fireUV = i.uv * _Noise1Scale;
                fireUV.y += _Time.y * _TimeScale * 2;
                
                float n = simplex(fireUV);

                fireUV = i.uv * _Noise2Scale;
                fireUV.y += _Time.y * _TimeScale;
                
                n -= voronoi(fireUV + n * _FBM) * 0.3;

                return 1 - step(i.uv.y, n);
            }
            ENDCG
        }
    }
}
