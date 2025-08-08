Shader "Swifter/SimpleTerrainFog"
{
    Properties
    {
        _SpecularAmount ("Specular Amount", Float) = 1
        _SpecularPower ("Specular Power", Float) = 16
        _DiffuseAmount ("Diffuse Amount", Float) = 1
        _Color ("Base Color", Color) = (1,1,1)
        _PastelAmount ("Pastel Amount", Range(0,1)) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2

        [Header(Note)][Space(10)]
        [Toggle(NOTE)] _IsNote ("Is Note", Int) = 0
        _Cutout ("Cutout", Range(0,1)) = 0
        [Toggle(DEBRIS)] _Debris ("Debris", Int) = 0
        _CutPlane ("Cut Plane", Vector) = (0, 0, 1, 0)

        [Header(Ambient)][Space(10)]
        [Toggle(AMBIENT_ENABLED)] _AmbientEnabled ("Enabled", Int) = 0
        _AmbientColor ("Color", Color) = (1,1,1)
        _AmbientStrength ("Strength", Float) = 1

        [Header(Sun)][Space(10)]
        [Toggle(SUN_ENABLED)] _SunEnabled ("Enabled", Int) = 0
        _SunColor ("Color", Color) = (1,1,1)
        _SunStrength ("Strength", Float) = 1

        [Header(Light 1)][Space(10)]
        [Toggle(LIGHT_1_ENABLED)] _Light1Enabled ("Enabled", Int) = 0
        _Light1Color ("Color", Color) = (1,1,1)
        _Light1Strength ("Strength", Float) = 1
        _Light1Range ("Range", Float) = 1
        _Light1Falloff ("Falloff", Float) = 1
        _Light1Flutter ("Flutter", Float) = 0
        _Light1Position ("Position", Vector) = (0, 0, 0)

        [Header(Fog)][Space(10)]
        [Toggle(FOG_ENABLED)] _FogEnabled ("Enabled", Int) = 0
        _FogColor ("Fog Color", Color) = (1,1,1)
        _FogFar ("Fog Far", Float) = 400
        _FogZStart ("Fog Z Start", Float) = 0
        _FogZEnd ("Fog Z End", Float) = 30
        [Toggle(FOG_HEIGHT_FALLOFF)] _FogHeightFalloffEnabled ("Height Falloff", Int) = 0
        _FogHeightFalloffSlope ("Height Falloff Slope", Float) = 200

        [Header(Stencil)][Space(10)]
        _StencilRef ("Stencil Ref", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", int) = 2
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
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
            #pragma shader_feature AMBIENT_ENABLED
            #pragma shader_feature SUN_ENABLED
            #pragma shader_feature LIGHT_1_ENABLED
            #pragma shader_feature FOG_ENABLED
            #pragma shader_feature FOG_HEIGHT_FALLOFF
            #pragma shader_feature NOTE
            #pragma shader_feature DEBRIS

            #include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "Flutter.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float distanceFog : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                #if NOTE
                float3 localPos : TEXCOORD4;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _SpecularAmount;
            float _SpecularPower;
            float _DiffuseAmount;
            float _PastelAmount;
            #if !NOTE
            float4 _Color;
            #endif

            float3 _AmbientColor;
            float _AmbientStrength;

            float3 _SunColor;
            float _SunStrength;

            float3 _Light1Color;
            float _Light1Strength;
            float3 _Light1Position;
            float _Light1Range;
            float _Light1Flutter;
            float _Light1Falloff;

            float3 _FogColor;
            float _FogFar;
            float _FogZStart;
            float _FogZEnd;
            float _FogHeightFalloffSlope;

            #if NOTE
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_DEFINE_INSTANCED_PROP(float, _Cutout)
            UNITY_DEFINE_INSTANCED_PROP(float4, _CutPlane)
            UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
                float3 viewDir = normalize(viewVector);

                float camDistance = length(viewVector);
                float distanceFog = smoothstep(0, _FogFar, camDistance);
                distanceFog = pow(distanceFog, 3);

                #if FOG_HEIGHT_FALLOFF
                distanceFog = saturate(distanceFog - worldPos.y / _FogHeightFalloffSlope);
                #endif

                o.distanceFog = distanceFog;
                o.viewDir = viewDir;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = worldPos;

                #if NOTE
                o.localPos = v.vertex.xyz;
                #endif

                return o;
            }

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
                col += doSpecular(i, normLightDir, lightStrength * lightDistanceNormalized);

                col *= flutter(flutterAmount);

                return col;
            }

            float doDirectionalLight(in v2f i, in float3 normLightDir, in float lightBrightness)
            {
                float col = 0;

                col += doDiffuse(i, normLightDir, lightBrightness);
                col += doSpecular(i, normLightDir, lightBrightness);

                return col;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                #if NOTE
                float4 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                float Cutout = UNITY_ACCESS_INSTANCED_PROP(Props, _Cutout);
                float c = 0;

                #if DEBRIS
                    float4 CutPlane = UNITY_ACCESS_INSTANCED_PROP(Props, _CutPlane);
                    float3 samplePoint = i.localPos + CutPlane.xyz * CutPlane.w;
                    float planeDistance = dot(samplePoint, CutPlane.xyz) / length(CutPlane.xyz);
                    c = planeDistance - Cutout * 0.4;
                #else
                    float debrisNoise = 1 - voronoi(i.localPos * 2).x / 0.8;
                    c = 1 - Cutout - debrisNoise;
                #endif

                clip(c);
                #else
                float4 Color = _Color;
                #endif

                float3 col = 0;

                #if AMBIENT_ENABLED
                col += _AmbientColor * _AmbientStrength;
                #endif

                #if SUN_ENABLED
                const float3 sunDir = float3(0,1,0);
                col += doDirectionalLight(i, sunDir, _SunStrength) * _SunColor;
                #endif

                #if LIGHT_1_ENABLED
                col += doPointLight(i, _Light1Position, _Light1Range, _Light1Falloff, _Light1Strength, _Light1Flutter) * _Light1Color;
                #endif

                #if FOG_ENABLED
                float heightFog = smoothstep(_FogZEnd, _FogZStart, i.worldPos.y);
                heightFog = pow(heightFog, 10);
                float fog = 1 - ((1 - heightFog) * (1 - i.distanceFog));
                col = lerp(col, _FogColor, fog);
                #endif

                float4 baseCol = lerp(Color, 1, _PastelAmount);
                col *= baseCol.rgb;

                return float4(col, 0);
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
