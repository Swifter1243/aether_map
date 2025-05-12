using System.Collections.Generic;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public class AnimationCurveManipulationConfig : ScriptableObject {

#if UNITY_EDITOR
        [SerializeField] internal bool useCustomSelectionOrder = false;
        [SerializeField] internal bool curvePositionRight = false;
        [SerializeField] internal bool autoApply = false;
        [SerializeField] internal bool displayButtonIcon = true;
#endif

        [SerializeField] private List<CurveLibrary> m_curveLibraries = new List<CurveLibrary>();

        public List<CurveLibrary> curveLibraries => m_curveLibraries;


        internal const string k_SettingsResourcePath = "AnimationCurveManipulationConfig";
        internal const string k_SettingsPath = "Assets/Resources/" + k_SettingsResourcePath + ".asset";

        private static AnimationCurveManipulationConfig instance;
        public static AnimationCurveManipulationConfig Get() {
            if (instance == null) {
                instance = Resources.Load(k_SettingsResourcePath) as AnimationCurveManipulationConfig;
#if UNITY_EDITOR
                if (instance == null) {
                    instance = GetOrCreateSettings();
                    Debug.LogWarning("AnimationCurveManipulationConfig not found, and is now being newly created.");
                }
#endif
            }
            return instance;
        }

        public static bool TryGet(out AnimationCurveManipulationConfig _config) {
            _config = Get();
            return _config != null;
        }

#if UNITY_EDITOR

        internal static AnimationCurveManipulationConfig GetOrCreateSettings() {
            var settings = (AnimationCurveManipulationConfig)Resources.Load(k_SettingsResourcePath);
            if (settings == null) {
                settings = ScriptableObject.CreateInstance<AnimationCurveManipulationConfig>();
                if (!System.IO.Directory.Exists(Application.dataPath + "/Resources")) {
                    System.IO.Directory.CreateDirectory(Application.dataPath + "/Resources");
                }
                UnityEditor.AssetDatabase.CreateAsset(settings, k_SettingsPath);
                UnityEditor.AssetDatabase.SaveAssets();
            }
            return settings;
        }

        internal static UnityEditor.SerializedObject GetSerializedSettings() {
            return new UnityEditor.SerializedObject(GetOrCreateSettings());
        }

        internal static bool IsSettingsAvailable() {
            return Resources.Load(k_SettingsResourcePath) != null;
        }
#endif

    }

}