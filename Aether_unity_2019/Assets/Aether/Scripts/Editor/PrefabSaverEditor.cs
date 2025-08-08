﻿using System.Linq;
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

			// Remove C# scripts
			GameObject temp = Instantiate(saver.gameObject);
			var components = temp.GetComponents<Component>().ToList();
			foreach (var comp in components)
			{
				if (comp == null) continue; // Missing script
				var type = comp.GetType();
				if (comp is MonoBehaviour && !type.Namespace?.StartsWith("UnityEngine") == true)
				{
					DestroyImmediate(comp);
				}
			}

			PrefabUtility.SaveAsPrefabAsset(temp, prefabPath);
			AssetDatabase.Refresh();

			DestroyImmediate(temp);

			Debug.Log($"Prefab '{prefab.name}' overwritten successfully.");
		}
	}
}
