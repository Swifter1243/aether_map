Shader "Swifter/GlassTerrain"
{
    Properties
    {
        _GlassRefraction ("Glass Refraction", Float) = 0.4
        _GlassAbsorption ("Glass Absorption", Float) = 0.8
        _SpecularAmount ("Specular Amount", Float) = 1
        _SpecularPower ("Specular Power", Float) = 16
        _DiffuseAmount ("Diffuse Amount", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2

        [Header(Colorizing)][Space(10)]
        [Toggle(COLORIZE)] _IsColorized ("Colorized", Int) = 0
        _Color ("Color", Color) = (1,1,1)
        _TintAmount ("Tint Amount", Range(0,1)) = 0.8
        [Toggle(FRESNEL)] _FresnelEnabled ("Fresnel Enabled", Int) = 0
        _FresnelAmount ("Fresnel Amount", Float) = 1
        _FresnelPower ("Fresnel Power", Float) = 4
        _FresnelGlow ("Fresnel Glow", Float) = 0.2

        [Header(Fog)][Space(10)]
        [Toggle(DISTANCE_FOG)] _DistanceFogEnabled ("Distance Fog Enabled", Int) = 1
        _FadeDistanceStart ("Fade Distance Start", Float) = 500
        _FadeDistanceEnd ("Fade Distance End", Float) = 800

        [Toggle(HEIGHT_FOG)] _HeightFogEnabled ("Height Fog Enabled", Int) = 0
        _HeightFogStart ("Height Fog Start", Float) = 0
        _HeightFogEnd ("Height Fog End", Float) = 10

        [Header(Light 1)][Space(10)]
        [Toggle(LIGHT_1_ENABLED)] _Light1Enabled ("Enabled", Int) = 0
        _Light1Color ("Color", Color) = (1,1,1)
        _Light1Strength ("Strength", Float) = 1
        _Light1Range ("Range", Float) = 1
        _Light1Falloff ("Falloff", Float) = 1
        _Light1Flutter ("Flutter", Float) = 0
        _Light1Position ("Position", Vector) = (0, 0, 0)

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2

        [Header(Note)][Space(10)]
        [Toggle(NOTE)] _IsNote ("Is Note", Int) = 0
        _Cutout ("Cutout", Range(0,1)) = 0
        [Toggle(DEBRIS)] _Debris ("Debris", Int) = 0
        _CutPlane ("Cut Plane", Vector) = (0, 0, 1, 0)
    }
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
        }
        GrabPass { "_GrabTexture1" }
        Cull [_Cull]

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
            #pragma instancing_options procedural:vertInstancingSetup
            #pragma shader_feature COLORIZE
            #pragma shader_feature FRESNEL
            #pragma shader_feature DISTANCE_FOG
            #pragma shader_feature HEIGHT_FOG
            #pragma shader_feature LIGHT_1_ENABLED
            #pragma shader_feature NOTE
            #pragma shader_feature DEBRIS

            #define LIGHT_ENABLED LIGHT_1_ENABLED

            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "Flutter.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenUV : TEXCOORD0;
                float4 normalClipPos : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                #if DISTANCE_FOG
                float distanceFog : TEXCOORD3;
                #endif
                #if LIGHT_ENABLED | FRESNEL
                float3 viewDir : TEXCOORD4;
                float3 worldNormal : TEXCOORD5;
                #endif
                #if NOTE
                float3 localPos : TEXCOORD6;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID // Insert for GPU instancing
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _GlassRefraction;
            float _GlassAbsorption;
            float _SpecularAmount;
            float _SpecularPower;
            float _DiffuseAmount;
            #if !NOTE
            float4 _Color;
            #endif
            float _TintAmount;

            float _FadeDistanceStart;
            float _FadeDistanceEnd;
            float _HeightFogStart;
            float _HeightFogEnd;
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GrabTexture1);

            float3 _Light1Color;
            float _Light1Strength;
            float3 _Light1Position;
            float _Light1Range;
            float _Light1Flutter;
            float _Light1Falloff;

            float _FresnelAmount;
            float _FresnelPower;
            float _FresnelGlow;

            // Register GPU instanced properties (apply per-note)
            #if NOTE
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
            UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenUV = ComputeScreenPos(o.vertex);

                float3 normalOffsetLocalPos = v.vertex + v.normal * _GlassRefraction;
                float4 normalOffsetClipPos = UnityObjectToClipPos(normalOffsetLocalPos);
                o.normalClipPos = normalOffsetClipPos;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos;

                #if DISTANCE_FOG | LIGHT_ENABLED | FRESNEL
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
                #endif

                #if DISTANCE_FOG
                float viewDistance = length(viewVector);
                o.distanceFog = smoothstep(_FadeDistanceEnd, _FadeDistanceStart, viewDistance);
                #endif

                #if LIGHT_ENABLED | FRESNEL
                float3 viewDir = normalize(viewVector);
                o.viewDir = viewDir;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                #endif

                #if NOTE
                o.localPos = v.vertex.xyz;
                #endif

                return o;
            }

            float4 sampleScreen(float2 screenUV)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture1, screenUV);
            }

            #if LIGHT_ENABLED
            float doSpecular(in v2f i, float3 normLightDir, in float3 lightStrength)
            {
                const float3 reflectionDir = reflect(normLightDir, i.worldNormal);
                const float specAngle = max(dot(reflectionDir, i.viewDir), 0.0);
                const float specular = pow(specAngle, _SpecularPower);
                return specular * _SpecularAmount * lightStrength;
            }

            float doDiffuse(in v2f i, in float3 normLightDir, in float lightStrength)
            {
                float alignment = max(dot(i.worldNormal, normLightDir), 0);
                return alignment * lightStrength * _DiffuseAmount;
            }

            float doPointLight(in v2f i, in float3 lightPos, in float3 lightRange, in float3 lightFalloff, in float3 lightStrength, in float flutterAmount)
            {
                float col = 0;

                const float3 toLight = lightPos - i.worldPos;
                const float3 normLightDir = normalize(toLight);

                // Fake lighting calculation with directional light and minimum darkness
                const float lightDistanceNormalized = 1 - saturate(length(toLight) / lightRange);
                const float lightAmount = pow(lightDistanceNormalized, lightFalloff);
                const float diffuse = doDiffuse(i, normLightDir, lightStrength * lightAmount);
                col += diffuse;

                // Add specular
                col += doSpecular(i, normLightDir, lightStrength * lightAmount);

                col *= flutter(flutterAmount);

                return col;
            }
            #endif

            inline float edgeSmooth(float x, float b)
            {
                return pow(abs(2*x - 1), b);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                UNITY_SETUP_INSTANCE_ID(i);

                #if NOTE
                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float4 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                #if DEBRIS
                float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
                float3 samplePoint = i.localPos + CutPlane.xyz * CutPlane.w;
                float planeDistance = dot(samplePoint, CutPlane.xyz) / length(CutPlane.xyz);
                const float CRACK_DISTORTION_DIST = 0.2;
                float crackDistortion = smoothstep(CRACK_DISTORTION_DIST, 0, planeDistance - Cutout * CRACK_DISTORTION_DIST);
                float crackNoise = (1 - voronoi(i.localPos * crackDistortion * 5).x);
                float c = planeDistance - Cutout * 0.3 + (crackNoise - 0.5) * 0.1;
                clip(c);
                #else
                float debrisNoise = 1 - voronoi(i.localPos * 2).x * 0.9;
                float c = 1 - Cutout - debrisNoise;
                clip(c);
                #endif
                #else
                float4 Color = _Color;
                #endif

                float2 screenUV = i.screenUV / i.screenUV.w;
                float4 screenCol = sampleScreen(screenUV);

                float4 normalClipPos = i.normalClipPos;
                normalClipPos.xy = clamp(normalClipPos.xy, -normalClipPos.w, normalClipPos.w);
                float4 normalScreenPos = ComputeNonStereoScreenPos(normalClipPos);
                float2 normalScreenUV = normalScreenPos.xy / normalScreenPos.w;

                #if DEBRIS
                normalScreenUV += crackDistortion * crackNoise * 0.5;
                #endif

                float4 col = sampleScreen(UnityStereoTransformScreenSpaceTex(normalScreenUV)) * _GlassAbsorption;

                const int SHARPNESS = 10;
                float border = (1 - edgeSmooth(1 - normalScreenUV.x, SHARPNESS)) * (1 - edgeSmooth(1 - normalScreenUV.y, SHARPNESS));
                border = saturate(border);

                col = lerp(screenCol, col, border);

                float fog = 1;

                #if DISTANCE_FOG
                fog *= i.distanceFog;
                #endif

                #if HEIGHT_FOG
                float heightFog = smoothstep(_HeightFogStart, _HeightFogEnd, i.worldPos.y);
                heightFog = pow(heightFog, 10);
                fog *= heightFog;
                #endif

                #if LIGHT_1_ENABLED
                col.rgb += doPointLight(i, _Light1Position, _Light1Range, _Light1Falloff, _Light1Strength, _Light1Flutter) * _Light1Color;
                #endif

                col = lerp(screenCol, col, fog);

                #if COLORIZE
                float4 tintedCol = col * Color;
                col = lerp(col, tintedCol, _TintAmount);
                #if FRESNEL
                float fresnel = abs(dot(i.viewDir, i.worldNormal));
                float fresnelAmt = pow(1 - fresnel, _FresnelPower);
                col += fresnelAmt * float4(Color.rgb, _FresnelGlow) * _FresnelAmount;
                #endif
                #endif

                #if NOTE
                if (c < 0.02)
                {
                    col *= 4;
                }
                #endif

                return col;
            }
            ENDCG
        }
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup
            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
