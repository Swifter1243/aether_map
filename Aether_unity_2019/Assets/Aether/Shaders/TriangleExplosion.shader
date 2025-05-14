Shader "Swifter/TriangleExplosion"
{
    Properties
    {
    	_ExplosionPoint ("Explosion Point", Vector) = (0, -10, 0)
    	_ExplosionTime ("Explosion Time", Float) = 10
    	_ExplosionRange ("Explosion Range", Float) = 5
    	_ExplosionFalloff ("Explosion Falloff", Float) = 2
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
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
            	float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct v2g
			{
				float4 proj : SV_POSITION;
				float4 localPos : TEXCOORD0;
				float3 normal : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				bool visible : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            float3 _ExplosionPoint;
            float _ExplosionTime;
            float _ExplosionRange;
            float _ExplosionFalloff;

            v2g vert (appdata v)
            {
            	v2g o;
                UNITY_SETUP_INSTANCE_ID(v);
            	UNITY_TRANSFER_INSTANCE_ID(v, v2g);

                o.proj = UnityObjectToClipPos(v.vertex);
            	o.localPos = v.vertex;
            	o.localPos.w = 1;
            	o.normal = v.normal;
                return o;
            }

            // https://www.shadertoy.com/view/XlXcW4
            float3 hash33( int3 x )
			{
            	const uint k = 1103515245U;
			    x = ((x>>8U)^x.yzx)*k;
			    x = ((x>>8U)^x.yzx)*k;
			    x = ((x>>8U)^x.yzx)*k;

			    return float3(x)*(1.0/float(0xffffffffU));
			}

            float3 random_in_unit_sphere(float3 seed)
			{
			    float3 h = hash(seed) * float3(2., 6.28318530718, 1.) - float3(1, 0, 0);
			    float phi = h.y;
			    float r = pow(h.z, 1. / 3.);
			    return r * float3(sqrt(1. - h.x * h.x) * float2(sin(phi), cos(phi)), h.x);
			}

            float4x4 rotate3D(float x, float y, float z)
            {
			    float cx = cos(x);
			    float sx = sin(x);
			    float cy = cos(y);
			    float sy = sin(y);
			    float cz = cos(z);
			    float sz = sin(z);

			    return float4x4(
			        cy*cx, sz*sy*cx - cz*sx, cz*sy*cx + sz*sx, 0,
			        cy*sx, sz*sy*sx + cz*cx, cz*sy*sx - sz*cx, 0,
			        -sy, sz*cy, cz*cy, 0,
			        0, 0, 0, 1
			    );
            }

            float4 applyExplosion(in v2g i, in float3 midPoint, in float3 newMidPoint, in float4x4 rotation)
            {
            	float4 pos = i.localPos;
            	pos.y += 0.01;
            	pos.xyz *= 1.01;
            	pos.xyz -= midPoint;
            	pos = mul(rotation, pos);
            	pos.xyz += newMidPoint;
            	return UnityObjectToClipPos(pos);
            }

            [maxvertexcount(6)]
			void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
			{
            	UNITY_SETUP_INSTANCE_ID(i[0])

				g2f o1;
				g2f o2;
				g2f o3;

				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o1);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o2);
				UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o3);

				o1.vertex = i[0].proj;
            	o1.visible = true;
				triangleStream.Append(o1);
				o2.vertex = i[1].proj;
            	o2.visible = true;
				triangleStream.Append(o2);
				o3.vertex = i[2].proj;
            	o3.visible = true;
				triangleStream.Append(o3);

            	float3 midPoint = (i[0].localPos + i[1].localPos + i[2].localPos) * 0.333333;
            	float3 fromExplosion = midPoint - _ExplosionPoint;
            	float3 travelDir = normalize(fromExplosion);

            	float explosionInfluence = max(0, 1 - length(fromExplosion) / _ExplosionRange);
            	explosionInfluence = pow(explosionInfluence, _ExplosionFalloff);
            	float explosionPower = _ExplosionTime * explosionInfluence;

            	float3 newMidpoint = midPoint + travelDir * explosionPower;
            	float3 angularMomentum = random_in_unit_sphere(midPoint) * explosionPower;
            	float4x4 rotate = rotate3D(angularMomentum.x, angularMomentum.y, angularMomentum.z);

            	float3 worldNewMidPoint = mul(unity_ObjectToWorld, newMidpoint);
            	float3 rotatedNormal = mul(rotate, i[0].normal);
            	float3 worldNormal = UnityObjectToWorldNormal(rotatedNormal);
            	float3 toMidpoint = normalize(worldNewMidPoint - _WorldSpaceCameraPos);
            	bool visible = dot(worldNormal, toMidpoint) > 0;

            	triangleStream.RestartStrip();

            	o1.vertex = applyExplosion(i[0], midPoint, newMidpoint, rotate);
            	o1.visible = visible;
            	triangleStream.Append(o1);
            	o2.vertex = applyExplosion(i[1], midPoint, newMidpoint, rotate);
            	o2.visible = visible;
            	triangleStream.Append(o2);
            	o3.vertex = applyExplosion(i[2], midPoint, newMidpoint, rotate);
            	o3.visible = visible;
            	triangleStream.Append(o3);
			}

            fixed4 frag (g2f i) : SV_Target
            {
                return i.visible ? float4(0, 1, 0, 0) : float4(0, 0, 0, 1);
            }
            ENDCG
        }
    }
}
