using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;

namespace Aether.Scripts.Editor
{
	[CustomEditor(typeof(PrefabSaver))]
	public class PrefabSaverEditor : UnityEditor.Editor
	{
		public override void OnInspectorGUI()
		{
			DrawDefaultInspector();

			PrefabSaver saver = (PrefabSaver)target;

			GUILayout.Space(10);
			if (saver.destination == null)
			{
				EditorGUILayout.HelpBox("Please assign a destination prefab.", MessageType.Warning);
				return;
			}

			if (GUILayout.Button("Save To Destination", GUILayout.Height(30)))
			{
				SaveToPrefab(saver);
			}
		}

		private void SaveToPrefab(PrefabSaver saver)
		{
			var prefab = saver.destination;
			string prefabPath = AssetDatabase.GetAssetPath(prefab);

			if (string.IsNullOrEmpty(prefabPath))
			{
				Debug.LogError("Destination prefab must be an asset in the project, not a scene object.");
				return;
			}

			PrefabUtility.SaveAsPrefabAsset(saver.gameObject, prefabPath);
			AssetDatabase.Refresh();

			Debug.Log($"Prefab '{prefab.name}' overwritten successfully.");
		}
	}
}
