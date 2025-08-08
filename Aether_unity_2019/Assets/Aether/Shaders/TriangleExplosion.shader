Shader "Swifter/TriangleExplosion"
{
    Properties
    {
    	_StencilRef ("Stencil Reference", Int) = 1

    	[Header(Blend)][Space(10)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Float) = 6

    	[Header(Fog)][Space(10)]
        [Toggle(DISTANCE_FOG)] _DistanceFogEnabled ("Distance Fog Enabled", Int) = 0
        _FadeDistanceStart ("Fade Distance Start", Float) = 500
        _FadeDistanceEnd ("Fade Distance End", Float) = 800
        [Toggle(HEIGHT_FOG)] _HeightFogEnabled ("Height Fog Enabled", Int) = 0
        _HeightFogStart ("Height Fog Start", Float) = 0
        _HeightFogEnd ("Height Fog End", Float) = 10

    	[Header(Explosion)][Space(10)]
    	_ExplosionTime ("Explosion Time", Float) = 10
    	_ExplosionRange ("Explosion Range", Float) = 5
    	_ExplosionFalloff ("Explosion Falloff", Float) = 2
    	_ExplosionPoint ("Explosion Point", Vector) = (0, -10, 0)
    	_ExplosionNoise ("Explosion Noise", Float) = 0
    	_ExplosionSpin ("Explosion Spin", Float) = 1

    	[Header(Sky)][Space(10)]
        _HorizonCol ("Horizon Color", Color) = (1,1,1)
        _SkyCol ("Sky Color", Color) = (1,1,1)
        _HueSaturation ("Hue Saturation", Float) = 0.7
        _Voronoi1Scale ("Voronoi 1 Scale", Float) = 20
        _Voronoi2Scale ("Voronoi 2 Scale", Float) = 3
        _Simplex1Scale ("Simplex 1 Scale", Float) = 3
        _FBM ("Fractional Brownian Motion", Float) = 0.3
        _TimeScale ("Time Scale", Float) = 1
        [Toggle(SKYBOX_HORIZON)] _SkyboxHorizon ("Horizon", Int) = 0
        [Toggle(SKYBOX_CLOUDS)] _SkyboxClouds ("Clouds", Int) = 0
        _CloudPow ("Cloud Pow", Float) = 3.5
        _CloudAmount ("Cloud Amount", Float) = 1
        [Toggle(SKYBOX_CLOUD_FOG)] _SkyboxCloudFog ("Cloud Fog", Int) = 0
        _SkyboxCloudFogDistance ("Cloud Fog Distance", Float) = 100
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }

        Pass // Backside Stencil Pass
        {
			Cull Back
			ColorMask 0

        	Stencil
        	{
        		Ref [_StencilRef]
        		Comp Always
        		Pass Replace
        	}

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
			#include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct v2g
			{
				float4 proj : SV_POSITION;
				float4 localPos : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            float3 _ExplosionPoint;
            float _ExplosionTime;
            float _ExplosionRange;
            float _ExplosionFalloff;
            float _ExplosionNoise;
            float _ExplosionSpin;

            v2g vert (appdata v)
            {
            	v2g o;
			    UNITY_SETUP_INSTANCE_ID(v);
			    UNITY_INITIALIZE_OUTPUT(v2g, o);
			    UNITY_TRANSFER_INSTANCE_ID(v, o);
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.proj = UnityObjectToClipPos(v.vertex);
            	o.localPos = v.vertex;
            	o.localPos.w = 1;
                return o;
            }

            void applyExplosion(in v2g i, inout v2f o, in float3 midPoint, in float3 newMidPoint, in float4x4 rotation)
            {
            	float4 pos = i.localPos;
            	pos.xyz -= midPoint;
            	pos = mul(rotation, pos);
            	pos.xyz += newMidPoint;
            	o.vertex = UnityObjectToClipPos(pos);
            }

            [maxvertexcount(3)]
			void geom(triangle v2g i[3], inout TriangleStream<v2f> triangleStream)
			{
            	UNITY_SETUP_INSTANCE_ID(i[0])

				v2f o1;
				v2f o2;
				v2f o3;

            	UNITY_INITIALIZE_OUTPUT(v2f, o1);
            	UNITY_INITIALIZE_OUTPUT(v2f, o2);
            	UNITY_INITIALIZE_OUTPUT(v2f, o3);

				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o1);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o2);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o3);

            	float3 midPoint = (i[0].localPos + i[1].localPos + i[2].localPos) * 0.333333;
            	float3 fromExplosion = midPoint - _ExplosionPoint;
            	float3 travelDir = normalize(fromExplosion);

            	float explosionInfluence = max(0, 1 - length(fromExplosion) / _ExplosionRange);
            	explosionInfluence = pow(explosionInfluence, _ExplosionFalloff);
            	float explosionPower = _ExplosionTime * explosionInfluence;

            	float3 noise = random_in_unit_sphere(midPoint);
            	float3 newMidpoint = midPoint + travelDir * (explosionPower + noise.x * _ExplosionNoise * explosionPower);
            	float3 angularMomentum = noise * explosionPower * _ExplosionSpin;
            	float4x4 rotate = rotate3DMatrix(angularMomentum.x, angularMomentum.y, angularMomentum.z);

            	triangleStream.RestartStrip();

            	applyExplosion(i[0], o1, midPoint, newMidpoint, rotate);
            	applyExplosion(i[1], o2, midPoint, newMidpoint, rotate);
            	applyExplosion(i[2], o3, midPoint, newMidpoint, rotate);

            	triangleStream.Append(o1);
            	triangleStream.Append(o2);
            	triangleStream.Append(o3);
			}

            fixed4 frag () : SV_Target { return 0; }
            ENDCG
        }
		Pass // Front Explosion Pass
        {
        	Cull Front

			Blend [_SrcBlend] [_DstBlend]

        	Stencil
        	{
        		Ref [_StencilRef]
        		Comp Always
        		Pass Replace
        	}

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature SKYBOX_HORIZON
            #pragma shader_feature SKYBOX_CLOUDS
            #pragma shader_feature SKYBOX_CLOUD_FOG
            #pragma shader_feature DISTANCE_FOG
            #pragma shader_feature HEIGHT_FOG

            #include "UnityCG.cginc"
            #include "RainbowSkybox.hlsl"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct v2g
			{
				float4 proj : SV_POSITION;
				float4 localPos : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 viewDir : TEXCOORD0;
                #if DISTANCE_FOG
                float distanceFog : TEXCOORD1;
                #endif
				#if HEIGHT_FOG
				float3 worldPos : TEXCOORD2;
				#endif
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            float3 _ExplosionPoint;
            float _ExplosionTime;
            float _ExplosionRange;
            float _ExplosionFalloff;
            float _ExplosionNoise;
            float _ExplosionSpin;
            float _FadeDistanceStart;
            float _FadeDistanceEnd;
            float _HeightFogStart;
            float _HeightFogEnd;

            v2g vert (appdata v)
            {
            	v2g o;
			    UNITY_SETUP_INSTANCE_ID(v);
			    UNITY_INITIALIZE_OUTPUT(v2g, o);
			    UNITY_TRANSFER_INSTANCE_ID(v, o);
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.proj = UnityObjectToClipPos(v.vertex);
            	o.localPos = v.vertex;
            	o.localPos.w = 1;
                return o;
            }

            void applyExplosion(in v2g i, inout v2f o, in float3 midPoint, in float3 newMidPoint, in float4x4 rotation)
            {
            	float4 pos = i.localPos;
            	pos.xyz -= midPoint;
            	pos = mul(rotation, pos);
            	pos.xyz += newMidPoint;
            	float3 worldPos = mul(unity_ObjectToWorld, pos);
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
            	float3 viewDir = normalize(viewVector);

                #if DISTANCE_FOG
                float viewDistance = length(viewVector);
                o.distanceFog = smoothstep(_FadeDistanceEnd, _FadeDistanceStart, viewDistance);
                #endif

            	#if HEIGHT_FOG
            	o.worldPos = worldPos;
            	#endif

            	o.vertex = UnityObjectToClipPos(pos);
            	o.viewDir = viewDir;
            }

            [maxvertexcount(3)]
			void geom(triangle v2g i[3], inout TriangleStream<v2f> triangleStream)
			{
            	UNITY_SETUP_INSTANCE_ID(i[0])

				v2f o1;
				v2f o2;
				v2f o3;

            	UNITY_INITIALIZE_OUTPUT(v2f, o1);
            	UNITY_INITIALIZE_OUTPUT(v2f, o2);
            	UNITY_INITIALIZE_OUTPUT(v2f, o3);

				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o1);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o2);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o3);

            	float3 midPoint = (i[0].localPos + i[1].localPos + i[2].localPos) * 0.333333;
            	float3 fromExplosion = midPoint - _ExplosionPoint;
            	float3 travelDir = normalize(fromExplosion);

            	float explosionInfluence = max(0, 1 - length(fromExplosion) / _ExplosionRange);
            	explosionInfluence = pow(explosionInfluence, _ExplosionFalloff);
            	float explosionPower = _ExplosionTime * explosionInfluence;

            	float3 noise = random_in_unit_sphere(midPoint);
            	float3 newMidpoint = midPoint + travelDir * (explosionPower + noise.x * _ExplosionNoise * explosionPower);
            	float3 angularMomentum = noise * explosionPower * _ExplosionSpin;
            	float4x4 rotate = rotate3DMatrix(angularMomentum.x, angularMomentum.y, angularMomentum.z);

            	triangleStream.RestartStrip();

            	applyExplosion(i[0], o1, midPoint, newMidpoint, rotate);
            	applyExplosion(i[1], o2, midPoint, newMidpoint, rotate);
            	applyExplosion(i[2], o3, midPoint, newMidpoint, rotate);

            	triangleStream.Append(o1);
            	triangleStream.Append(o2);
            	triangleStream.Append(o3);
			}

            fixed4 frag (v2f i) : SV_Target
            {
            	float4 col = doSkybox(i.viewDir);

            	float fog = 1;

                #if DISTANCE_FOG
                fog *= i.distanceFog;
                #endif

                #if HEIGHT_FOG
                float heightFog = smoothstep(_HeightFogStart, _HeightFogEnd, i.worldPos.y);
                heightFog = pow(heightFog, 10);
                fog *= heightFog;
                #endif

                col = lerp(0, col, fog);

                return col;
            }
            ENDCG
        }
		Pass // Base Pass
		{
			Stencil
			{
				Ref [_StencilRef]
				Comp NotEqual
				Pass Keep
			}

			Blend [_SrcBlend] [_DstBlend]

			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature SKYBOX_HORIZON
            #pragma shader_feature SKYBOX_CLOUDS
            #pragma shader_feature SKYBOX_CLOUD_FOG
            #pragma shader_feature DISTANCE_FOG
            #pragma shader_feature HEIGHT_FOG

            #include "UnityCG.cginc"
            #include "RainbowSkybox.hlsl"

			struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 viewDir : TEXCOORD0;
                #if DISTANCE_FOG
                float distanceFog : TEXCOORD1;
                #endif
				#if HEIGHT_FOG
				float3 worldPos : TEXCOORD2;
				#endif
				UNITY_VERTEX_OUTPUT_STEREO
			};

            float _FadeDistanceStart;
            float _FadeDistanceEnd;
            float _HeightFogStart;
            float _HeightFogEnd;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
            	float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 viewVector = worldPos - _WorldSpaceCameraPos;
            	o.viewDir = normalize(viewVector);

            	#if DISTANCE_FOG
                float viewDistance = length(viewVector);
                o.distanceFog = smoothstep(_FadeDistanceEnd, _FadeDistanceStart, viewDistance);
            	#endif

            	#if HEIGHT_FOG
            	o.worldPos = worldPos;
            	#endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
            	float4 col = doSkybox(i.viewDir);

            	float fog = 1;

                #if DISTANCE_FOG
                fog *= i.distanceFog;
                #endif

                #if HEIGHT_FOG
                float heightFog = smoothstep(_HeightFogStart, _HeightFogEnd, i.worldPos.y);
                heightFog = pow(heightFog, 10);
                fog *= heightFog;
                #endif

                col = lerp(0, col, fog);

                return col;
            }
            ENDCG
		}
    }
}
