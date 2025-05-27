Shader "Swifter/VFX/TriangleArtifact"
{
    Properties
    {
        _Zoom ("Zoom", Float) = 6
        _RainbowScale ("Rainbow Scale", Float) = 10
        _Saturation ("Saturation", Range(0,1)) = 0.5
        _FadeOutRadius ("Fade Out Radius", Float) = 0.6
        _FadeOutSize ("Fade Out Size", Float) = 0.1
        _TimeScale ("Time Scale", Float) = 0.1
        _Brightness ("Brightness", Float) = 1
        _Highlights ("Highlights", Float) = 20
        _Falloff ("Falloff", Float) = 9
        _Flutter ("Flutter", Float) = 0

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend One One
        ZWrite Off

        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            Pass [_StencilPass]
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "../Flutter.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Zoom;
            float _RainbowScale;
            float _Saturation;
            float _FadeOutRadius;
            float _FadeOutSize;
            float _TimeScale;
            float _Brightness;
            float _Highlights;
            float _Falloff;
            float _Flutter;

            v2f vert(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // https://www.shadertoy.com/view/ss3fWr
            // cellX, cellY, edgeDist
            float3 triangleGrid(float2 uv, float zoom)
            {
                uv = mul(float2x2(1.0, 0.0, 0.5, 0.866) * zoom, uv);

                float2 index = floor(uv);
                uv = frac(uv);
                index = index * 2.0 - step(uv.x, uv.y);

                if(uv.x < uv.y) uv = uv.yx;
                float value = 3. * min(min(uv.x - uv.y, 1.0 - uv.x), uv.y);

                return float3(index, value);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 p = abs(i.uv * 2 - 1);

                float3 grid = triangleGrid(p, _Zoom);

                float n = simplex(grid.xy);
                float a = n * UNITY_TWO_PI - _Time.y * 0.1 * _TimeScale;
                float2 gradDir = float2(cos(a), sin(a));

                float gradPhase = p.x * gradDir.x + p.y * gradDir.y;

                float rainbowPhase = gradPhase * _RainbowScale * _Zoom + sin(_Time.y * _TimeScale) * 0.2 + _Time.y * 0.7 * _TimeScale + n * 20;

                float3 col = rainbow(rainbowPhase) + 0.2;

                col = lerp(Luminance(col), col, _Saturation);
                col *= 1 + max(0, pow(sin(rainbowPhase * 5), 3)) * _Highlights;
                col *= 1 + pow(n, 7) * 20;

                float pixelCenterDist = max(0, 1 - length(p));
                col *= smoothstep(_FadeOutRadius + _FadeOutSize, _FadeOutRadius, pixelCenterDist);

                col *= _Brightness;
                col *= pow(pixelCenterDist + n * 0.2, _Falloff);

                col *= flutter(_Flutter);

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
