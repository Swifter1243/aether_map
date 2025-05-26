using UnityEditor;
using UnityEngine;
namespace Aether.Scripts.Editor
{
	[CustomEditor(typeof(ZoomGenerator))]
	public class ZoomGeneratorInspector : UnityEditor.Editor
	{
		public override void OnInspectorGUI()
		{
			base.OnInspectorGUI();

			ZoomGenerator zoomGenerator = (ZoomGenerator)target;

			GUILayout.Space(10);
			if (GUILayout.Button("Generate", GUILayout.Height(30)))
			{
				zoomGenerator.GenerateZooms();
			}

			GUILayout.Space(10);
			if (GUILayout.Button("Clear Previous", GUILayout.Height(30)))
			{
				zoomGenerator.ClearPrevious();
			}
		}
	}
}
