using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public static class CurveMasterIcons {

        private static Texture m_addProp;
        private static Texture m_align;
        private static Texture m_gear;
        private static Texture m_mirror;
        private static Texture m_offset;
        private static Texture m_offsetPlus;
        private static Texture m_reverse;
        private static Texture m_setKey;
        private static Texture m_logo;


        public static Texture addProp {
            get {
                if (m_addProp == null) {
                    m_addProp = Resources.Load("CurveMaster_Icons/Icon_AddProp") as Texture;
                }
                return m_addProp;
            }
        }

        public static Texture align {
            get {
                if (m_align == null) {
                    m_align = Resources.Load("CurveMaster_Icons/Icon_Align") as Texture;
                }
                return m_align;
            }
        }

        public static Texture gear {
            get {
                if (m_gear == null) {
                    m_gear = Resources.Load("CurveMaster_Icons/Icon_Gear") as Texture;
                }
                return m_gear;
            }
        }

        public static Texture mirror {
            get {
                if (m_mirror == null) {
                    m_mirror = Resources.Load("CurveMaster_Icons/Icon_Mirror") as Texture;
                }
                return m_mirror;
            }
        }

        public static Texture offset {
            get {
                if (m_offset == null) {
                    m_offset = Resources.Load("CurveMaster_Icons/Icon_Offset") as Texture;
                }
                return m_offset;
            }
        }

        public static Texture reverse {
            get {
                if (m_reverse == null) {
                    m_reverse = Resources.Load("CurveMaster_Icons/Icon_Reverse") as Texture;
                }
                return m_reverse;
            }
        }

        public static Texture offsetPlus {
            get {
                if (m_offsetPlus == null) {
                    m_offsetPlus = Resources.Load("CurveMaster_Icons/Icon_OffsetPlus") as Texture;
                }
                return m_offsetPlus;
            }
        }

        public static Texture setKey {
            get {
                if (m_setKey == null) {
                    m_setKey = Resources.Load("CurveMaster_Icons/Icon_SetKey") as Texture;
                }
                return m_setKey;
            }
        }

        public static Texture logo {
            get {
                if (m_logo == null) {
                    m_logo = Resources.Load("CurveMaster_Icons/Logo") as Texture;
                }
                return m_logo;
            }
        }

    }

}