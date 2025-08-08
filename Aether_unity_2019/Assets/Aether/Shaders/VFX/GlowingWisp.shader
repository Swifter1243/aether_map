Shader "Swifter/VFX/GlowingWisp"
{
    Properties
    {
        _TextureScale ("Texture Scale", Vector) = (5,5,0,0)
        _ScrollSpeed ("Scroll Speed", Float) = 0.1
        _Color ("Color", Color) = (1,1,1)
        [Toggle(RAINBOW)] _Rainbow ("Use Rainbow", Int) = 0
        _MixRainbow ("Mix Rainbow", Float) = 0.8
        _RainbowScale ("Rainbow Scale", Float) = 4
        _RainbowSpeed ("Rainbow Speed", Float) = 0.25
        _Brightness ("Brightness", Float) = 2
        _Contrast ("Contrast", Float) = 2.2
        _TimeScale ("Time Scale", float) = 1
        _Flutter ("Flutter", float) = 0
        _FocalAmount ("Focal Amount", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("BlendOp", Int) = 0

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 0
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        LOD 100

        Blend One One
        BlendOp [_BlendOp]
        ZWrite Off
        ZTest [_ZTest]

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
            #pragma shader_feature RAINBOW
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup

            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            #include "../Flutter.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float2 _TextureScale;
            float _ScrollSpeed;
            float3 _Color;
            float _Brightness;
            float _TimeScale;
            float _Flutter;
            float _FocalAmount;
            float _MixRainbow;
            float _RainbowScale;
            float _RainbowSpeed;
            float _Contrast;

            fixed4 frag (v2f i) : SV_Target
            {
                //Scaled pixel coordinates
                float2 p = i.uv * _TextureScale;
                p.y += _Time.y * _TimeScale * _ScrollSpeed;

                //8 wave passes
                for(float j=0.0; j<8.0;j++)
                {
                    //Add a simple sine wave with an offset and animation
                    p.x += sin(p.y+j+_Time.y*.10*_TimeScale);
                    //Rotate and scale down

                    p = mul(p, float2x2(6,-8,8,6)/8.);
                }
                //Pick a color using the turbulent coordinates
                float n = sin((p.x - p.y) * 0.2) * 0.3 + 0.5;
                float v = pow(n, 2);
                v *= _Brightness;

                // Vignette
                float vignette = smoothstep(1, 0, length(i.uv * 2 - 1));
                v *= pow(vignette, _FocalAmount);

                // Flutter
                v *= flutter(_Flutter);

                v = pow(v, _Contrast);

                v = max(v, 0);

                #if RAINBOW
                float3 col = rainbow(n * _RainbowScale + _Time.y * _TimeScale * _RainbowScale * _RainbowSpeed + n * _RainbowScale * 0.5);
                col = lerp(_Color, col, _MixRainbow);
                #else
                float3 col = _Color;
                #endif

                return float4(v * col, 0);
            }
            ENDCG
        }
    }
}
