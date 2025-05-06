Shader "Swifter/VFX/GlowingWisp"
{
    Properties
    {
        _TextureScale ("Texture Scale", Vector) = (5,5,0,0)
        _Color ("Color", Color) = (1,1,1)
        [Toggle(RAINBOW)] _Rainbow ("Use Rainbow", Int) = 0
        _MixRainbow ("Mix Rainbow", Float) = 0.8
        _Brightness ("Brightness", Float) = 2
        _Contrast ("Contrast", Float) = 2.2
        _TimeScale ("Time Scale", float) = 1
        _Flutter ("Flutter", float) = 0
        _FocalAmount ("Focal Amount", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 0
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        LOD 100

        Blend One One
        ZWrite Off
        ZTest [_ZTest]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature RAINBOW

            #include "UnityCG.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"

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
            float3 _Color;
            float _Brightness;
            float _TimeScale;
            float _Flutter;
            float _FocalAmount;
            float _MixRainbow;
            float _Contrast;

            fixed4 frag (v2f i) : SV_Target
            {
                //Scaled pixel coordinates
                float2 p = i.uv * _TextureScale;
                p.y += _Time.y * _TimeScale * 0.1;

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
                v *= saturate(lerp(1, noise1d(_Time.y * 20), _Flutter));

                #if RAINBOW
                float3 col = rainbow(n * 4 + _Time.y * _TimeScale + n * 2);
                col = lerp(_Color, col, _MixRainbow);
                #else
                float3 col = _Color;
                #endif

                col = pow(col, _Contrast);

                return float4(v * col, 0);
            }
            ENDCG
        }
    }
}
