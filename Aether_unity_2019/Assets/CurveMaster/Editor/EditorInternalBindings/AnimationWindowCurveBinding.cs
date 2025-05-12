using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public class AnimationWindowCurveBinding {

        private object objectReference;

        public AnimationWindowCurveBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        private static System.Type bindedType;
        public static System.Type GetBindedType() {
            if (bindedType == null) {
                bindedType = ReflectionUtility.unityEditorAssembly.GetType("UnityEditorInternal.AnimationWindowCurve");
            }
            return bindedType;
        }

        public object GetObjectReference() { return objectReference; }

        public AnimationClip clip {
            get {
                return (AnimationClip)objectReference.GetType()
                    .GetProperty("clip", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public bool isPPtrCurve {
            get {
                return (bool)objectReference.GetType()
                    .GetProperty("isPPtrCurve", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public int depth {
            get {
                return (int)objectReference.GetType()
                    .GetProperty("depth", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public string propertyName {
            get {
                return (string)objectReference.GetType()
                    .GetProperty("propertyName", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public string path {
            get {
                return (string)objectReference.GetType()
                    .GetProperty("path", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public List<AnimationWindowKeyframeBinding> keyframes {
            get {
                var result = new List<AnimationWindowKeyframeBinding>();
                var field = objectReference.GetType().GetField("m_Keyframes", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                var keyframeList = (IEnumerable)field.GetValue(objectReference);
                foreach (var key in keyframeList) {
                    var keyframe = new AnimationWindowKeyframeBinding(key);
                    result.Add(keyframe);
                }
                return result;
            }
            set {
                var keyframeType = AnimationWindowKeyframeBinding.GetBindedType();
                ICollection curveCollection = (ICollection)Activator.CreateInstance(typeof(List<>).MakeGenericType(keyframeType));
                foreach (var keyframe in value) {
                    // Use reflection to call the Add method on the collectionOfMyType
                    MethodInfo addMethod = curveCollection.GetType().GetMethod("Add");
                    addMethod.Invoke(curveCollection, new[] { keyframe.GetObjectReference() });
                }
            }
        }

        public AnimationCurve ToAnimationCurve() {
            return (AnimationCurve)objectReference.GetType().GetMethod("ToAnimationCurve", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { });
        }

        public void AddKeyframe(AnimationWindowKeyframeBinding _keyframe) {
            var field = objectReference.GetType().GetField("m_Keyframes", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            var keyframeList = (IEnumerable)field.GetValue(objectReference);
            MethodInfo addMethod = keyframeList.GetType().GetMethod("Add");
            addMethod.Invoke(keyframeList, new object[] { _keyframe.GetObjectReference() });
        }

        public bool HasKeyframe(AnimationKeyTimeBinding _time) {
            return (bool)objectReference.GetType().GetMethod("HasKeyframe", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { _time.GetObjectReference() });
        }

        public void RemoveKeyframe(AnimationKeyTimeBinding _time) {
            objectReference.GetType().GetMethod("RemoveKeyframe", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { _time.GetObjectReference() });
        }

        public AnimationWindowKeyframeBinding FindKeyAtTime(AnimationKeyTimeBinding _keyTime) {
            var obj = objectReference.GetType().GetMethod("FindKeyAtTime", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { _keyTime.GetObjectReference() });
            if (obj == null) return null;
            else return new AnimationWindowKeyframeBinding(obj);
        }

    }

}
