Shader "Swifter/DropArrow"
{
    Properties
    {
        _Offset ("Offset", Vector) = (0,0,0)
        _FogHeight ("Fog Height", Float) = 3
        [Toggle(IS_PARTICLE)] _IsParticle ("Is Particle", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Float) = 6
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("BlendOp", Int) = 0
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend One [_DstBlend]
        BlendOp [_BlendOp]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature IS_PARTICLE

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                #if IS_PARTICLE
                float4 texcoord0 : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float fog : TEXCOORD0;
                float3 test : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _Offset;
            float _FogHeight;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                #if IS_PARTICLE
                float4 center = float4(v.texcoord0.xyz, 1);
                float4 localPos = v.vertex - center;
                localPos.xyz *= _Offset.z;

                o.vertex = UnityObjectToClipPos(localPos + center);
                float fogZ = length(localPos.xyz);
                #else
                float3 localPos = v.vertex + _Offset;

                o.vertex = UnityObjectToClipPos(localPos);
                float fogZ = localPos.z;
                #endif

                o.fog = fogZ / _FogHeight;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float v = saturate(i.fog);
                return float4(v, v, v, v);
            }
            ENDCG
        }
    }
}
