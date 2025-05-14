Shader "Custom/SimpleTerrainFog"
{
    Properties
    {
        _SpecularAmount ("Specular Amount", Float) = 1
        _SpecularPower ("Specular Power", Float) = 16
        _DiffuseAmount ("Diffuse Amount", Float) = 1

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
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
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
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _SpecularAmount;
            float _SpecularPower;
            float _DiffuseAmount;

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

            v2f vert(appdata v)
            {

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
                float3 viewDir = normalize(viewVector);

                float camDistance = length(viewVector);
                float distanceFog = smoothstep(0, _FogFar, camDistance);
                distanceFog = pow(distanceFog, 3);
                distanceFog = saturate(distanceFog - worldPos.y / 200);

                o.distanceFog = distanceFog;
                o.viewDir = viewDir;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = worldPos;

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
            };

            v2f vert(appdata_base v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)
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
