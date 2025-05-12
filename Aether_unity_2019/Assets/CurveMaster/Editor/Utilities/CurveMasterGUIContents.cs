using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AnimationCurveManipulationTool {
    public static class CurveMasterGUIContents {

        private static GUIContent m_gearIcon;
        private static GUIContent m_addPropIcon;
        private static GUIContent m_alignIcon;
        private static GUIContent m_mirrorIcon;
        private static GUIContent m_offsetIcon;
        private static GUIContent m_offsetPlusIcon;
        private static GUIContent m_reverseIcon;
        private static GUIContent m_setKeyIcon;

        private static GUIContent m_addPropLabel;
        private static GUIContent m_alignLabel;
        private static GUIContent m_mirrorLabel;
        private static GUIContent m_offsetLabel;
        private static GUIContent m_offsetPlusLabel;
        private static GUIContent m_reverseLabel;
        private static GUIContent m_setKeyLabel;

        public static GUIContent gearIcon {
            get {
                if (m_gearIcon == null) {
                    m_gearIcon = new GUIContent(CurveMasterIcons.gear, "Settings");
                }
                return m_gearIcon;
            }
        }


        public static GUIContent addPropIcon {
            get {
                if (m_addPropIcon == null) {
                    m_addPropIcon = new GUIContent(CurveMasterIcons.addProp, "Add Properties:\nAdd properties from selected object to current animation clip with existing value.");
                }
                return m_addPropIcon;
            }
        }
        public static GUIContent addPropLabel {
            get {
                if (m_addPropLabel == null) {
                    m_addPropLabel = new GUIContent("Add Prop", "Add properties from selected object to current animation clip with existing value.");
                }
                return m_addPropLabel;
            }
        }

        public static GUIContent alignIcon {
            get {
                if (m_alignIcon == null) {
                    m_alignIcon = new GUIContent(CurveMasterIcons.align, "Align:\nMove the selected keyframes into current time. Select at least 1 keyframe.");
                }
                return m_alignIcon;
            }
        }
        public static GUIContent alignLabel {
            get {
                if (m_alignLabel == null) {
                    m_alignLabel = new GUIContent("Align", "Move the selected keyframes into current time. Select at least 1 keyframe.");
                }
                return m_alignLabel;
            }
        }

        public static GUIContent mirrorIcon {
            get {
                if (m_mirrorIcon == null) {
                    m_mirrorIcon = new GUIContent(CurveMasterIcons.mirror, "Mirror:\nDuplicate selected keyframes and reverse the time. Select at least 1 keyframe.");
                }
                return m_mirrorIcon;
            }
        }
        public static GUIContent mirrorLabel {
            get {
                if (m_mirrorLabel == null) {
                    m_mirrorLabel = new GUIContent("Mirror", "Duplicate selected keyframes and reverse the time. Select at least 1 keyframe.");
                }
                return m_mirrorLabel;
            }
        }

        public static GUIContent offsetIcon {
            get {
                if (m_offsetIcon == null) {
                    m_offsetIcon = new GUIContent(CurveMasterIcons.offset, "Offset:\nOffset selected keyframes on each object. Select at least 2 keyframes.");
                }
                return m_offsetIcon;
            }
        }
        public static GUIContent offsetLabel {
            get {
                if (m_offsetLabel == null) {
                    m_offsetLabel = new GUIContent("Offset", "Offset selected keyframes on each object. Select at least 2 keyframes.");
                }
                return m_offsetLabel;
            }
        }

        public static GUIContent offsetPlusIcon {
            get {
                if (m_offsetPlusIcon == null) {
                    m_offsetPlusIcon = new GUIContent(CurveMasterIcons.offsetPlus, "Offset Plus:\nOffset selected keyframes on each sub-property. Select at least 2 keyframes.");
                }
                return m_offsetPlusIcon;
            }
        }
        public static GUIContent offsetPlusLabel {
            get {
                if (m_offsetPlusLabel == null) {
                    m_offsetPlusLabel = new GUIContent("Offset+", "Offset selected keyframes on each sub-property. Select at least 2 keyframes.");
                }
                return m_offsetPlusLabel;
            }
        }

        public static GUIContent reverseIcon {
            get {
                if (m_reverseIcon == null) {
                    m_reverseIcon = new GUIContent(CurveMasterIcons.reverse, "Reverse:\nReverse the value of selected keyframes. Select at least 2 keyframes.");
                }
                return m_reverseIcon;
            }
        }
        public static GUIContent reverseLabel {
            get {
                if (m_reverseLabel == null) {
                    m_reverseLabel = new GUIContent("Reverse", "Reverse the value of selected keyframes. Select at least 2 keyframes.");
                }
                return m_reverseLabel;
            }
        }

        public static GUIContent setKeyIcon {
            get {
                if (m_setKeyIcon == null) {
                    m_setKeyIcon = new GUIContent(CurveMasterIcons.setKey, "Set Key:\nSet multiple keyframe properties to custom value.");
                }
                return m_setKeyIcon;
            }
        }
        public static GUIContent setKeyLabel {
            get {
                if (m_setKeyLabel == null) {
                    m_setKeyLabel = new GUIContent("Set Key", "Set multiple keyframe properties to custom value.");
                }
                return m_setKeyLabel;
            }
        }

    }
}