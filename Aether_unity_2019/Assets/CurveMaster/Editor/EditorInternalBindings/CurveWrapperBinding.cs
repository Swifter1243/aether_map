using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Reflection;

namespace AnimationCurveManipulationTool {

    public class CurveWrapperBinding {

        private object objectReference;

        public CurveWrapperBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        public bool changed {
            get {
                return (bool)objectReference.GetType()
                    .GetProperty("changed", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
            set {
                objectReference.GetType()
                    .GetProperty("changed", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public AnimationCurve curve {
            get {
                return (AnimationCurve)objectReference.GetType()
                    .GetProperty("curve", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public int keyCount => curve.length;

        public int AddKey(Keyframe _key) {
            return (int)objectReference.GetType()
                    .GetMethod("AddKey", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .Invoke(objectReference, new object[] { _key });
        }

        public int MoveKey(int _index, ref Keyframe _key) {
            return (int)objectReference.GetType()
                    .GetMethod("MoveKey", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .Invoke(objectReference, new object[] { _index, _key });
        }

        public Keyframe GetKeyframe(int index) {
            return curve.keys[index];
        }

    }

}
