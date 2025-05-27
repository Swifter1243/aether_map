using System;
using System.Collections.Generic;
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
        public float rotateTimeOffsetPercentage = 0.4f;
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
                instance.SetActive(false);

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

        private AnimationCurve GenerateLogZoomCurve(float startTime, float startScale, float endTime, float endScale, int steps = 10)
        {
            AnimationCurve curve = new AnimationCurve();

            // Prevent invalid logs
            float safeStart = Mathf.Max(startScale, 0.0001f);
            float safeEnd = Mathf.Max(endScale, 0.0001f);

            List<Keyframe> keys = new List<Keyframe>();

            for (int i = 0; i <= steps; i++)
            {
                float t = i / (float)steps;
                float time = Mathf.Lerp(startTime, endTime, t);
                float value = safeStart * Mathf.Pow(safeEnd / safeStart, t);

                keys.Add(new Keyframe(time, value));
            }

            // Compute tangents based on slope between neighbors
            for (int i = 0; i < keys.Count; i++)
            {
                Keyframe key = keys[i];
                float inTangent = 0f, outTangent = 0f;

                if (i > 0)
                {
                    float dx = keys[i].time - keys[i - 1].time;
                    float dy = keys[i].value - keys[i - 1].value;
                    inTangent = dy / dx;
                }

                if (i < keys.Count - 1)
                {
                    float dx = keys[i + 1].time - keys[i].time;
                    float dy = keys[i + 1].value - keys[i].value;
                    outTangent = dy / dx;
                }

                key.inTangent = inTangent;
                key.outTangent = outTangent;

                keys[i] = key;
            }

            curve.keys = keys.ToArray();
            return curve;
        }

        private void AddZoomInAnimation(AnimationClip clip, string path, float startTime, float endTime)
        {
            // Zoom (scale)
            AnimationCurve scaleXCurve = GenerateLogZoomCurve(startTime, 0, endTime, zoomEndSize.x, 50);
            AnimationCurve scaleYCurve = GenerateLogZoomCurve(startTime, 0, endTime, zoomEndSize.y, 50);
            AnimationCurve scaleZCurve = GenerateLogZoomCurve(startTime, 0, endTime, zoomEndSize.z, 50);

            clip.SetCurve(path, typeof(Transform), "m_LocalScale.x", scaleXCurve);
            clip.SetCurve(path, typeof(Transform), "m_LocalScale.y", scaleYCurve);
            clip.SetCurve(path, typeof(Transform), "m_LocalScale.z", scaleZCurve);

            // Random spin on X, Y, Z axes
            float startAngleX = Random.Range(-180, 180);
            float endAngleX = -startAngleX;

            float startAngleY = Random.Range(-180, 180);
            float endAngleY = -startAngleY;

            float startAngleZ = Random.Range(-180, 180);
            float endAngleZ = -startAngleZ;

            float rotationStartTime = startTime + zoomDuration * rotateTimeOffsetPercentage;
            float rotationEndTime = endTime + zoomDuration * rotateTimeOffsetPercentage;

            AnimationCurve rotX = AnimationCurve.Linear(rotationStartTime, startAngleX, rotationEndTime, endAngleX);
            AnimationCurve rotY = AnimationCurve.Linear(rotationStartTime, startAngleY, rotationEndTime, endAngleY);
            AnimationCurve rotZ = AnimationCurve.Linear(rotationStartTime, startAngleZ, rotationEndTime, endAngleZ);

            clip.SetCurve(path, typeof(Transform), "localEulerAnglesRaw.x", rotX);
            clip.SetCurve(path, typeof(Transform), "localEulerAnglesRaw.y", rotY);
            clip.SetCurve(path, typeof(Transform), "localEulerAnglesRaw.z", rotZ);

            // Active state
            AnimationCurve visibilityCurve = new AnimationCurve();
            visibilityCurve.AddKey(new Keyframe(0, 0));
            visibilityCurve.AddKey(new Keyframe(startTime, 1));
            visibilityCurve.AddKey(new Keyframe(endTime, 0));

            AnimationUtility.SetKeyLeftTangentMode(visibilityCurve, 0, AnimationUtility.TangentMode.Constant);
            AnimationUtility.SetKeyLeftTangentMode(visibilityCurve, 1, AnimationUtility.TangentMode.Constant);
            AnimationUtility.SetKeyLeftTangentMode(visibilityCurve, 2, AnimationUtility.TangentMode.Constant);

            clip.SetCurve(path, typeof(GameObject), "m_IsActive", visibilityCurve);
        }
    }
}
