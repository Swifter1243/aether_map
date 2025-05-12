using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.Reflection;

namespace AnimationCurveManipulationTool {

    public class AnimationWindowBinding {

        public static AnimationWindowBinding Get() {
            var window = GetCurrentWindow();
            if (window == null) return null;
            return new AnimationWindowBinding(window);
        }

        private static EditorWindow GetCurrentWindow() {
            var windowType = ReflectionUtility.unityEditorAssembly.GetType("UnityEditor.AnimationWindow");
            var windows = (EditorWindow[])Resources.FindObjectsOfTypeAll(windowType);
            if (windows.Length == 0) {
                //return EditorWindow.GetWindow(windowType);
                return null;
            }
            else {
                EditorWindow focusedWindow = EditorWindow.focusedWindow;
                if (focusedWindow != null && focusedWindow.GetType() == windowType) {
                    return focusedWindow;
                }
                else {
                    //windows[0].ShowTab();
                    return windows[0];
                }
            }
        }

        private object objectReference;

        public AnimationWindowBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        private AnimEditorBinding m_animEditor;
        public AnimEditorBinding animEditor {
            get {
                if (m_animEditor == null) {
                    var field = objectReference.GetType().GetField("m_AnimEditor", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                    m_animEditor = new AnimEditorBinding(field.GetValue(objectReference));
                }
                return m_animEditor;
            }
        }

    }

}