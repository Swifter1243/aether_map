Shader "Custom/IntroSkybox"
{
    Properties
    {
        _HorizonCol ("Horizon Color", Color) = (1,1,1)
        _SkyCol ("Sky Color", Color) = (1,1,1)
        _HueSaturation ("Hue Saturation", Float) = 0.7
        _Voronoi1Scale ("Voronoi 1 Scale", Float) = 20
        _Voronoi2Scale ("Voronoi 2 Scale", Float) = 3
        _Simplex1Scale ("Simplex 1 Scale", Float) = 3
        _FBM ("Fractional Brownian Motion", Float) = 0.3
        _TimeScale ("Time Scale", Float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Geometry-900"
        }
        ZWrite Off
        ZTest Off
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

            struct appdata {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 _HorizonCol;
            float3 _SkyCol;
            float _HueSaturation;
            float _Voronoi1Scale;
            float _Voronoi2Scale;
            float _Simplex1Scale;
            float _FBM;
            float _TimeScale;

            v2f vert(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float t = _Time.y * _TimeScale * 0.2;

                float v = voronoi(i.localPos * _Voronoi1Scale + t).x;

                float3 v2Offset = float3(cos(v), 0, sin(v));
                float v2 = voronoi(i.localPos * _Voronoi2Scale + v2Offset * _FBM + t * 0.1) * 0.3;

                float3 huePos = i.localPos + v2;
                float hue = simplex(huePos * _Simplex1Scale) * 3;

                float3 hueCol = rainbow(hue + t);

                float3 desaturatedHue = lerp(hueCol, Luminance(hueCol) * _SkyCol, _HueSaturation);

                //return float4(hueCol, 0);

                float horizonAmount = pow(1 - max(0, i.localPos.y), 20);

                float hueAmount = (1 - horizonAmount);
                hueAmount *= pow(simplex(i.localPos * 5), 3);

                float3 col = lerp(_HorizonCol, desaturatedHue, hueAmount);

                return float4(col, 0);
            }
            ENDCG
        }
    }
}
