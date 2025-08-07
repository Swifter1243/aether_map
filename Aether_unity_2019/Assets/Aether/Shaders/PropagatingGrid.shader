Shader "Swifter/PropagatingGrid"
{
    Properties
    {
        _BorderWidth ("Border Width", Range(0,0.5)) = 0.1
        _Scale ("Scale", Float) = 2
        _ScrollSpeed ("Scroll Speed", Float) = 0.1
        _Alpha ("Alpha", Float) = 0.5
        _Opacity ("Opacity", Range(0,1)) = 1

        [Header(Shockwave)][Space(10)]
        _ShockwaveBlend ("Shockwave Blend", Range(0,1)) = 0
        _ShockwaveDistance ("Shockwave Distance", Float) = 20
        _ShockwaveFalloff ("Shockwave Falloff", Float) = 3

        [Header(Blend)][Space(10)]
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("BlendOp", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        ZWrite Off
        BlendOp [_BlendOp]
        Blend [_BlendSrc] [_BlendDst]

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
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _BorderWidth;
            float _Scale;
            float _ScrollSpeed;
            float _Alpha;
            float _Opacity;

            float _ShockwaveBlend;
            float _ShockwaveDistance;
            float _ShockwaveFalloff;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 pos2D = i.worldPos.xz;
                float2 scrolledPos2D = pos2D;
                scrolledPos2D.y += _Time.y * _ScrollSpeed;
                float2 grid2D = frac(scrolledPos2D * _Scale);

                int borderX = grid2D.x < _BorderWidth | 1 - grid2D.x < _BorderWidth;
                int borderY = grid2D.y < _BorderWidth | 1 - grid2D.y < _BorderWidth;
                float v = borderX | borderY;

                float shockwaveDist = max(0, length(pos2D) - _ShockwaveDistance);
                float shockwaveInfluence = smoothstep(_ShockwaveFalloff, 0, shockwaveDist);
                v *= lerp(1, shockwaveInfluence, _ShockwaveBlend);

                v *= _Opacity;

                return float4(v, v, v, v * _Alpha);
            }
            ENDCG
        }
    }
}
