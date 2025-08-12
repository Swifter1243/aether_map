Shader "Swifter/SimpleColor"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1)
        [Toggle(ALT_BASE_COLOR)] _UseAltBaseColor ("Use Alt Base Color", Int) = 0
        _AltBaseColor ("Alt Base Color", Color) = (1,1,1)
        _Glow ("Glow", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [KeywordEnum(Off, On)] _ZWrite ("ZWrite", Float) = 1

    	[Header(Blend)][Space(10)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Float) = 6
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        Cull [_Cull]
        ZWrite [_ZWrite]
        Blend [_SrcBlend] [_DstBlend]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup
            #pragma shader_feature ALT_BASE_COLOR

            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"

            struct appdata {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _Color;
            float3 _AltBaseColor;
            float _Glow;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag() : SV_Target
            {
                #if ALT_BASE_COLOR
                return float4(_AltBaseColor, _Glow);
                #else
                return float4(_Color, _Glow);
                #endif
            }
            ENDCG
        }
    }
}
