using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public class AnimationWindowKeyframeBinding {

        private object objectReference;

        public AnimationWindowKeyframeBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        private static System.Type bindedType;
        public static System.Type GetBindedType() {
            if (bindedType == null) {
                bindedType = ReflectionUtility.unityEditorAssembly.GetType("UnityEditorInternal.AnimationWindowKeyframe");
            }
            return bindedType;
        }

        public object GetObjectReference() { return objectReference; }

        public float time {
            get {
                return (float)objectReference.GetType()
                    .GetProperty("time", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetProperty("time", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public float value {
            get {
                return (float)objectReference.GetType()
                    .GetProperty("value", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetProperty("value", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }


        public float inTangent {
            get {
                return (float)objectReference.GetType()
                    .GetProperty("inTangent", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetProperty("inTangent", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public float outTangent {
            get {
                return (float)objectReference.GetType()
                    .GetProperty("outTangent", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetProperty("outTangent", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public float inWeight {
            get {
                return (float)objectReference.GetType()
                    .GetProperty("inWeight", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetProperty("inWeight", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public float outWeight {
            get {
                return (float)objectReference.GetType()
                    .GetProperty("outWeight", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetProperty("outWeight", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public WeightedMode weightedMode {
            get {
                return (WeightedMode)objectReference.GetType()
                    .GetProperty("weightedMode", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetProperty("weightedMode", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public object curve {
            get {
                return objectReference.GetType()
                    .GetProperty("curve", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
            set {
                objectReference.GetType()
                    .GetProperty("curve", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public int GetHash() {
            return (int)objectReference.GetType()
                    .GetMethod("GetHash", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .Invoke(objectReference, new object[0]);
        }

    }

}
