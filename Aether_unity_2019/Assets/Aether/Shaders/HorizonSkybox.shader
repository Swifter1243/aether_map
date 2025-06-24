Shader "Swifter/HorizonSkybox"
{
    Properties
    {
        _RainbowScale ("Rainbow Scale", Float) = 3
        _RainbowOffset ("Rainbow Offset", Float) = 0.3
        _TimeScale ("Time Scale", Float) = 0.2
        _VoronoiScale ("Voronoi Scale", Float) = 3
        _VoronoiAmount ("Voronoi Amount", Float) = 0.9
        _Saturation ("_Saturation", Float) = 0.7
        _XFalloff ("_XFalloff", Float) = 10
        _YFalloff ("_YFalloff", Float) = 15
        _CenterHighlightPower ("_CenterHighlightPower", Float) = 4
        _Brightness ("Brightness", Float) = 1

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }

        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            Pass [_StencilPass]
        }
        Cull Front

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex;
                return o;
            }

            float _RainbowScale;
            float _RainbowOffset;
            float _TimeScale;
            float _VoronoiScale;
            float _VoronoiAmount;
            float _Saturation;
            float _XFalloff;
            float _YFalloff;
            float _CenterHighlightPower;
            float _Brightness;

            fixed4 frag (v2f i) : SV_Target
            {
                float t = abs(i.localPos.y);
                t += voronoi(abs(i.localPos.xyz) * _VoronoiScale - _Time.y * _TimeScale) * _VoronoiAmount;

                float3 col = rainbow(t * _RainbowScale + _RainbowOffset);
                col = lerp(1, col, _Saturation);

                col *= pow(1 - abs(i.localPos.x), _XFalloff);
                col *= pow(1 - abs(i.localPos.y), _YFalloff);

                col += pow(col, _CenterHighlightPower);

                col *= _Brightness;

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
