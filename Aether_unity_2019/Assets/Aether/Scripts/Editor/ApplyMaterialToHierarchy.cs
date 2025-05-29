using UnityEditor;
using UnityEngine;

namespace Aether.Scripts.Editor
{
	public class ApplyMaterialToHierarchy : EditorWindow
	{
		private GameObject targetObject;
		private Material materialToApply;

		[MenuItem("Window/Apply Material to Hierarchy")]
		public static void ShowWindow()
		{
			GetWindow<ApplyMaterialToHierarchy>("Apply Material");
		}

		private void OnGUI()
		{
			GUILayout.Label("Apply Material to Object and Children", EditorStyles.boldLabel);

			targetObject = (GameObject)EditorGUILayout.ObjectField("Target Object", targetObject, typeof(GameObject), true);
			materialToApply = (Material)EditorGUILayout.ObjectField("Material", materialToApply, typeof(Material), false);

			if (GUILayout.Button("Apply Material"))
			{
				if (targetObject == null || materialToApply == null)
				{
					EditorUtility.DisplayDialog("Missing Info", "Please assign both a target object and a material.", "OK");
					return;
				}

				ApplyMaterialRecursively(targetObject.transform, materialToApply);
				EditorUtility.DisplayDialog("Success", "Material applied to all child renderers!", "OK");
			}
		}

		private void ApplyMaterialRecursively(Transform parent, Material material)
		{
			foreach (Renderer renderer in parent.GetComponents<Renderer>())
			{
				renderer.sharedMaterial = material;
			}

			foreach (Transform child in parent)
			{
				ApplyMaterialRecursively(child, material);
			}
		}
	}
}
