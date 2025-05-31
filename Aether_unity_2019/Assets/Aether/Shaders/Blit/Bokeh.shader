Shader "Swifter/Blit/Bokeh"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    	_Radius ("Radius", Float) = 0.1
    	_Steps ("Steps", Int) = 25
    	_Gamma ("Gamma", Float) = 4

    	[Toggle(DEPTH_OF_FIELD)] _DepthOfFieldEnabled ("Depth Of Field", Int) = 0
    	_FocalDistance ("Focal Distance", Float) = 100
    	_FocalFalloff ("Focal Falloff", Float) = 5
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature DEPTH_OF_FIELD

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            #include "../Flutter.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #if DEPTH_OF_FIELD
			UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraDepthTexture);
            #endif

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
            float2 _MainTex_TexelSize;
            float _Radius;
            int _Steps;
            float _Gamma;
            float _FocalDistance;
            float _FocalFalloff;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o)

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 getScreenCol(float2 uv)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, UnityStereoTransformScreenSpaceTex(uv));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

            	#if DEPTH_OF_FIELD
            	float2 screenUV = UnityStereoTransformScreenSpaceTex(i.uv);
            	float depthRaw = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraDepthTexture, screenUV);
            	float depthZ = LinearEyeDepth(depthRaw);

            	float focalDistance = abs(depthZ - _FocalDistance);
            	float clarity = exp(-focalDistance * _FocalFalloff);
            	float radius = _Radius * (1 - clarity);
            	#else
            	float radius = _Radius;
            	#endif

            	// ADAPTED FROM: https://github.com/XorDev/Bokeh/wiki

				//Initialize blur output color
				float4 blur = 0;

				//First sample offset
				float scale = radius*rsqrt(_Steps);
				float2 p = float2(scale,0);

				//Golden angle rotation matrix
				float2x2 ang = float2x2(-0.7373688, -0.6754904, 0.6754904,  -0.7373688);

				//Look through all the samples
            	[loop]
				for(float s = 0.0;s<_Steps;s++)
				{
					//Rotate point direction
					p = mul(p, ang);

					//Get sample coordinates
					float2 uv = i.uv + p * sqrt(s) * 0.001;
					//Sample texture
			        float4 samp = getScreenCol(uv);

					//Add sample to total
					blur += pow(samp, _Gamma);
				}

				//Get sample average
				blur /= _Steps;
				//Correct for exposure

            	return pow(blur, 1.0/_Gamma);
            }
            ENDCG
        }
    }
}
