Shader "Swifter/CrackedRainbowSky"
{
    Properties
    {
        _Rotation ("Rotation", Float) = 0
        _Twist ("Twist", Float) = 0
        _WorldOffset ("World Offset", Vector) = (0,0,0)
        _NoiseScale ("Noise Scale", Float) = 4
        _BorderWidth ("Border Width", Float) = 0
        _BorderFalloff ("Border Falloff", Float) = 1

        [Header(Layer 1)][Space(10)]
        _Layer1HueScale ("Hue Scale", Float) = 1
        _Layer1NoiseHueAmt ("Noise Hue Amount", Float) = 0.3
        _Layer1Saturation ("Saturation", Float) = 0.5
        _Layer1GlowThresh ("Glow Threshold", Range(0,1)) = 0.5
        _Layer1Alpha ("Layer 1 Alpha", Float) = 0.3

        [Header(Layer 2)][Space(10)]
        _HorizonCol ("Horizon Color", Color) = (1,1,1)
        _SkyCol ("Sky Color", Color) = (1,1,1)
        _HueSaturation ("Hue Saturation", Float) = 0.7
        _Voronoi1Scale ("Voronoi 1 Scale", Float) = 20
        _Voronoi2Scale ("Voronoi 2 Scale", Float) = 3
        _Simplex1Scale ("Simplex 1 Scale", Float) = 3
        _FBM ("Fractional Brownian Motion", Float) = 0.3
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

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            #include "RainbowSkybox.hlsl"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            float _Rotation;
            float _Twist;
            float3 _WorldOffset;
            float _NoiseScale;
            float _Layer1HueScale;
            float _Layer1NoiseHueAmt;
            float _Layer1Saturation;
            float _BorderWidth;
            float _BorderFalloff;
            float _Layer1GlowThresh;
            float _Layer1Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            // yoink https://www.ronja-tutorials.com/post/024-white-noise/
            float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
                //make value smaller to avoid artefacts
                float3 smallValue = sin(value);
                //get scalar value from 3d vector
                float random = dot(smallValue, dotDir);
                //make value more random by making it bigger and then taking the factional part
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            float rand1dTo1d(float3 value, float mutator = 0.546){
                float random = frac(sin(value + mutator) * 143758.5453);
                return random;
            }

            //to 3d functions

            float3 rand3dTo3d(float3 value){
                return float3(
                rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
                rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
                rand3dTo1d(value, float3(73.156, 52.235, 09.151))
                );
            }

            float3 rand1dTo3d(float value){
                return float3(
                rand1dTo1d(value, 3.9812),
                rand1dTo1d(value, 7.1536),
                rand1dTo1d(value, 5.7241)
                );
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
                            float3 cellPosition = cell + rand3dTo3d(cell);
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
                            float3 cellPosition = cell + rand3dTo3d(cell);
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

                float random = rand3dTo1d(f2 ? secondClosestCell : closestCell);
                return float3(minDistToCell, random, minEdgeDistance);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // World position stuff
                float3 worldPos = i.worldPos;
                worldPos += _WorldOffset;
                float XYlen = length(worldPos.xy);

                // Voronoi noise
                XYlen *= _NoiseScale;
                float3 noisePos = worldPos / XYlen;
                noisePos.xy = rotate2D(noisePos.z * _Twist + _Rotation, noisePos.xy);
                float3 noise = voronoiNoise(noisePos, true);

                // Crack
                float border = noise.z;
                border *= exp(abs(noisePos.y) * _BorderFalloff);
                float crack = step(border, _BorderWidth);

                // Layer 1
                float3 layer1Rainbow = rainbow(noisePos.z * _Layer1HueScale + noise.y * _Layer1NoiseHueAmt);
                layer1Rainbow = lerp(layer1Rainbow, 1, _Layer1Saturation);
                bool layer1Mix = noise.y < _Layer1GlowThresh;
                float layer1Alpha = layer1Mix * _Layer1Alpha;
                float4 layer1Col = float4(lerp(layer1Rainbow, 1, layer1Mix), layer1Alpha);

                // Layer 2
                float4 layer2Col = doSkybox(normalize(noisePos));

                // Final
                float4 col = lerp(layer1Col, layer2Col, crack);
                return col;
            }
            ENDCG
        }
    }
}
