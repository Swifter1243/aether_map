Shader "Swifter/CustomNoteArrow"
{
    Properties
    {
        _CutoutEdgeWidth("Cutout Edge Width", Range(0,0.1)) = 0.02
        _Cutout ("Cutout", Range(0,1)) = 1
        _Color ("Color", Color) = (1,1,1)
        _Alpha ("Alpha", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_INSTANCING_BUFFER_END(Props)

            float _CutoutEdgeWidth;
            float _Alpha;

            v2f vert (appdata v)
            {
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float noise = simplex(i.localPos * 2);
                float c = noise - Cutout;
                clip(c);
                if (c < _CutoutEdgeWidth) {
                    return 1;
                }

                return float4(Color, _Alpha);
            }
            ENDCG
        }
    }
}
