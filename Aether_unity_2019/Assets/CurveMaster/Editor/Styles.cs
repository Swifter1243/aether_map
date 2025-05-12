using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public static class Styles {

        private static GUIStyle m_groupBox;
        public static GUIStyle groupBox {
            get {
                if (m_groupBox == null) {
                    m_groupBox = new GUIStyle("GroupBox");
                }
                return m_groupBox;
            }
        }


        private static GUIStyle m_outlinedBoxStyle;
        public static GUIStyle outlinedBoxStyle {
            get {
                if (m_outlinedBoxStyle == null) {
                    m_outlinedBoxStyle = new GUIStyle("DD Background");
                }
                return m_outlinedBoxStyle;
            }
        }

        private static GUIStyle m_frameBoxStyle;
        public static GUIStyle frameBoxStyle {
            get {
                if (m_frameBoxStyle == null) {
                    m_frameBoxStyle = new GUIStyle("FrameBox");
                }
                return m_frameBoxStyle;
            }
        }

        private static GUIStyle m_shadowBGStyle;
        public static GUIStyle shadowBGStyle {
            get {
                if (m_shadowBGStyle == null) {
                    m_shadowBGStyle = new GUIStyle("ProjectBrowserTextureIconDropShadow");
                }
                return m_shadowBGStyle;
            }
        }


        private static GUIStyle m_titleBox;
        public static GUIStyle titleBox {
            get {
                if (m_titleBox == null) {
                    m_titleBox = new GUIStyle("OL Title");
                }
                return m_titleBox;
            }
        }

        private static GUIStyle m_tabUnselected;
        public static GUIStyle tabUnselected {
            get {
                if (m_tabUnselected == null) {
                    m_tabUnselected = new GUIStyle("Tab middle");
                    m_tabUnselected.padding = new RectOffset(5, 5, 0, 0);
                    m_tabUnselected.clipping = TextClipping.Clip;
                    m_tabUnselected.alignment = TextAnchor.MiddleLeft;
                }
                return m_tabUnselected;
            }
        }

        private static GUIStyle m_tabSelected;
        public static GUIStyle tabSelected {
            get {
                if (m_tabSelected == null) {
                    m_tabSelected = new GUIStyle("Tab middle");
                    m_tabSelected.padding = new RectOffset(5, 5, 0, 0);
                    m_tabSelected.clipping = TextClipping.Clip;
                    m_tabSelected.alignment = TextAnchor.MiddleLeft;
                    var lighterTexture = new Texture2D(1, 1);
                    lighterTexture.SetPixel(0, 0, Color.grey);
                    lighterTexture.Apply();
                    m_tabSelected.normal.background = lighterTexture;
                }
                return m_tabSelected;
            }
        }

        private static GUIStyle m_boxBackground;
        public static GUIStyle boxBackground {
            get {
                if (m_boxBackground == null) {
                    m_boxBackground = new GUIStyle("AvatarMappingBox");
                }
                return m_boxBackground;
            }
        }

        private static GUIStyle m_largeText;
        public static GUIStyle largeText {
            get {
                if (m_largeText == null) {
                    m_largeText = new GUIStyle(EditorStyles.boldLabel);
                    m_largeText.fontSize = 30;
                    m_largeText.alignment = TextAnchor.MiddleCenter;
                }
                return m_largeText;
            }
        }

    }

}