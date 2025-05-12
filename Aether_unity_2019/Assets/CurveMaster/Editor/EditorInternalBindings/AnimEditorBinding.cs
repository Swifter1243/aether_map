using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Reflection;
using UnityEditor;

namespace AnimationCurveManipulationTool {

    public class AnimEditorBinding {

        private object objectReference;

        public AnimEditorBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        private CurveEditorBinding m_curveEditor;
        public CurveEditorBinding curveEditor {
            get {
                if (m_curveEditor == null) {
                    var field = objectReference.GetType().GetField("m_CurveEditor", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                    m_curveEditor = new CurveEditorBinding(field.GetValue(objectReference));
                }
                return m_curveEditor;
            }
        }

        private EditorWindow m_ownerWindow;
        public EditorWindow ownerWindow {
            get {
                if (m_ownerWindow == null) {
                    var field = objectReference.GetType().GetField("m_OwnerWindow", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                    m_ownerWindow = (EditorWindow)field.GetValue(objectReference);
                }
                return m_ownerWindow;
            }
        }

        private AnimationWindowStateBinding m_state;
        public AnimationWindowStateBinding state {
            get {
                if (m_state == null) {
                    var field = objectReference.GetType().GetField("m_State", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                    var obj = field.GetValue(objectReference);
                    if (obj != null) {
                        m_state = new AnimationWindowStateBinding(obj);
                    }
                    else {
                        return null;
                    }
                }
                return m_state;
            }
        }

        public void UpdateSelectedKeysFromCurveEditor() {
            objectReference.GetType().GetMethod("UpdateSelectedKeysFromCurveEditor", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { });
        }

        public void UpdateSelectedKeysToCurveEditor() {
            objectReference.GetType().GetMethod("UpdateSelectedKeysToCurveEditor", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { });
        }

        public void SaveChangedCurvesFromCurveEditor() {
            objectReference.GetType().GetMethod("SaveChangedCurvesFromCurveEditor", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { });
        }

        public void SaveCurveEditorKeySelection() {
            objectReference.GetType().GetMethod("SaveCurveEditorKeySelection", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(objectReference, new object[] { });
        }

    }

}
