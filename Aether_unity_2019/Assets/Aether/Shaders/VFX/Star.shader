Shader "Swifter/VFX/Star"
{
    Properties
    {
        _Bend ("Bend", Float) = 0.5
        _Size ("Size", Float) = 1.35
        _Spread ("Spread", Float) = 0.2
        _Alpha ("Alpha", Float) = 0.5
        _Thickness ("Thickness", Float) = 0.07
        _Flutter ("Flutter", Float) = 0
        _Softness ("Softness", Float) = 7
        _Opacity ("Opacity", Float) = 1
        [Toggle(CLAMP)] _Clamp ("Clamp", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4

        [Header(Blend)][Space(10)]
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("BlendOp", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 1

        [Header(Debris)][Space(10)]
        [Toggle(DEBRIS)] _IsDebris ("Is Debris", Int) = 0
        _CutPlane ("Cut Plane", Vector) = (0, 0, 1, 0)

        [Header(Graphic)][Space(10)]
        [Toggle(GRAPHIC)] _GraphicEnabled ("Enable Graphic", Int) = 0
        _GraphicNoise1Scale ("Noise 1 Scale", Float) = 8
        _GraphicNoise2Scale ("Noise 2 Scale", Float) = 15
        _GraphicNoise2Influence ("Noise 2 Influence", Float) = 0.4
        _GraphicNoiseInfluence ("Overall Noise Influence", Float) = 0.3
        _GraphicCutoff ("Cutoff", Float) = 0.6
        _GraphicSharpness ("Sharpness", Float) = 2

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Blend [_BlendSrc] [_BlendDst]
        BlendOp [_BlendOp]
        ZWrite Off
        ZTest [_ZTest]
        Cull Off

        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            Pass [_StencilPass]
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature CLAMP
            #pragma shader_feature GRAPHIC
            #pragma shader_feature DEBRIS

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "../Flutter.hlsl"
            #include "../Graphic.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                #if DEBRIS
                float4 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                #else
                float2 uv : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Bend;
            float _Size;
            float _Spread;
            float _Alpha;
            float _Thickness;
            float _Flutter;
            float _Opacity;
            float _Softness;

            #if DEBRIS
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
            UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            inline float projectOnPlane( float3 vec, float3 normal )
            {
                return dot( vec, normal );
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float4 localPos = v.vertex;

                #if DEBRIS
                o.uv = v.texcoord0.xy;
                float3 center = float3(v.texcoord0.zw, v.texcoord1.x);
                float3 normal = v.normal;
                float3 tangent = v.tangent;

                float3 localZ = -normal;
                float3 localX = tangent;
                float3 localY = cross(localZ, localX);

                localPos.xyz -= center;

                float3 p = float3(
                    projectOnPlane(localPos.xyz, localX),
                    projectOnPlane(localPos.xyz, localY),
                    projectOnPlane(localPos.xyz, localZ)
                );

                float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
                float3 cutForward = CutPlane.xyz;
                float3 cutOffset = CutPlane.xyz * CutPlane.w;

                float3 forward = normalize(cutForward);
                float3 up = float3(0,1,0);
                float3 right = normalize(cross(up, forward));
                up = normalize(cross(forward, right));
                float3x3 m = matrixFromBasis(right, up, forward);
                p = mul(m, p) + cutOffset;

                localPos.xyz = p.x * localX + p.y * localY + p.z * localZ;
                localPos.xyz += center;
                #else
                o.uv = v.uv;
                #endif

                o.vertex = UnityObjectToClipPos(localPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float2 p = abs(i.uv * 2 - 1);
                float edgeDist = smoothstep(1, 0.5, p.x*p.x + p.y*p.y);
                p *= _Size;

                float s = pow(p.x, _Bend) + pow(p.y, _Bend);
                float d = abs(s - 1) - _Thickness;

                float value = smoothstep(_Spread, 0, d);
                value *= edgeDist;

                value = pow(value * 2, _Softness);

                value *= flutter(_Flutter);

                #if GRAPHIC
                doGraphic(value, p);
                #endif

                #if CLAMP
                value = saturate(value);
                #else
                value = max(0, value);
                #endif

                value *= _Opacity;

                return float4(value, value, value, value * _Alpha);
            }
            ENDCG
        }
    }
}
