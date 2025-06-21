#include <UnityCG.cginc>

#include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
#include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"

float3 _HorizonCol;
float3 _SkyCol;
float _HueSaturation;
float _Voronoi1Scale;
float _Voronoi2Scale;
float _Simplex1Scale;
float _FBM;
float _TimeScale;
float _CloudPow;
float _CloudAmount;

float4 doSkybox(in float3 dir)
{
	float t = _Time.y * _TimeScale * 0.2;

	float v = voronoi(dir * _Voronoi1Scale + t).x;

	float3 v2Offset = float3(cos(v), 0, sin(v));
	float v2 = voronoi(dir * _Voronoi2Scale + v2Offset * _FBM + t * 0.1) * 0.3;

	float3 huePos = dir + v2;
	float hue = simplex(huePos * _Simplex1Scale) * 3;

	float3 hueCol = rainbow(hue + t);

	float3 desaturatedHue = lerp(hueCol, Luminance(hueCol) * _SkyCol, _HueSaturation);

	//return float4(hueCol, 0);

	#ifdef SKYBOX_HORIZON
	float horizonAmount = pow(1 - max(0, dir.y), 20);
	float hueAmount = (1 - horizonAmount);
	#else
	float hueAmount = 1;
	#endif

	#ifdef SKYBOX_CLOUDS
	hueAmount *= lerp(1, pow(simplex(dir * 3), _CloudPow), _CloudAmount);
	#endif

	float3 col = lerp(_HorizonCol, desaturatedHue, hueAmount);

	return float4(col, 0);
}
