using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Reflection;
using System.Linq;

namespace AnimationCurveManipulationTool {

    public class CurveEditorBinding {

        private object objectReference;

        public CurveEditorBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        public List<CurveSelectionBinding> selectedCurves {
            get {
                var result = new List<CurveSelectionBinding>();
                var property = objectReference.GetType().GetProperty("selectedCurves", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                var selectedCurveList = (IEnumerable)property.GetValue(objectReference);
                foreach (var curve in selectedCurveList) {
                    var curveSelection = new CurveSelectionBinding(curve);
                    result.Add(curveSelection);
                }
                return result;
            }
        }

        public CurveWrapperBinding[] animationCurves {
            get {
                var field = objectReference.GetType().GetProperty("animationCurves", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                var animationCurveArray = field.GetValue(objectReference) as System.Array;
                if (animationCurveArray != null) {
                    CurveWrapperBinding[] result = new CurveWrapperBinding[animationCurveArray.Length];
                    for (int i = 0; i < result.Length; i++) {
                        result[i] = new CurveWrapperBinding(animationCurveArray.GetValue(i));
                    }
                    return result;
                }
                return null;
            }
        }

        private Dictionary<int, int> curveIDToIndexMap {
            get {
                return objectReference.GetType().GetProperty("curveIDToIndexMap", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference) as Dictionary<int, int>;
            }
        }

        public Keyframe GetKeyframe(CurveSelectionBinding c) => GetCurve(c).GetKeyframe(c.key);

        public CurveWrapperBinding GetCurve(int curveId) {
            if (curveIDToIndexMap.TryGetValue(curveId, out int indexMap)) {
                return animationCurves[indexMap];
            }
            return null;
        }

        public CurveWrapperBinding GetCurve(CurveSelectionBinding c) => GetCurve(c.curveId);

        public Dictionary<CurveWrapperBinding, CurveSelectionBinding[]> GetSelectedCurveIdGroups() {
            var selections = selectedCurves.Select(c => (curveId: c.curveId, selection: c));
            var groups = selections.GroupBy(x => x.curveId);
            var groupDictionary = groups.ToDictionary(g1 => GetCurve(g1.Key), g2 => g2.Select(g3 => g3.selection).ToArray());
            return groupDictionary;
        }

        public Vector2 NormalizeInViewSpace(Vector2 vec) {
            var zoomableAreaType = ReflectionUtility.unityEditorAssembly.GetType("UnityEditor.ZoomableArea");
            return (Vector2)zoomableAreaType.GetMethod("NormalizeInViewSpace", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { vec });
        }

    }

}
