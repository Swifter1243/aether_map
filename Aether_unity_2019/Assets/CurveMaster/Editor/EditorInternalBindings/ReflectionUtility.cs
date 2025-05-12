using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace AnimationCurveManipulationTool {
    public static class ReflectionUtility {

        private static Assembly m_unityEditorAssembly;

        public static Assembly unityEditorAssembly {
            get {
                if (m_unityEditorAssembly == null) {
                    m_unityEditorAssembly = Assembly.Load("UnityEditor");
                }
                return m_unityEditorAssembly;
            }
        }

    }

}
