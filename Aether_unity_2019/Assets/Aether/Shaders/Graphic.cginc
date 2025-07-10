float _GraphicNoise1Scale;
float _GraphicNoise2Scale;
float _GraphicNoise2Influence;
float _GraphicNoiseInfluence;
float _GraphicCutoff;
float _GraphicSharpness;

inline float posterize(float x, float n)
{
	return round(x * n) / n;
}

void doGraphic(inout float v, in float2 p)
{
	float time = (_Time.y % 300);

	float2 fireP = p * _GraphicNoise1Scale - time * 6;

	float n = simplex(fireP);

	fireP = p * _GraphicNoise2Scale - time * 3;

	n -= voronoi(fireP + n) * _GraphicNoise2Influence;

	v += n * _GraphicNoiseInfluence;

	v -= _GraphicCutoff;

	v = saturate(v);

	v = posterize(v, 3);

	v *= _GraphicSharpness;
}
