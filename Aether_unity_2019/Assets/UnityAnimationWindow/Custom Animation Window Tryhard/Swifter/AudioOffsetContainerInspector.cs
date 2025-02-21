using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

namespace UnityAnimationWindow.Swifter
{
    [CustomEditor(typeof (AudioOffsetContainer))]
    public class AudioOffsetContainerInspector : Editor
    {
        public override void OnInspectorGUI() {
            GUILayout.Label("This component exists to store data about audio timings.");
        }
    }
}