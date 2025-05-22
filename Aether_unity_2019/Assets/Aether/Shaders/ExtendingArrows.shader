Shader "Swifter/ExtendingArrows"
{
    Properties
    {
        _TipBase ("Tip Base", Float) = 28.2
        _StretchLength ("Stretch Length", Float) = 1
        _TwistSpeed ("Twist Speed", Float) = 3
        _TwistRadius ("Twist Radius", Float) = 1
        _TwistAmount ("Twist Amount", Float) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }

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
                float2 texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float test : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _StretchStart;
            float _StretchEnd;
            float _StretchLength;
            float _TipBase;
            float _TwistAmount;
            float _TwistSpeed;
            float _TwistRadius;

            float3 path(float t, in float2 phases)
            {
                float3 circleOffset = float3(
                    sin(t * phases.x * _TwistAmount + _Time.y * _TwistSpeed),
                    0,
                    cos(t * phases.y * _TwistAmount + _Time.y * _TwistSpeed));

                return float3(0, t * 6, 0) + circleOffset * (t * _TwistRadius);
            }

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)
                /*localPos.y += smoothstep(_StretchStart, _StretchEnd * size, t) * _StretchLength;*/

                float3 center = v.texcoord0.xyz;
                float size = v.texcoord0.w;
                float2 random = v.texcoord1.xy;

                float4 localPos = v.vertex;
                localPos.xyz = (localPos.xyz - center) / size / _TipBase;

                float t = min(1, localPos.y);
                if (localPos.y < 1)
                {
                    localPos.y = 0;
                }
                else
                {
                    localPos.y -= 1;
                }
                o.test = t;

                t *= _StretchLength;

                float3 pathNow = path(t, random);
                float3 pathAhead = path(t + 0.01, random);
                float3 normal = normalize(pathAhead - pathNow);

                float3 forward = float3(0, 0, 1);
                float3 right = normalize(cross(normal, forward));
                forward = normalize(cross(right, normal));

                float3x3 m = transpose(float3x3(right, normal, forward));
                localPos.xyz = mul(m, localPos.xyz) + pathNow;

                localPos.xyz = localPos.xyz * size * _TipBase + center;

                o.vertex = UnityObjectToClipPos(localPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.test;
            }
            ENDCG
        }
    }
}
