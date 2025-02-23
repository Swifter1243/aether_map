Shader "Swifter/VortexBlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Steps ("Steps", Int) = 16
        _StepSize ("Step Size", Float) = 60
        _VolumeStartZ ("Volume Start Z", Float) = 400
        _VortexCenter ("Vortex Center", Vector) = (0, 0, 1000)
        _VortexNoiseScale ("Vortex Noise Scale", Float) = 0.002
        _RadiusSizes ("Radius Sizes", Vector) = (1000, 600, 800, 300)
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD0;
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Steps;
            float _StepSize;
            float _VolumeStartZ;
            float3 _VortexCenter;
            float _VortexNoiseScale;
            float4 _RadiusSizes;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // Calculate View Direction
                o.viewVector = viewVectorFromUV(v.uv); // from Math.cginc

                // Save Vertex
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;

                return o;
            }

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);

            float2 rotate2D(float2 p, float a)
            {
                float s = sin(a);
                float c = cos(a);
                return float2(
                    p.x * c - p.y * s,
                    p.x * s + p.y * c
                );
            }

            float3 rotateY(float3 p, float a)
            {
                float2 rotatedP = rotate2D(p.xz, a);
                return float3(rotatedP.x, p.y, rotatedP.y);
            }

            float invLerp(float a, float b, float x)
            {
                return (x - a) / (b - a);
            }

            float3 sampleDensity(float3 p)
            {
                if (abs(p.y + 900) > 20) {
                    //return 0;
                }

                float3 toCenter = p - _VortexCenter;
                float distToCenter = length(toCenter.xz);

                //float angle = pow(distToCenter, 0.4);

                float3 rotatedP = rotateY(toCenter, distToCenter * 0.002 + _Time.y * 0.2 + p.y * 0.001) + _VortexCenter;
                rotatedP.y *= 0.7;

                float3 n = simplex(rotatedP * _VortexNoiseScale);
                n += simplex(rotatedP * _VortexNoiseScale * 2 + n) * 0.5;
                n += simplex(rotatedP * _VortexNoiseScale * 4 + n * 2) * 0.25;
                n = pow(n, 4);

                float radius = lerp(900, 300, invLerp(100, -1900, p.y));

                float d = invLerp(radius, 0, distToCenter);
                d = pow(d, 3);
                d = saturate(d);
                d *= 0.01;

                float3 col = d * n * 3 + n * saturate(1 - distToCenter / 600) * 0.002;

                float cutoff = saturate(1 - p.y * 0.001);

                col *= cutoff;
                col *= smoothstep(-2000, 0, p.y);

                col *= min(1, pow(distToCenter * 0.003, 4));

                float ballLight = invLerp(800 + n * 100, 0, length(toCenter));
                ballLight = pow(max(0, ballLight), 7);
                col += ballLight * n * 0.6 * float3(0.5, 0.8, 1);

                return col;
            }

            float4 getScreenColor(float2 uv) {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, uv);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float zProjLength = 1 / i.viewVector.z;
                float toVolumeStart = _VolumeStartZ - _WorldSpaceCameraPos.z;

                float3 p = _WorldSpaceCameraPos + i.viewVector * (zProjLength * toVolumeStart);

                float3 col = 0;

                [loop]
                for (int j = 0; j < _Steps; j++) {
                    p += i.viewVector * (_StepSize * zProjLength);

                    col += sampleDensity(p);
                }

                float4 finalCol = float4(col, 0);
                float4 screenCol = getScreenColor(i.uv);

                return finalCol;
            }
            ENDCG
        }
    }
}
