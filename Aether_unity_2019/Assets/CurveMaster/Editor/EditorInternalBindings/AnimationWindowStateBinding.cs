using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public class AnimationWindowStateBinding {

        private object objectReference;

        public AnimationWindowStateBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        public AnimationClip activeAnimationClip {
            get {
                var obj = objectReference.GetType()
                    .GetProperty("activeAnimationClip", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
                if (obj != null) {
                    return (AnimationClip)obj;
                }
                return null;
            }
        }

        public GameObject activeRootGameObject {
            get {
                var obj = objectReference.GetType()
                    .GetProperty("activeRootGameObject", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
                if (obj != null) {
                    return (GameObject)obj;
                }
                return null;
            }
        }

        public bool showCurveEditor {
            get {
                return (bool)objectReference.GetType()
                    .GetField("showCurveEditor", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }

            set {
                objectReference.GetType()
                    .GetField("showCurveEditor", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public float currentTime {
            get {
                return (float)objectReference.GetType()
                    .GetProperty("currentTime", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
            set {
                objectReference.GetType()
                    .GetProperty("currentTime", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }

        public List<AnimationWindowCurveBinding> allCurves {
            get {
                var result = new List<AnimationWindowCurveBinding>();
                var property = objectReference.GetType().GetProperty("allCurves", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                var curveList = (IEnumerable)property.GetValue(objectReference);
                foreach (var curve in curveList) {
                    var keyframe = new AnimationWindowCurveBinding(curve);
                    result.Add(keyframe);
                }
                return result;
            }
        }

        public List<AnimationWindowCurveBinding> activeCurves {
            get {
                var result = new List<AnimationWindowCurveBinding>();
                var property = objectReference.GetType().GetProperty("activeCurves", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                var curveList = (IEnumerable)property.GetValue(objectReference);
                foreach (var curve in curveList) {
                    var keyframe = new AnimationWindowCurveBinding(curve);
                    result.Add(keyframe);
                }
                return result;
            }
        }

        public void ClearSelectedKeysCache() {
            objectReference.GetType().GetField("m_SelectedKeysCache", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, null);
        }

        private HashSet<int> selectedKeyHashes {
            get {
                return (HashSet<int>)objectReference.GetType().GetProperty("selectedKeyHashes", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public void RemoveSelectedKeyHash(int _hash) {
            var keySelection = objectReference.GetType().GetField("m_KeySelection", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            if (keySelection != null) {
                var hashSet = keySelection.GetType().GetField("m_SelectedKeyHashes", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(keySelection);
                if (hashSet is HashSet<int> selectedKeyHashes) {
                    selectedKeyHashes.Remove(_hash);
                }
            }
        }

        public List<AnimationWindowKeyframeBinding> selectedKeys {
            get {
                var result = new List<AnimationWindowKeyframeBinding>();
                var property = objectReference.GetType().GetProperty("selectedKeys", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                var selectedKeyList = (IEnumerable)property.GetValue(objectReference);
                foreach (var key in selectedKeyList) {
                    var keyframe = new AnimationWindowKeyframeBinding(key);
                    result.Add(keyframe);
                }
                return result;
            }
        }

        public void SaveSelectedKeys(string _undoLabel) {
            //foreach (var method in objectReference.GetType().GetMethods(BindingFlags.Instance | BindingFlags.NonPublic)) {
            //    Debug.Log(method.Name);
            //}
            var method = objectReference.GetType().GetMethod("SaveSelectedKeys", BindingFlags.Instance | BindingFlags.NonPublic);
            method.Invoke(objectReference, new object[] { _undoLabel });
        }

        public void SaveKeySelection(string _undoLabel) {
            var method = objectReference.GetType().GetMethod("SaveKeySelection", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            method.Invoke(objectReference, new object[] { _undoLabel });
        }

        public void SaveCurve(AnimationClip _clip, AnimationWindowCurveBinding _curve, string _undoLabel) {
            var method = objectReference.GetType().GetMethods(BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public).Where(_method => {
                return _method.Name == "SaveCurve" && _method.GetParameters().Length == 3;
            }).ToArray()[0];
            method.Invoke(objectReference, new object[] { _clip, _curve.GetObjectReference(), _undoLabel });
        }

        public void SaveCurves(AnimationClip _clip, ICollection<object> _curves, string _undoLabel) {
            var curveType = AnimationWindowCurveBinding.GetBindedType();
            ICollection curveCollection = (ICollection)Activator.CreateInstance(typeof(List<>).MakeGenericType(curveType));
            foreach (object obj in _curves) {
                // Use reflection to call the Add method on the collectionOfMyType
                MethodInfo addMethod = curveCollection.GetType().GetMethod("Add");
                addMethod.Invoke(curveCollection, new[] { obj });
            }
            var method = objectReference.GetType().GetMethod("SaveCurves", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            method.Invoke(objectReference, new object[] { _clip, curveCollection, _undoLabel });
        }

        public void ResampleAnimation() {
            var method = objectReference.GetType().GetMethod("ResampleAnimation", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            method.Invoke(objectReference, new object[0]);
        }

        public void SelectKey(AnimationWindowKeyframeBinding _keyframe) {
            var method = objectReference.GetType().GetMethod("SelectKey", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            method.Invoke(objectReference, new object[] { _keyframe.GetObjectReference() });
        }

        public void UnselectKey(AnimationWindowKeyframeBinding _keyframe) {
            var method = objectReference.GetType().GetMethod("UnselectKey", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            method.Invoke(objectReference, new object[] { _keyframe.GetObjectReference() });
        }

        public void ClearKeySelections() {
            var method = objectReference.GetType().GetMethod("ClearKeySelections", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
            method.Invoke(objectReference, new object[0]);
        }

        public void PasteKeysMirrored() {
            SaveKeySelection("save key selection");
            ClearSelectedKeysCache();
            var keys = selectedKeys;
            //Debug.Log(keys.Count);
            if (keys.Count == 0) {
                ClearSelectedKeysCache();
                return;
            }

            keys.Reverse();
            ClearKeySelections();

            float lastTime = currentTime;

            for (int i=0; i < keys.Count; i++) {
                var lastlyUpdatedKeyframe = keys.Find(_key => _key.GetHash() == keys[i].GetHash());
                if (lastlyUpdatedKeyframe != null) {
                    keys[i] = lastlyUpdatedKeyframe;
                }
                var keyframe = keys[i];
                var newKeyframeInternal = Activator.CreateInstance(AnimationWindowKeyframeBinding.GetBindedType(), keyframe.GetObjectReference());
                var newKeyframe = new AnimationWindowKeyframeBinding(newKeyframeInternal);

                newKeyframe.curve = keyframe.curve;             

                newKeyframe.time = lastTime;
                newKeyframe.inTangent = -keyframe.outTangent;
                newKeyframe.inWeight = keyframe.outWeight;
                newKeyframe.outTangent = -keyframe.inTangent;
                newKeyframe.outWeight = keyframe.inWeight;

                if (i < keys.Count-1) {
                    lastTime += keyframe.time - keys[i + 1].time;
                }

                var curveBinding = new AnimationWindowCurveBinding(newKeyframe.curve);
                //  Only allow pasting of key frame from numerical curves to numerical curves or from pptr curves to pptr curves.
                if ((newKeyframe.time >= 0.0f) && (newKeyframe.curve != null) && (curveBinding.isPPtrCurve == curveBinding.isPPtrCurve)) {
                    if (!curveBinding.HasKeyframe(AnimationKeyTimeBinding.Time(newKeyframe.time, curveBinding.clip.frameRate))) {

                        curveBinding.AddKeyframe(newKeyframe);
                        SelectKey(newKeyframe);
                        SaveCurve(curveBinding.clip, curveBinding, "add keyframe");
                    }
                }
            }

            ResampleAnimation();
        }

        public void SetKeysToCurrentTime(List<AnimationWindowCurveBinding> _curves, Func<float> _valueGetter, bool _additive) {
            float time = currentTime;

            foreach (var curve in _curves) {
                var newKeyframeInternal = Activator.CreateInstance(AnimationWindowKeyframeBinding.GetBindedType());
                var newKeyframe = new AnimationWindowKeyframeBinding(newKeyframeInternal);

                newKeyframe.curve = curve.GetObjectReference();
                var curveBinding = new AnimationWindowCurveBinding(newKeyframe.curve);

                newKeyframe.time = time;
                if (_additive) {
                    var animationCurve = curve.ToAnimationCurve();
                    var currentValue = animationCurve.Evaluate(newKeyframe.time);
                    newKeyframe.value = currentValue + _valueGetter();
                }
                else {
                    newKeyframe.value = _valueGetter();
                }

                //  Only allow pasting of key frame from numerical curves to numerical curves or from pptr curves to pptr curves.
                if ((newKeyframe.time >= 0.0f) && (newKeyframe.curve != null) && (curveBinding.isPPtrCurve == curveBinding.isPPtrCurve)) {

                    if (curveBinding.HasKeyframe(AnimationKeyTimeBinding.Time(newKeyframe.time, curveBinding.clip.frameRate))) {
                        curveBinding.RemoveKeyframe(AnimationKeyTimeBinding.Time(newKeyframe.time, curveBinding.clip.frameRate));
                    }

                    curveBinding.AddKeyframe(newKeyframe);
                    SelectKey(newKeyframe);
                    SaveCurve(curveBinding.clip, curveBinding, "add keyframe");
                }
            }

            ResampleAnimation();
        }

    }

}