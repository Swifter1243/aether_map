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
        _VortexTwistYRate ("Vortex Twist Y Rate", Float) = 0.002
        _VortexTwistRadialRate ("Vortex Twist Radial Rate", Float) = 0.01
        _VortexTwistTimeRate ("Vortex Twist Time Rate", Float) = 0.04
        _VortexMainBrightness ("Vortex Main Brightness", Float) = 0.01
        _VortexBeamBrightness ("Vortex Beam Brightness", Float) = 0.01
        _VortexBeamRadius ("Vortex Beam Radius", Float) = 600
        _RadiusSizes ("Radius Sizes", Vector) = (1000, 600, 800, 300)
        _CutoffHeights ("Cutoff Heights", Vector) = (1200, 1000, 500, 0)
        _LightColor ("Light Color", Color) = (1,1,1)
        _LightBrightness ("Light Brightness", Float) = 0.7
        _BlurSteps ("Blur Steps", Int) = 10
        _BlurRadius ("Blur Radius", Range(0,0.01)) = 0.001
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass // Volumetrics
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"

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
            float _VortexTwistRadialRate;
            float _VortexTwistYRate;
            float _VortexTwistTimeRate;
            float _VortexMainBrightness;
            float _VortexBeamBrightness;
            float _VortexBeamRadius;
            float4 _RadiusSizes;
            float4 _CutoffHeights;
            float3 _LightColor;
            float _LightBrightness;

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraDepthTexture);

            v2f vert (appdata_base v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.viewVector = viewVectorFromUV(v.texcoord); // from Math.cginc
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                return o;
            }

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

                float3 rotatedP = rotateY(toCenter, distToCenter * _VortexTwistRadialRate + _Time.y * _VortexTwistTimeRate + p.y * _VortexTwistYRate) + _VortexCenter;
                rotatedP.y *= 0.7;

                float3 n = simplex(rotatedP * _VortexNoiseScale);
                n += simplex(rotatedP * _VortexNoiseScale * 4 + n) * 0.25;
                n = pow(n, 10);

                float radiusProgress = saturate(invLerp(_RadiusSizes[0], _RadiusSizes[2], p.y));
                float radius = lerp(_RadiusSizes[1], _RadiusSizes[3], radiusProgress);

                float d = invLerp(radius, 0, distToCenter);
                d = pow(d, 3);
                d = saturate(d);

                float3 beamMist = n * saturate(1 - distToCenter / _VortexBeamRadius) * _VortexBeamBrightness * _LightColor;

                float mainColorBrightness = d * n * _VortexMainBrightness;
                float3 mainColor = mainColorBrightness;
                mainColor = lerp(mainColor, mainColorBrightness * 1.3 * rainbow(distToCenter / 120), 0.4 * smoothstep(0, 600, distToCenter));

                float3 col = mainColor + beamMist;

                float cutoffStart = smoothstep(_CutoffHeights[0], _CutoffHeights[1], p.y);
                float cutoffEnd = smoothstep(_CutoffHeights[3], _CutoffHeights[2], p.y);
                col *= cutoffStart * cutoffEnd;

                float ballLight = invLerp(800 + n * 100, 0, length(toCenter));
                ballLight = pow(max(0, ballLight), 7);
                col += ballLight * n * _LightBrightness * _LightColor;

                return col;
            }

            float InterleavedGradientNoise(float2 p) {
                return frac(52.9829189 * frac(0.06711056*p.x + 0.00583715*p.y));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float zProjLength = 1 / i.viewVector.z;
                float toVolumeStart = _VolumeStartZ - _WorldSpaceCameraPos.z;

                float3 col = 0;

                float depth = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraDepthTexture, i.uv).r;
                float zDepth = LinearEyeDepth(depth);

                float totalDist = toVolumeStart + InterleavedGradientNoise(i.uv * 100) * _StepSize * 3;
                float stepSize = _StepSize;
                stepSize *= zProjLength;

                [loop]
                for (int j = 0; j < _Steps; j++) {
                    totalDist += stepSize;

                    if (totalDist > zDepth) {
                        break;
                    }

                    float3 p = _WorldSpaceCameraPos + i.viewVector * totalDist;

                    col += sampleDensity(p);
                }

                float4 volumetricsCol = float4(col, 0);
                return volumetricsCol;
            }
            ENDCG
        }
        Pass // Horizontal Blur
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_VortexTexture1);

            int _BlurSteps;
            float _BlurRadius;

            v2f_img vert(appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f_img, v2f_img o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            float4 getScreenCol(float2 uv)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_VortexTexture1, UnityStereoTransformScreenSpaceTex(uv));
            }

            float4 blur(float2 uv, float amount)
            {
                float4 total = 0;
                float aspect = _ScreenParams.y / _ScreenParams.x;

                for (int i = -_BlurSteps; i <= _BlurSteps; i++)
                {
                    float offset = (float)i / _BlurSteps;
                    total += getScreenCol(uv + float2(offset * amount * aspect, 0));
                }

                return total / (_BlurSteps * 2 + 1);
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                return blur(i.uv, _BlurRadius);
            }
            ENDCG
        }
        Pass // Vertical Blur
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_VortexTexture2);

            int _BlurSteps;
            float _BlurRadius;

            v2f_img vert(appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f_img, v2f_img o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            float4 getScreenCol(float2 uv)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_VortexTexture2, UnityStereoTransformScreenSpaceTex(uv));
            }

            float4 blur(float2 uv, float amount)
            {
                float4 total = 0;

                for (int i = -_BlurSteps; i <= _BlurSteps; i++)
                {
                    float offset = (float)i / _BlurSteps;
                    total += getScreenCol(uv + float2(0, offset * amount));
                }

                return total / (_BlurSteps * 2 + 1);
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                return blur(i.uv, _BlurRadius);
            }
            ENDCG
        }
        Pass // Composition
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_VortexTexture3);
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);

            v2f_img vert (appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f_img, v2f_img o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                return o;
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 vortexCol = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_VortexTexture3, i.uv);
                float4 screenCol = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.uv);

                return screenCol * 0 + vortexCol;
            }
            ENDCG
        }
    }
}
