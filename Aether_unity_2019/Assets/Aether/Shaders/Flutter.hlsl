#include <UnityShaderVariables.cginc>

float flutter(float amount)
{
	return max(0, lerp(1, noise1d(_Time.y * 40), amount));
}
