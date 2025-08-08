using System;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Aether.Scripts
{
    public class ZoomGenerator : MonoBehaviour
    {
        [Serializable]
        public struct ZoomStructure
        {
            [SerializeField] public GameObject prefab;
        }

        public ZoomStructure[] structures;
        public GameObject parent;
        public AnimationClip clip;
        public float startTime;
        public float endTime;
        public float zoomDuration = 10;
        public float zoomFrequency = 3;
        public float zoomEndSize = 1000;
        public float centeredScale = 100;
        public float minVisibleScale = 2;

#if UNITY_EDITOR
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
            float currentTime = startTime;

            while (currentTime < endTime)
            {
                ZoomStructure zoom = structures[(int)(Random.value * structures.Length)];
                if (zoom.prefab == null) continue;

                GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(zoom.prefab, parentObj);
                instance.transform.localPosition = Vector3.zero;
                instance.name = $"Zoom_{currentTime}";

                string path = AnimationUtility.CalculateTransformPath(instance.transform, rootObj);

                AddZoomInAnimation(clip, path, currentTime);

                currentTime += zoomFrequency;
            }

            UnityEditor.SceneManagement.EditorSceneManager.MarkSceneDirty(parent.scene);
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

        private struct LogZoomCurveOutput
        {
            public float firstVisibleTime;
            public float startTime;
            public float endTime;
            public AnimationCurve curve;
        }

        private LogZoomCurveOutput GenerateLogZoomCurve(float centeredTime, int steps = 10)
        {
            AnimationCurve curve = new AnimationCurve();

            // Prevent invalid logs
            float sizeStart = 0.0001f;
            float sizeEnd = zoomEndSize;

            List<Keyframe> keys = new List<Keyframe>();

            float tOffset = Mathf.Log(centeredScale/sizeStart) / Mathf.Log(sizeEnd/sizeStart);
            float keyframesStart = (-tOffset) * zoomDuration + centeredTime;
            float keyframesEnd = (-tOffset + 1) * zoomDuration + centeredTime;

            float firstVisibleTime = float.MaxValue;

            for (int i = 0; i <= steps; i++)
            {
                float t = i / (float)steps;
                float time = Mathf.Lerp(keyframesStart, keyframesEnd, t);
                float value = sizeStart * Mathf.Pow(sizeEnd / sizeStart, t);

                if (value < minVisibleScale)
                    continue;

                firstVisibleTime = Math.Min(time, firstVisibleTime);

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

            return new LogZoomCurveOutput
            {
                firstVisibleTime = firstVisibleTime,
                startTime = keyframesStart,
                endTime = keyframesEnd,
                curve = curve
            };
        }

        private void AddZoomInAnimation(AnimationClip clip, string path, float centeredTime)
        {
            // Zoom (scale)
            LogZoomCurveOutput scaleCurve = GenerateLogZoomCurve(centeredTime, 50);

            clip.SetCurve(path, typeof(Transform), "m_LocalScale.x", scaleCurve.curve);
            clip.SetCurve(path, typeof(Transform), "m_LocalScale.y", scaleCurve.curve);
            clip.SetCurve(path, typeof(Transform), "m_LocalScale.z", scaleCurve.curve);

            // Random spin on X, Y, Z axes
            float startAngleX = Random.Range(-180, 180);
            float endAngleX = -startAngleX;

            float startAngleY = Random.Range(-180, 180);
            float endAngleY = -startAngleY;

            float startAngleZ = Random.Range(-180, 180);
            float endAngleZ = -startAngleZ;
            float zRoll = Random.Range(0, 360);
            startAngleZ += zRoll;
            endAngleZ += zRoll;

            float rotationHalfTime = Math.Max(centeredTime - scaleCurve.startTime, scaleCurve.endTime - centeredTime);
            float rotationStartTime = centeredTime - rotationHalfTime;
            float rotationEndTime = centeredTime + rotationHalfTime;

            AnimationCurve rotX = AnimationCurve.Linear(rotationStartTime, startAngleX, rotationEndTime, endAngleX);
            AnimationCurve rotY = AnimationCurve.Linear(rotationStartTime, startAngleY, rotationEndTime, endAngleY);
            AnimationCurve rotZ = AnimationCurve.Linear(rotationStartTime, startAngleZ, rotationEndTime, endAngleZ);

            clip.SetCurve(path, typeof(Transform), "localEulerAnglesRaw.x", rotX);
            clip.SetCurve(path, typeof(Transform), "localEulerAnglesRaw.y", rotY);
            clip.SetCurve(path, typeof(Transform), "localEulerAnglesRaw.z", rotZ);

            // Active state
            AnimationCurve visibilityCurve = new AnimationCurve();
            visibilityCurve.AddKey(new Keyframe(0, 0));
            visibilityCurve.AddKey(new Keyframe(scaleCurve.firstVisibleTime, 1));
            visibilityCurve.AddKey(new Keyframe(scaleCurve.endTime, 0));

            AnimationUtility.SetKeyLeftTangentMode(visibilityCurve, 0, AnimationUtility.TangentMode.Constant);
            AnimationUtility.SetKeyLeftTangentMode(visibilityCurve, 1, AnimationUtility.TangentMode.Constant);
            AnimationUtility.SetKeyLeftTangentMode(visibilityCurve, 2, AnimationUtility.TangentMode.Constant);

            clip.SetCurve(path, typeof(GameObject), "m_IsActive", visibilityCurve);
        }
#endif
    }
}
