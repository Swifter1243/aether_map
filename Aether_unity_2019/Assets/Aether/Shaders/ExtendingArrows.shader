Shader "Swifter/ExtendingArrows"
{
    Properties
    {
        _TipBase ("Tip Base", Float) = 28.2
        _StretchLength ("Stretch Length", Float) = 1
        _StretchVariation ("Stretch Variation", Float) = 0
        _TwistSpeed ("Twist Speed", Float) = 3
        _TwistRadius ("Twist Radius", Float) = 1
        _TwistAmount ("Twist Amount", Float) = 1

        _WavePosition ("Wave Position", Float) = 0
        _WaveSpread ("Wave Spread", Float) = 2
        _WaveAmplitude ("Wave Amplitude", Float) = 3

        _Opacity ("Opacity", Float) = 1
        _TipBrightness ("Tip Brightness", Float) = 0

        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 0
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
        Blend [_BlendSrc] [_BlendDst]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float pathPosition : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _StretchLength;
            float _StretchVariation;
            float _TipBase;
            float _TwistAmount;
            float _TwistSpeed;
            float _TwistRadius;
            float _WavePosition;
            float _WaveSpread;
            float _WaveAmplitude;
            float _Opacity;
            float _TipBrightness;

            float3 path(in float t, in float2 phases, in float radius, in float amount, in float speed)
            {
                float3 circleOffset = float3(
                    sin(t * phases.x * amount + _Time.y * speed + phases.x * UNITY_TWO_PI),
                    0,
                    cos(t * phases.y * amount + _Time.y * speed + phases.y * UNITY_TWO_PI));

                return float3(0, t * 6, 0) + circleOffset * radius;
            }

            inline float projectOnPlane( float3 vec, float3 normal )
            {
                return dot( vec, normal );
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                float3 center = v.texcoord0.xyz;
                float size = v.texcoord0.w;
                float2 random = v.texcoord1.xy;

                float3 localY = normalize(float3(v.texcoord1.zw, v.texcoord2.x));
                float3 localZ = float3(0, 0, 1);
                float3 localX = normalize(cross(localY, localZ));
                localZ = normalize(cross(localY, localX));

                float4 localPos = v.vertex;
                localPos.xyz = (localPos.xyz - center) / size / _TipBase;

                float3 p = float3(
                    projectOnPlane(localPos.xyz, localX),
                    projectOnPlane(localPos.xyz, localY),
                    projectOnPlane(localPos.xyz, localZ)
                );

                float t = min(1, p.y);
                if (p.y < 1)
                {
                    p.y = 0;
                }
                else
                {
                    p.y -= 1;
                }
                o.pathPosition = t;

                float length = _StretchLength + (random - 0.5) * _StretchVariation;
                t *= length;

                float waveDist = abs(t - _WavePosition);
                float wave = smoothstep(_WaveSpread, 0, waveDist);
                float radius = _TwistRadius * t + wave * _WaveAmplitude * pow(t, 0.3);

                float3 pathNow = path(t, random, radius, _TwistAmount, _TwistSpeed);
                float3 pathAhead = path(t + 0.01, random, radius, _TwistAmount, _TwistSpeed);
                float3 normal = normalize(pathAhead - pathNow);

                float3 forward = float3(0, 0, 1);
                float3 right = normalize(cross(normal, forward));
                forward = normalize(cross(right, normal));

                float3x3 m = transpose(float3x3(right, normal, forward));
                p.xyz = mul(m, p.xyz) + pathNow;

                localPos.xyz = p.x * localX + p.y * localY + p.z * localZ;
                localPos.xyz = localPos.xyz * size * _TipBase + center;

                o.vertex = UnityObjectToClipPos(localPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float fade = smoothstep(0.1, 1, i.pathPosition);
                fade = lerp(1 - fade, pow(fade, 5), _TipBrightness);

                return fade * _Opacity;
            }
            ENDCG
        }
    }
}
