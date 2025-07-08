Shader "Swifter/VFX/Strand"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TimeStep ("Time Step", Float) = 0.09
        _Color ("Color", Color) = (1,1,1)

        [Header(Blend)][Space(10)]
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("BlendOp", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 0

        [Toggle(IS_PARTICLE)] _IsParticle ("Is Particle", Int) = 0
        _TimeStepRandomness ("Timestep Randomness", Float) = 0.01
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
        BlendOp [_BlendOp]
        Blend [_BlendSrc] [_BlendDst]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature IS_PARTICLE

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            //#include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                #if IS_PARTICLE
                float random : TEXCOORD1;
                #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _TimeStep;
            float _TimeStepRandomness;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =TRANSFORM_TEX(v.texcoord0.xy, _MainTex);

                #if IS_PARTICLE
                o.random = v.texcoord0.z;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                #if IS_PARTICLE
                float timeStep = _TimeStep + i.random * _TimeStepRandomness;
                #else
                float timeStep = _TimeStep;
                #endif
                float timeStepped = round(_Time.y / timeStep) * timeStep;
                float nTime = (timeStepped * 9.2873) % 20;

                float2 texCoord = i.uv;
                texCoord.y += nTime;

                #if IS_PARTICLE
                texCoord.y += i.random;
                #endif

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
