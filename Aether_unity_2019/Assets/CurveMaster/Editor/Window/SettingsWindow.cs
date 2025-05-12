using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace AnimationCurveManipulationTool {
    public class SettingsWindow : EditorWindow {

        private string version = "v1.1.1";
        private string docsLink = "https://to.yan-k.tv/CMDocs";
        private string supportLink = "https://to.yan-k.tv/DCnekolab";

        public static void OpenWindow() {
            var window = GetWindow<SettingsWindow>();
            window.titleContent.text = "Curve Master Settings";
            window.minSize = new Vector2(282, 348);
            window.maxSize = new Vector2(282, 348);
            window.ShowAuxWindow();
        }

        private Color selectedButtonColor = new Color(0.8f, 0.8f, 1f);
        private Color unselectedButtonColor = new Color(0.8f, 0.8f, 0.8f);

        private GUIStyle m_whiteText;
        private GUIStyle whiteText {
            get {
                if (m_whiteText == null) {
                    m_whiteText = new GUIStyle();
                    m_whiteText.normal.textColor = Color.white;
                    m_whiteText.alignment = TextAnchor.MiddleCenter;
                    m_whiteText.fontSize = 20;
                }
                return m_whiteText;
            }
        }

        private GUIStyle m_buttonLeft;
        private GUIStyle m_buttonRight;

        private GUIStyle buttonLeft {
            get {
                if (m_buttonLeft == null) {
                    m_buttonLeft = new GUIStyle(EditorStyles.miniButtonLeft);
                    m_buttonLeft.fixedHeight = 35f;
                }
                return m_buttonLeft;
            }
        }

        private GUIStyle buttonRight {
            get {
                if (m_buttonRight == null) {
                    m_buttonRight = new GUIStyle(EditorStyles.miniButtonRight);
                    m_buttonRight.fixedHeight = 35f;
                }
                return m_buttonRight;
            }
        }

        private void OnGUI() {
            DrawUpperLogo();
            DrawTitleVersion();

            var config = AnimationCurveManipulationConfig.Get();
            DrawCurvePositionField(config);
            DrawAutoApplyField(config);
            DrawButtonDisplayField(config);

            GUILayout.Space(5);
            bool useCustomSelectionOrder = EditorGUILayout.ToggleLeft(
                new GUIContent("Use Custom Selection Order", "Custom Selection Order is used only for Offset and Offset+. By default, selection is ordered from top to bottom. By turning this on, it allows us to select in our preferred order using mouse click. But note that this might be expensive when many amounts of keyframes are being used."),
                config.useCustomSelectionOrder);
            if (useCustomSelectionOrder != config.useCustomSelectionOrder) {
                ChangeConfig(config, () => {
                    config.useCustomSelectionOrder = useCustomSelectionOrder;
                });
                if (useCustomSelectionOrder) GetWindow<AnimationCurveManipulationWindow>().EnableFrameUpdate();
                else GetWindow<AnimationCurveManipulationWindow>().DisableFrameUpdate();
            }

            GUILayout.Space(10);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Docs", buttonLeft, GUILayout.Width(137))) {
                Application.OpenURL(docsLink);
            }
            if (GUILayout.Button("Support", buttonRight, GUILayout.Width(137))) {
                Application.OpenURL(supportLink);
            }
            GUILayout.EndHorizontal();

            var e = Event.current;
            if (e.type == EventType.ValidateCommand) {
                if (e.commandName == "UndoRedoPerformed") {
                    Repaint();
                }
            }
        }

        private void DrawUpperLogo() {
            var upperArea = EditorGUILayout.GetControlRect(GUILayout.Width(282), GUILayout.Height(157));
            var boxArea = new Rect(upperArea.x, upperArea.y + 2, 276, 153);
            var logoArea = new Rect(boxArea.x + 10, boxArea.y, boxArea.width - 20, 120);
            var textArea = new Rect(logoArea.x, logoArea.y + logoArea.height, logoArea.width, boxArea.height - logoArea.height);

            var guiColor = GUI.color;
            GUI.color = new Color(0.2f, 0.2f, 0.2f, 1);
            GUI.DrawTexture(boxArea, EditorGUIUtility.whiteTexture);
            GUI.color = guiColor;
            GUI.DrawTexture(logoArea, CurveMasterIcons.logo, ScaleMode.ScaleToFit);
            GUI.Label(textArea, "Curve Master", whiteText);
        }

        private void DrawTitleVersion() {
            EditorGUILayout.Space();
            GUILayout.Label("Curve Master", EditorStyles.boldLabel);
            var guiColor = GUI.color;
            GUI.color = new Color(0.5f, 0.5f, 0.5f, 1);
            GUILayout.Label(version, EditorStyles.miniLabel);
            var lineRect = EditorGUILayout.GetControlRect(GUILayout.ExpandWidth(true), GUILayout.Height(1));
            GUI.DrawTexture(lineRect, EditorGUIUtility.whiteTexture);
            GUI.color = guiColor;
            EditorGUILayout.Space();
        }

        private void DrawCurvePositionField(AnimationCurveManipulationConfig _config) {
            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Curve Position", GUILayout.Width(100));
            var guiBacgroundColor = GUI.backgroundColor;
            GUI.backgroundColor = _config.curvePositionRight ? unselectedButtonColor : selectedButtonColor;
            if (GUILayout.Button("Left", EditorStyles.miniButtonLeft, GUILayout.Width(90))) {
                ChangeConfig(_config, () => _config.curvePositionRight = false);
                GetWindow<AnimationCurveManipulationWindow>().Repaint();
            }
            GUI.backgroundColor = _config.curvePositionRight ? selectedButtonColor : unselectedButtonColor;
            if (GUILayout.Button("Right", EditorStyles.miniButtonRight)) {
                ChangeConfig(_config, () => _config.curvePositionRight = true);
                GetWindow<AnimationCurveManipulationWindow>().Repaint();
            }
            GUI.backgroundColor = guiBacgroundColor;
            GUILayout.EndHorizontal();
        }
        private void DrawAutoApplyField(AnimationCurveManipulationConfig _config) {
            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Auto Apply", GUILayout.Width(100));
            var guiBacgroundColor = GUI.backgroundColor;
            GUI.backgroundColor = _config.autoApply ? selectedButtonColor : unselectedButtonColor;
            if (GUILayout.Button("On", EditorStyles.miniButtonLeft, GUILayout.Width(90))) {
                ChangeConfig(_config, () => _config.autoApply = true);
                Focus();
            }
            GUI.backgroundColor = _config.autoApply ? unselectedButtonColor : selectedButtonColor;
            if (GUILayout.Button("Off", EditorStyles.miniButtonRight)) {
                ChangeConfig(_config, () => _config.autoApply = false);
                Focus();
            }
            GUI.backgroundColor = guiBacgroundColor;
            GUILayout.EndHorizontal();
        }
        private void DrawButtonDisplayField(AnimationCurveManipulationConfig _config) {
            GUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Button Display", GUILayout.Width(100));
            var guiBacgroundColor = GUI.backgroundColor;
            GUI.backgroundColor = _config.displayButtonIcon ? selectedButtonColor : unselectedButtonColor;
            if (GUILayout.Button("Icon", EditorStyles.miniButtonLeft, GUILayout.Width(90))) {
                ChangeConfig(_config, () => _config.displayButtonIcon = true);
                GetWindow<AnimationCurveManipulationWindow>().Repaint();
                Focus();
            }
            GUI.backgroundColor = _config.displayButtonIcon ? unselectedButtonColor : selectedButtonColor;
            if (GUILayout.Button("Text", EditorStyles.miniButtonRight)) {
                ChangeConfig(_config, () => _config.displayButtonIcon = false);
                GetWindow<AnimationCurveManipulationWindow>().Repaint();
                Focus();
            }
            GUI.backgroundColor = guiBacgroundColor;
            GUILayout.EndHorizontal();
        }

        private void ChangeConfig(AnimationCurveManipulationConfig _config, System.Action _handler) {
            Undo.RecordObject(_config, "modify config");
            _handler.Invoke();
            EditorUtility.SetDirty(_config);
        }

    }
}
