using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    [System.Serializable]
    public class CurvePreset {

        [SerializeField] private string m_presetName;
        [SerializeField] private float[] m_curveValue = new float[4];

        public string presetName { get => m_presetName; set => m_presetName = value; }
        public float[] curveValue { get => m_curveValue; set => m_curveValue = value; }

        public CurvePreset() {
            m_presetName = "New Curve";
            m_curveValue = new float[4] {
                0.25f, 0.25f, 0.75f, 0.75f
            };
        }

        public CurvePreset(float[] _curveValue) {
            m_presetName = "New Curve";
            m_curveValue = _curveValue;
        }

    }


    [System.Serializable]
    public class CurveLibrary {

        [SerializeField] private string m_libraryName;
        [SerializeField] private string m_guid;
        [SerializeField] private List<CurvePreset> m_curvePresets = new List<CurvePreset>();

        public string libraryName { get => m_libraryName; set => m_libraryName = value; }
        public string guid { get => m_guid; set => m_guid = value; }
        public List<CurvePreset> curvePresets => m_curvePresets;

        public CurveLibrary() {
            m_libraryName = "New Library";
            m_guid = System.Guid.NewGuid().ToString();
        }

        public bool Compare(CurveLibrary _other) {
            if (System.Guid.TryParse(m_guid, out var guid1)) {
                if (System.Guid.TryParse(_other.m_guid, out var guid2)) {
                    return guid1 == guid2;
                }
            }
            return false;
        }

        public string ToJSON() {
            return JsonUtility.ToJson(this, true);
        }

        public static CurveLibrary FromJSON(string _json) {
            return JsonUtility.FromJson<CurveLibrary>(_json);
        }

    }


}
