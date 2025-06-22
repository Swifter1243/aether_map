Shader "Swifter/CrackedRainbowSky"
{
    Properties
    {
        _Rotation ("Rotation", Float) = 0
        _Twist ("Twist", Float) = 0
        _WorldOffset ("World Offset", Vector) = (0,0,0)
        _Scale ("World Scale", Float) = 200
        _NoiseScale ("Noise Scale", Float) = 4
        _HueScale ("Hue Scale", Float) = 1
        _Border ("Border Width", Float) = 0
        _GlowThresh ("Glow Threshold", Range(0, 1)) = 0.1
        _AddAlpha ("Add Alpha", Range(0, 1)) = 0
    }
    SubShader
    {
        Cull Front

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
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

            uniform float3 _Position;

            float _Rotation;
            float _Twist;
            float3 _WorldOffset;
            float _Scale;
            float _NoiseScale;
            float _HueScale;
            float _Border;
            float _GlowThresh;
            float _AddAlpha;

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

            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1., 2./3., 1./3., 3.);
                float3 p = abs(frac(c.xxx+K.xyz)*6.-K.www);
                return c.z*lerp(K.xxx, clamp(p-K.xxx, 0., 1.), c.y);
            }

            float3 rgb2hsv(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float3 hsvNode(float3 col, float hue, float saturation, float value) {
                float3 hsv = rgb2hsv(col);
                hsv.x *= hue;
                hsv.y *= saturation;
                hsv.z *= value;
                return hsv2rgb(hsv);
            }

            float3 lerpHSV(float3 col1, float3 col2, float f) {
                col1 = rgb2hsv(col1);
                col2 = rgb2hsv(col2);
                return hsv2rgb(lerp(col1, col2, f));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // World position stuff
                float3 worldPos = i.worldPos;
                worldPos += _WorldOffset;
                worldPos *= _Scale;
                _Twist *= max(0, i.worldPos.z / 200);
                worldPos.xy = rotate2D(_Twist + _Rotation, worldPos.xy);

                // Rotation
                float XYlen = length(float3(worldPos.y, 14.7, worldPos.x));

                // Border
                _Border /= abs(worldPos.y);
                float3 worldHue = hsv2rgb(float3(abs(worldPos.y) / _Scale / 1000,1,1));

                // Voronoi noise
                XYlen *= _NoiseScale;
                float alpha = _AddAlpha;
                float3 noiseVal = worldPos / XYlen;
                float3 noise = voronoiNoise(noiseVal, true);
                float3 col = rand1dTo3d(noise.y);
                if (noise.y < _GlowThresh) {
                    col = 1;
                    alpha = 1;
                }

                // Apply border
                float valueChange = fwidth(noiseVal.z) * 0.5;
                float isBorder = 1 - smoothstep(_Border - valueChange, _Border + valueChange, noise.z);
                col = lerp(col, worldHue, isBorder);
                alpha += isBorder / 5;

                // Color correction
                float hue = worldPos.z / XYlen;
                hue *= _HueScale;
                col = hsvNode(col, hue, 0.7, 1);

                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
