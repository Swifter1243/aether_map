Shader "Swifter/CrackedRainbowSky"
{
    Properties
    {
        _Rotation ("Rotation", Float) = 0
        _Twist ("Twist", Float) = 0
        _WorldOffset ("World Offset", Vector) = (0,0,0)
        _WorldScale ("World Scale", Vector) = (900,900,900)
        _NoiseScale ("Noise Scale", Float) = 4
        _NoiseOffset ("Noise Offset", Vector) = (0,0,0)
        _BorderWidth ("Border Width", Float) = 0
        _BorderFalloff ("Border Falloff", Float) = 1

        [Header(Layer 1)][Space(10)]
        _Layer1HueScale ("Hue Scale", Float) = 1
        _Layer1NoiseHueAmt ("Noise Hue Amount", Float) = 0.3
        _Layer1Saturation ("Saturation", Float) = 0.5
        _Layer1GlowThresh ("Glow Threshold", Range(0,1)) = 0.5
        _Layer1Alpha ("Layer 1 Alpha", Float) = 0.3
        _Layer1BaseBrightness ("Base Brightness", Float) = 1

        [Header(Wave)][Space(10)]
        [Toggle(WAVE)] _WaveEnabled ("Wave Enabled", Int) = 0
        _WaveZ ("Wave Z", Float) = 20
        _WaveFalloff ("Wave Falloff", Float) = 0.4

        [Header(Layer 2)][Space(10)]
        _HorizonCol ("Horizon Color", Color) = (1,1,1)
        _SkyCol ("Sky Color", Color) = (1,1,1)
        _HueSaturation ("Hue Saturation", Float) = 0.7
        _Voronoi1Scale ("Voronoi 1 Scale", Float) = 20
        _Voronoi2Scale ("Voronoi 2 Scale", Float) = 3
        _Simplex1Scale ("Simplex 1 Scale", Float) = 3
        _FBM ("fracional Brownian Motion", Float) = 0.3
        _TimeScale ("Time Scale", Float) = 1
        [Toggle(SKYBOX_HORIZON)] _SkyboxHorizon ("Horizon", Int) = 1
        [Toggle(SKYBOX_CLOUDS)] _SkyboxClouds ("Clouds", Int) = 1
        _CloudPow ("Cloud Pow", Float) = 3.5
        _CloudAmount ("Cloud Amount", Float) = 1
        [Toggle(SKYBOX_CLOUD_FOG)] _SkyboxCloudFog ("Cloud Fog", Int) = 0
        _SkyboxCloudFogDistance ("Cloud Fog Distance", Float) = 100
    }
    SubShader
    {
        Cull Front

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature SKYBOX_HORIZON
            #pragma shader_feature SKYBOX_CLOUDS
            #pragma shader_feature SKYBOX_CLOUD_FOG
            #pragma shader_feature WAVE

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            #include "RainbowSkybox.hlsl"
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

            float _Rotation;
            float _Twist;
            float3 _WorldOffset;
            float3 _WorldScale;
            float _NoiseScale;
            float3 _NoiseOffset;
            float _Layer1HueScale;
            float _Layer1NoiseHueAmt;
            float _Layer1Saturation;
            float _BorderWidth;
            float _BorderFalloff;
            float _Layer1GlowThresh;
            float _Layer1Alpha;
            float _Layer1BaseBrightness;
            float _WaveZ;
            float _WaveFalloff;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.localPos = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            // modified from https://www.shadertoy.com/view/4djSRW
            float hash31(float3 p3)
            {
	            p3  = frac(p3 * .1031);
                p3 += dot(p3, p3.zyx + 31.32);
                return frac((p3.x + p3.y) * p3.z);
            }

            float3 hash33(float3 p3)
            {
	            p3 = frac(p3 * float3(.1031, .1030, .0973));
                p3 += dot(p3, p3.yxz+33.33);
                return frac((p3.xxy + p3.yxx)*p3.zyx);
            }

            // modified from https://www.ronja-tutorials.com/post/028-voronoi-noise/
            float3 voronoiNoise(float3 value, bool f2){
                float3 baseCell = floor(value);

                //first pass to find the closest cell
                float minDistToCell = 10;
                float3 toClosestCell;
                float3 closestCell;
                float3 secondClosestCell;
                [unroll]
                for(int x1=-1; x1<=1; x1++){
                    [unroll]
                    for(int y1=-1; y1<=1; y1++){
                        [unroll]
                        for(int z1=-1; z1<=1; z1++){
                            float3 cell = baseCell + float3(x1, y1, z1);
                            float3 cellPosition = cell + hash33(cell);
                            float3 toCell = cellPosition - value;
                            float distToCell = length(toCell);
                            if (distToCell < minDistToCell){
                                minDistToCell = distToCell;
                                secondClosestCell = closestCell;
                                closestCell = cell;
                                toClosestCell = toCell;
                            }
                        }
                    }
                }

                //second pass to find the distance to the closest edge
                float minEdgeDistance = 10;
                [unroll]
                for(int x2=-1; x2<=1; x2++){
                    [unroll]
                    for(int y2=-1; y2<=1; y2++){
                        [unroll]
                        for(int z2=-1; z2<=1; z2++){
                            float3 cell = baseCell + float3(x2, y2, z2);
                            float3 cellPosition = cell + hash33(cell);
                            float3 toCell = cellPosition - value;

                            float3 diffToClosestCell = abs(closestCell - cell);
                            bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y + diffToClosestCell.z < 0.1;
                            if(!isClosestCell){
                                float3 toCenter = (toClosestCell + toCell) * 0.5;
                                float3 cellDifference = normalize(toCell - toClosestCell);
                                float edgeDistance = dot(toCenter, cellDifference);
                                minEdgeDistance = min(minEdgeDistance, edgeDistance);
                            }
                        }
                    }
                }

                float random = hash31(f2 ? secondClosestCell : closestCell);
                return float3(minDistToCell, random, minEdgeDistance);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // World position stuff
                float3 worldPos = i.localPos * _WorldScale;
                worldPos += _WorldOffset;
                float XYlen = length(worldPos.xy);

                // Voronoi noise
                XYlen *= _NoiseScale;
                float3 projectedPos = worldPos / XYlen;
                projectedPos.xy = rotate2D(projectedPos.z * _Twist + _Rotation, projectedPos.xy);
                float3 noise = voronoiNoise(projectedPos + _NoiseOffset, true);

                // Crack
                float border = noise.z;
                float falloffVal = exp(abs(projectedPos.y) * _BorderFalloff);
                border *= falloffVal;
                border = lerp(border, _BorderWidth + 1, min(1, falloffVal / 200));
                float crack = step(border, _BorderWidth);

                // Layer 1
                float3 layer1Rainbow = rainbow(projectedPos.z * _Layer1HueScale + noise.y * _Layer1NoiseHueAmt);
                layer1Rainbow = lerp(layer1Rainbow, 1, _Layer1Saturation);
                layer1Rainbow *= _Layer1BaseBrightness;
                float layer1Mix = noise.y < _Layer1GlowThresh;

                #if WAVE
                float wave = noise.z * exp(abs(projectedPos.z - _WaveZ) * _WaveFalloff);
                wave = step(wave, 0.3);
                layer1Mix = min(1, layer1Mix + wave);
                #endif

                float layer1Alpha = layer1Mix * _Layer1Alpha;
                float4 layer1Col = float4(lerp(layer1Rainbow, 1, layer1Mix), layer1Alpha);

                // Layer 2
                projectedPos.xy = rotate2D(projectedPos.z * _Twist + _Rotation, projectedPos.xy);
                float4 layer2Col = doSkybox(normalize(projectedPos));

                // Final
                float4 col = lerp(layer1Col, layer2Col, crack);
                return col;
            }
            ENDCG
        }
    }
}
