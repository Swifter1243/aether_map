Shader "Mawntee/Beat Saber Wireframe 3D-Noise"
{
	Properties
	{
		[Header(Main)]
        [Space(5)]
		_WireThickness ("Wire Thickness", RANGE(0, 800)) = 100
		_WireSmoothness ("Wire Smoothness", RANGE(0.001, 50)) = 3
		_WireColor ("Wire Color", Color) = (0.0, 1.0, 0.0, 1.0)
		_BaseColor ("Base Color", Color) = (0.0, 0.0, 0.0, 1.0)
		_MaxTriSize ("Max Tri Size", RANGE(0, 1000)) = 25

		[Header(Beat Saber)]
        [Space(5)]
		_Glow ("Glow", RANGE(0, 1)) = 0

		[Header(Rendering Options)]
        [Space]
        //[Enum(Zero Zero, 0, SrcALpha OneMinusSrcAlpha, 1)] _BlendMode("Blend Mode", Int) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0

	}

	SubShader
	{
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend One OneMinusSrcColor
        Cull [_CullMode]
		Pass
		{
		    ZWrite Off
		    ColorMask 0
		}
		Pass
		{
			ZWrite Off
			// Wireframe shader based on the the following
			// http://developer.download.nvidia.com/SDK/10/direct3d/Source/SolidWireframe/Doc/SolidWireframe.pdf

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup

			#include "UnityCG.cginc"
            #include "UnityStandardParticleInstancing.cginc"
			#include "Wireframe.cginc"

			ENDCG
		}
		//Pass
		//{
		//    ZWrite On
		//    ColorMask 0
		//}
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
