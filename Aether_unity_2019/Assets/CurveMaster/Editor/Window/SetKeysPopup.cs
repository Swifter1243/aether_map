using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public class SetKeysPopup : PopupWindowContent {

        public enum Mode {
            Fixed,
            AbsoluteRandom,
            RelativeRandom
        }

        private static Mode mode = 0;
        private static float fixedValue = 0;
        private static float minValue = 0;
        private static float maxValue = 0;

        private Color selectedButtonColor = new Color(0.8f, 0.8f, 1f);
        private Color unselectedButtonColor = new Color(0.8f, 0.8f, 0.8f);

        public static void Show() {
            var popup = new SetKeysPopup();
            PopupWindow.Show(new Rect(Event.current.mousePosition, Vector2.zero), popup);
        }

        public override Vector2 GetWindowSize() {
            return new Vector2(258, 80);
        }

        public override void OnGUI(Rect rect) {
            var modeRect = new Rect(rect.x + 8, rect.y + 8, rect.width - 16, EditorGUIUtility.singleLineHeight);
            var buttonToggleRect = new Rect(modeRect.x, modeRect.y, modeRect.width / 3f, modeRect.height);
            var guiColor = GUI.color;
            GUI.color = mode == Mode.Fixed ? selectedButtonColor : unselectedButtonColor; 
            if (GUI.Button(buttonToggleRect, new GUIContent("Fixed", "Fixed:\nSet multiple keyframe properties with a fixed value."), EditorStyles.miniButtonLeft)) {
                mode = Mode.Fixed;
            }
            buttonToggleRect.x += buttonToggleRect.width;
            GUI.color = mode == Mode.AbsoluteRandom ? selectedButtonColor : unselectedButtonColor;
            if (GUI.Button(buttonToggleRect, new GUIContent("Absolute R.", "Absolute Random:\nSet each keyframe property with a random value within range."), EditorStyles.miniButtonMid)) {
                mode = Mode.AbsoluteRandom;
            }
            buttonToggleRect.x += buttonToggleRect.width;
            GUI.color = mode == Mode.RelativeRandom ? selectedButtonColor : unselectedButtonColor;
            if (GUI.Button(buttonToggleRect, new GUIContent("Relative R.", "Relative Random:\nAdd each keyframe property's current value with a random value within range."), EditorStyles.miniButtonRight)) {
                mode = Mode.RelativeRandom;
            }
            GUI.color = guiColor;

            float labelWidth = EditorGUIUtility.labelWidth;
            var valueRect = new Rect(rect.x + 8, modeRect.y + modeRect.height + 8, rect.width - 16, EditorGUIUtility.singleLineHeight);
            if (mode == Mode.Fixed) {
                EditorGUIUtility.labelWidth = 70f;
                fixedValue = EditorGUI.FloatField(valueRect, "Value", fixedValue);
                EditorGUIUtility.labelWidth = labelWidth;
            }
            else {
                EditorGUIUtility.labelWidth = 30f;
                var halfValueRect = new Rect(valueRect.x, valueRect.y, valueRect.width / 2f - 5, valueRect.height);
                minValue = EditorGUI.FloatField(halfValueRect, "Min", minValue);
                halfValueRect.x += halfValueRect.width + 10;
                maxValue = EditorGUI.FloatField(halfValueRect, "Max", maxValue);
                EditorGUIUtility.labelWidth = labelWidth;
            }

            var confirmRect = new Rect(rect.xMax - 88f, valueRect.yMax + 2, 80f, EditorGUIUtility.singleLineHeight);
            if (GUI.Button(confirmRect, "Confirm")) {
                editorWindow.Close();
                SetKeys();
            }
        }

        private void SetKeys() {
            var animationWindow = AnimationWindowBinding.Get();
            if (animationWindow == null) return;
            var animEditor = animationWindow.animEditor;
            if (animEditor == null) return;

            System.Func<float> valueGetter;
            if (mode == Mode.Fixed) {
                valueGetter = () => fixedValue;
            }
            else {
                valueGetter = () => Random.Range(minValue, maxValue);
            }

            var state = animEditor.state;
            var activeCurves = state.activeCurves;
            if (activeCurves.Count > 0) {
                state.SetKeysToCurrentTime(activeCurves, valueGetter, mode == Mode.RelativeRandom);
            }
            else {
                var allCurves = state.allCurves;
                state.SetKeysToCurrentTime(allCurves, valueGetter, mode == Mode.RelativeRandom);
            }

            animEditor.SaveChangedCurvesFromCurveEditor();
            animEditor.ownerWindow.Repaint();
        }
    }

}
