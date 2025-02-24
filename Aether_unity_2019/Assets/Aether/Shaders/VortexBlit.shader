Shader "Swifter/VortexBlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Steps ("Steps", Int) = 16
        _StepSize ("Step Size", Float) = 60
        _StepNoise ("Step Noise", Float) = 1
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
        _LightRadius ("Light Radius", Float) = 1300
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
            float _StepNoise;
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
            float _LightRadius;

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

            float lightAmount(float3 toCenter)
            {
                float ballLight = invLerp(_LightRadius , 0, length(toCenter));
                ballLight = pow(max(0, ballLight), 5);
                return ballLight;
            }

            float sampleDensity(float3 p, float3 toCenter, float distToCenter)
            {
                float3 rotatedP = rotateY(toCenter, distToCenter * _VortexTwistRadialRate + _Time.y * _VortexTwistTimeRate + p.y * _VortexTwistYRate) + _VortexCenter;
                rotatedP.y *= 0.7;

                float3 n = simplex(rotatedP * _VortexNoiseScale);
                n += simplex(rotatedP * _VortexNoiseScale * 4 + n + _Time.y * _VortexTwistTimeRate) * 0.25;
                n += simplex(rotatedP * _VortexNoiseScale * 8 + n + _Time.y * _VortexTwistTimeRate) * 0.125;
                n = pow(n, 10);

                float radiusProgress = saturate(invLerp(_RadiusSizes[0], _RadiusSizes[2], p.y));
                float radius = lerp(_RadiusSizes[1], _RadiusSizes[3], radiusProgress);

                float d = invLerp(radius, 0, distToCenter);
                d = pow(d, 3);
                d = saturate(d);

                float3 beamMist = n * saturate(1 - distToCenter / _VortexBeamRadius) * _VortexBeamBrightness * _LightColor;
                float mainColorBrightness = d * n * _VortexMainBrightness;
                float density = mainColorBrightness + beamMist;

                float cutoffStart = smoothstep(_CutoffHeights[0], _CutoffHeights[1], p.y);
                float cutoffEnd = smoothstep(_CutoffHeights[3], _CutoffHeights[2], p.y);
                density *= cutoffStart * cutoffEnd;

                density += lightAmount(toCenter) * lerp(n, 1, 0.1);

                return density * 0.2;
            }

            float3 sampleColor(float3 toCenter, float distToCenter)
            {
                float3 col = 0;

                col = lerp(col, _LightColor, lightAmount(toCenter) * _LightBrightness);

                col = lerp(col, rainbow(distToCenter / 120) * 0.2, 0.2 * smoothstep(0, 500, distToCenter));

                return col;
            }

            float InterleavedGradientNoise(float2 p) {
                return frac(52.9829189 * frac(0.06711056*p.x + 0.00583715*p.y));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float toVolumeStart = _VolumeStartZ;

                float depth = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(i.uv)).r;
                float zDepth = LinearEyeDepth(depth);

                float2 screenCoord = i.uv * _ScreenParams.xy;
                float totalDist = toVolumeStart + InterleavedGradientNoise(screenCoord) * _StepSize * _StepNoise;
                float stepSize = _StepSize;

                float3 col = 0;
                float alpha = 1;

                float lastDensity = 0;

                [loop]
                for (int j = 0; j < _Steps && totalDist < zDepth; j++) {
                    float3 p = _WorldSpaceCameraPos + i.viewVector * totalDist;

                    float3 toCenter = p - _VortexCenter;
                    float distToCenter = length(toCenter.xz);

                    float3 fogColor = sampleColor(toCenter, distToCenter);
                    float fogDensity = sampleDensity(p, toCenter, distToCenter);

                    col += fogColor * (fogDensity * alpha);
                    alpha *= exp(-fogDensity);

                    float densityDelta = abs(fogDensity - lastDensity);
                    densityDelta /= stepSize;
                    lastDensity = fogDensity;
                    totalDist += stepSize;
                }

                float4 volumetricsCol = float4(col, alpha);
                return volumetricsCol;
            }
            ENDCG
        }
        Pass // Blur
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_VortexTexture1);
            float4 _VortexTexture1_TexelSize;

            v2f_img vert(appdata_img v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f_img, v2f_img o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            float4 getScreenCol(float2 uv, float2 offset)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_VortexTexture1, UnityStereoTransformScreenSpaceTex(uv) + offset);
            }

            float4 blur(float2 uv)
            {
                float4 total = 0;
                float2 offset = _VortexTexture1_TexelSize.xy;

                total += getScreenCol(uv, 0);
                total += getScreenCol(uv, float2(offset.x, offset.y));
                total += getScreenCol(uv, float2(offset.x, -offset.y));
                total += getScreenCol(uv, float2(-offset.x, -offset.y));
                total += getScreenCol(uv, float2(-offset.x, offset.y));

                return total / 5;
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                return blur(i.uv);
            }
            ENDCG
        }
        Pass // Composition
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_VortexTexture2);
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

                float2 normalizedUV = UnityStereoTransformScreenSpaceTex(i.uv);
                float4 vortexCol = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_VortexTexture2, normalizedUV);
                float4 screenCol = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, normalizedUV);

                return vortexCol + screenCol * 0.01;
            }
            ENDCG
        }
    }
}
