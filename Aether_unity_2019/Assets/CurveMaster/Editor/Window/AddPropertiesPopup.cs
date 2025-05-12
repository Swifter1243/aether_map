using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public static class AddPropertiesPopup {

        public static void Show() {
            var animationWindow = AnimationWindowBinding.Get();
            if (animationWindow == null) return;
            var animEditor = animationWindow.animEditor;
            if (animEditor == null) return;

            var state = animEditor.state;
            var activeClip = state.activeAnimationClip;
            if (activeClip == null) return;
            var rootGameObject = state.activeRootGameObject;
            if (rootGameObject == null) return;

            var selectedGameObjects = Selection.gameObjects.Where(_gameObject => IsChildOf(_gameObject.transform, rootGameObject.transform)).ToList();
            if (selectedGameObjects.Count == 0) {
                Debug.Log("Please select at least 1 child GameObject of " + rootGameObject.name + ".");
                return;
            }

            var currentTime = state.currentTime;

            GenericMenu menu = new GenericMenu();
            menu.AddItem(new GUIContent("Position"), false, () => {
                PerformAddProperties(animEditor, selectedGameObjects, rootGameObject, (_gameObject, _bindingDict) => {
                    AddPositionCurve(activeClip, currentTime, _gameObject, _bindingDict);
                });
            });
            menu.AddItem(new GUIContent("Rotation"), false, () => {
                PerformAddProperties(animEditor, selectedGameObjects, rootGameObject, (_gameObject, _bindingDict) => {
                    AddRotationCurve(activeClip, currentTime, _gameObject, _bindingDict);
                });
            });
            menu.AddItem(new GUIContent("Scale"), false, () => {
                PerformAddProperties(animEditor, selectedGameObjects, rootGameObject, (_gameObject, _bindingDict) => {
                    AddScaleCurve(activeClip, currentTime, _gameObject, _bindingDict);
                });
            });
            menu.AddItem(new GUIContent("Transform"), false, () => {
                PerformAddProperties(animEditor, selectedGameObjects, rootGameObject, (_gameObject, _bindingDict) => {
                    AddPositionCurve(activeClip, currentTime, _gameObject, _bindingDict);
                    AddRotationCurve(activeClip, currentTime, _gameObject, _bindingDict);
                    AddScaleCurve(activeClip, currentTime, _gameObject, _bindingDict);
                });
            });
            menu.AddItem(new GUIContent("Blendshape"), false, () => {
                PerformAddProperties(animEditor, selectedGameObjects, rootGameObject, (_gameObject, _bindingDict) => {
                    AddBlendshapeCurve(activeClip, currentTime, _gameObject, _bindingDict);
                });
            });
            menu.ShowAsContext();
        }

        private static bool IsChildOf(Transform _child, Transform _parent) {
            Transform currentTransform = _child.parent;
            while (currentTransform != null) {
                if (currentTransform == _parent) {
                    return true;
                }
                currentTransform = currentTransform.parent;
            }
            return false;
        }

        private static void PerformAddProperties(AnimEditorBinding _animEditor, List<GameObject> _gameObjects, GameObject _rootGameObject, System.Action<GameObject, Dictionary<System.Type, List<EditorCurveBinding>>> _handler) {
            var clip = _animEditor.state.activeAnimationClip;
            Undo.RecordObject(clip, "add properties");

            foreach (var go in _gameObjects) {
                var bindingDict = new Dictionary<System.Type, List<EditorCurveBinding>>();
                EditorCurveBinding[] allCurveBindings = AnimationUtility.GetAnimatableBindings(go, _rootGameObject);
                foreach (var curveBinding in allCurveBindings) {
                    if (!bindingDict.TryGetValue(curveBinding.type, out var bindingList)) {
                        bindingList = new List<EditorCurveBinding>();
                        bindingDict.Add(curveBinding.type, bindingList);
                    }
                    bindingList.Add(curveBinding);
                }
                _handler.Invoke(go, bindingDict);
            }
            _animEditor.SaveChangedCurvesFromCurveEditor();
            EditorUtility.SetDirty(clip);
            _animEditor.ownerWindow.Repaint();
        }



        private static void AddPositionCurve(AnimationClip _activeClip, float _time, GameObject _gameObject, Dictionary<System.Type, List<EditorCurveBinding>> _bindingDict) {
            if (_bindingDict.TryGetValue(typeof(Transform), out var transformBindings)) {
                AnimationCurve posXCurve = new AnimationCurve();
                AnimationCurve posYCurve = new AnimationCurve();
                AnimationCurve posZCurve = new AnimationCurve();

                var localPosition = _gameObject.transform.localPosition;

                posXCurve.AddKey(_time, localPosition.x);
                posYCurve.AddKey(_time, localPosition.y);
                posZCurve.AddKey(_time, localPosition.z);

                var posXBinding = transformBindings.Find(_binding => _binding.propertyName == "m_LocalPosition.x");
                var posYBinding = transformBindings.Find(_binding => _binding.propertyName == "m_LocalPosition.y");
                var posZBinding = transformBindings.Find(_binding => _binding.propertyName == "m_LocalPosition.z");

                if (AnimationUtility.GetEditorCurve(_activeClip, posXBinding) == null) {
                    AnimationUtility.SetEditorCurve(_activeClip, posXBinding, posXCurve);
                }
                if (AnimationUtility.GetEditorCurve(_activeClip, posYBinding) == null) {
                    AnimationUtility.SetEditorCurve(_activeClip, posYBinding, posYCurve);
                }
                if (AnimationUtility.GetEditorCurve(_activeClip, posZBinding) == null) {
                    AnimationUtility.SetEditorCurve(_activeClip, posZBinding, posZCurve);
                }
            }
        }

        private static void AddRotationCurve(AnimationClip _activeClip, float _time, GameObject _gameObject, Dictionary<System.Type, List<EditorCurveBinding>> _bindingDict) {
            if (_bindingDict.TryGetValue(typeof(Transform), out var transformBindings)) {
                AnimationCurve rotXCurve = new AnimationCurve();
                AnimationCurve rotYCurve = new AnimationCurve();
                AnimationCurve rotZCurve = new AnimationCurve();

                var localRotation = _gameObject.transform.localRotation.eulerAngles;

                rotXCurve.AddKey(_time, localRotation.x);
                rotYCurve.AddKey(_time, localRotation.y);
                rotZCurve.AddKey(_time, localRotation.z);

                string path = transformBindings[0].path;

                var m_LocalRotationXBinding = EditorCurveBinding.FloatCurve(path, typeof(Transform), "m_LocalRotation.x");
                var localEulerAnglesBakedXBinding = EditorCurveBinding.FloatCurve(path, typeof(Transform), "localEulerAnglesBaked.x");
                var localEulerAnglesRawXBinding = EditorCurveBinding.FloatCurve(path, typeof(Transform), "localEulerAnglesRaw.x");
                var localEulerAnglesXBinding = EditorCurveBinding.FloatCurve(path, typeof(Transform), "localEulerAngles.x");

                if (AnimationUtility.GetEditorCurve(_activeClip, m_LocalRotationXBinding) == null &&
                    AnimationUtility.GetEditorCurve(_activeClip, localEulerAnglesBakedXBinding) == null &&
                    AnimationUtility.GetEditorCurve(_activeClip, localEulerAnglesRawXBinding) == null &&
                    AnimationUtility.GetEditorCurve(_activeClip, localEulerAnglesXBinding) == null) {

                    var localEulerAnglesRawYBinding = EditorCurveBinding.FloatCurve(path, typeof(Transform), "localEulerAnglesRaw.y");
                    var localEulerAnglesRawZBinding = EditorCurveBinding.FloatCurve(path, typeof(Transform), "localEulerAnglesRaw.z");

                    AnimationUtility.SetEditorCurve(_activeClip, localEulerAnglesRawXBinding, rotXCurve);

                    if (AnimationUtility.GetEditorCurve(_activeClip, localEulerAnglesRawYBinding) == null) {
                        AnimationUtility.SetEditorCurve(_activeClip, localEulerAnglesRawYBinding, rotYCurve);
                    }
                    if (AnimationUtility.GetEditorCurve(_activeClip, localEulerAnglesRawZBinding) == null) {
                        AnimationUtility.SetEditorCurve(_activeClip, localEulerAnglesRawZBinding, rotZCurve);
                    }
                }
            }
        }

        private static void AddScaleCurve(AnimationClip _activeClip, float _time, GameObject _gameObject, Dictionary<System.Type, List<EditorCurveBinding>> _bindingDict) {
            if (_bindingDict.TryGetValue(typeof(Transform), out var transformBindings)) {
                AnimationCurve scaleXCurve = new AnimationCurve();
                AnimationCurve scaleYCurve = new AnimationCurve();
                AnimationCurve scaleZCurve = new AnimationCurve();

                var localScale = _gameObject.transform.localScale;

                scaleXCurve.AddKey(_time, localScale.x);
                scaleYCurve.AddKey(_time, localScale.y);
                scaleZCurve.AddKey(_time, localScale.z);

                var scaleXBinding = transformBindings.Find(_binding => _binding.propertyName == "m_LocalScale.x");
                var scaleYBinding = transformBindings.Find(_binding => _binding.propertyName == "m_LocalScale.y");
                var scaleZBinding = transformBindings.Find(_binding => _binding.propertyName == "m_LocalScale.z");

                if (AnimationUtility.GetEditorCurve(_activeClip, scaleXBinding) == null) {
                    AnimationUtility.SetEditorCurve(_activeClip, scaleXBinding, scaleXCurve);
                }
                if (AnimationUtility.GetEditorCurve(_activeClip, scaleYBinding) == null) {
                    AnimationUtility.SetEditorCurve(_activeClip, scaleYBinding, scaleYCurve);
                }
                if (AnimationUtility.GetEditorCurve(_activeClip, scaleZBinding) == null) {
                    AnimationUtility.SetEditorCurve(_activeClip, scaleZBinding, scaleZCurve);
                }
            }
        }

        private static void AddBlendshapeCurve(AnimationClip _activeClip, float _time, GameObject _gameObject, Dictionary<System.Type, List<EditorCurveBinding>> _bindingDict) {
            if (_bindingDict.TryGetValue(typeof(SkinnedMeshRenderer), out var transformBindings)) {
                var renderer = _gameObject.GetComponent<SkinnedMeshRenderer>();
                var mesh = renderer.sharedMesh;
                if (mesh == null) return;

                var blendShapeBindings = new List<EditorCurveBinding>();
                foreach (var binding in transformBindings) {
                    var splits = binding.propertyName.Split('.');
                    if (splits.Length > 0 && splits[0] == "blendShape") {
                        blendShapeBindings.Add(binding);
                    }
                }

                var blendShapeDict = new Dictionary<string, EditorCurveBinding>();
                foreach (var binding in blendShapeBindings) {
                    var blendShapeName = binding.propertyName.Substring(11, binding.propertyName.Length - 11);
                    blendShapeDict.Add(blendShapeName, binding);
                }

                int blendShapeCount = mesh.blendShapeCount;
                for (int i = 0; i < blendShapeCount; i++) {
                    var blendShapeName = mesh.GetBlendShapeName(i);
                    if (blendShapeDict.TryGetValue(blendShapeName, out var binding)) {
                        AnimationCurve blendShapeCurve = new AnimationCurve();
                        blendShapeCurve.AddKey(_time, renderer.GetBlendShapeWeight(i));
                        if (AnimationUtility.GetEditorCurve(_activeClip, binding) == null) {
                            AnimationUtility.SetEditorCurve(_activeClip, binding, blendShapeCurve);
                        }
                    }
                }

            }
        }


    }

}
