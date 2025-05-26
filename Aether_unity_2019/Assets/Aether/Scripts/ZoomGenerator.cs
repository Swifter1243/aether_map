using System;
using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;
namespace Aether.Scripts
{
    public class ZoomGenerator : MonoBehaviour
    {
        [Serializable]
        public struct ZoomObject
        {
            [SerializeField] public GameObject prefab;
        }

        public ZoomObject[] objects;
        public GameObject parent;
        public AnimationClip clip;
        public float startTime;
        public float endTime;
        public float zoomDuration = 10;
        public float zoomFrequency = 3;
        public Vector3 zoomEndSize = Vector3.one * 1000;


        private void DestroyChildren(Transform transform)
        {
            while (transform.childCount > 0)
            {
                // god, I hate children.
                DestroyImmediate(transform.GetChild(0).gameObject);
            }
        }

        public void ClearPrevious()
        {
            if (parent == null || clip == null) return;

            Transform parentObj = parent.transform;
            Transform rootObj = parentObj.root;

            // 1. Clear children
            DestroyChildren(parentObj);

            // 2. Clear animation on parent and its children
            ClearAnimations(rootObj, parentObj, clip);
        }

        public void GenerateZooms()
        {
            if (parent == null || clip == null) return;

            ClearPrevious();

            Transform parentObj = parent.transform;
            Transform rootObj = parentObj.root;

            // 3. Instantiate and animate
            float currentStartTime = startTime;

            while (currentStartTime < endTime)
            {
                ZoomObject zoom = objects[(int)(Random.value * objects.Length)];
                if (zoom.prefab == null) continue;

                GameObject instance = Instantiate(zoom.prefab, parentObj);
                instance.transform.localScale = Vector3.zero;
                instance.transform.localPosition = Vector3.zero;
                instance.transform.localRotation = Quaternion.identity;
                instance.name = $"Zoom_{currentStartTime}";

                string path = AnimationUtility.CalculateTransformPath(instance.transform, rootObj);

                AddZoomInAnimation(clip, path, currentStartTime, currentStartTime + zoomDuration);

                currentStartTime += zoomFrequency;
            }

            AssetDatabase.SaveAssets();
        }

        private void ClearAnimations(Transform root, Transform parent, AnimationClip clip)
        {
            string parentPath = AnimationUtility.CalculateTransformPath(parent, root);

            foreach (var binding in AnimationUtility.GetCurveBindings(clip))
            {
                bool isAtLeastParent = binding.path.StartsWith(parentPath);
                if (isAtLeastParent)
                {
                    AnimationUtility.SetEditorCurve(clip, binding, null);
                }
            }
        }

        private void AddZoomInAnimation(AnimationClip clip, string path, float startTime, float endTime)
        {
            AnimationCurve curveX = AnimationCurve.Linear(startTime, 0, endTime, zoomEndSize.x);
            AnimationCurve curveY = AnimationCurve.Linear(startTime, 0, endTime, zoomEndSize.y);
            AnimationCurve curveZ = AnimationCurve.Linear(startTime, 0, endTime, zoomEndSize.z);

            clip.SetCurve(path, typeof(Transform), "m_LocalScale.x", curveX);
            clip.SetCurve(path, typeof(Transform), "m_LocalScale.y", curveY);
            clip.SetCurve(path, typeof(Transform), "m_LocalScale.z", curveZ);
        }
    }
}
