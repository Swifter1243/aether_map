Shader "Swifter/VFX/GraphicFire"
{
    Properties
    {
        _Noise1Scale ("Noise 1 Scale", Float) = 3
        _Noise2Scale ("Noise 2 Scale", Float) = 8
        _TimeScale ("Time Scale", Float) = 1.5
        _FBM ("Fractional Brownian Motion", Float) = 0.2
        _Color ("Color", Color) = (0,0,0)
        [Toggle(IS_PARTICLE)] _IsParticle ("Is Particle", Int) = 0
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
            #pragma shader_feature IS_PARTICLE

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord0 : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                #if IS_PARTICLE
                float random : TEXCOORD1;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Noise1Scale;
            float _Noise2Scale;
            float _TimeScale;
            float _FBM;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord0.xy;

                #if IS_PARTICLE
                o.random = v.texcoord0.z;
                #endif
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 movingUV = i.uv;

                #if IS_PARTICLE
                movingUV.y += i.random;
                #endif
                
                float2 fireUV = movingUV * _Noise1Scale;
                fireUV.y += _Time.y * _TimeScale * 2;
                
                float n = simplex(fireUV);

                fireUV = movingUV * _Noise2Scale;
                fireUV.y += _Time.y * _TimeScale;
                
                n -= voronoi(fireUV + n * _FBM) * 0.3;

                if (step(i.uv.y, n))
                    discard;

                return _Color;
            }
            ENDCG
        }
    }
}
