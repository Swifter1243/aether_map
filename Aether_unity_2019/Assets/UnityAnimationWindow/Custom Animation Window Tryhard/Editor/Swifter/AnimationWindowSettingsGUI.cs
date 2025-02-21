using UnityAnimationWindow.Swifter;
using UnityEditor;
using UnityEditorInternal.Enemeteen;
using UnityEngine;

[System.Serializable]
class AnimationWindowSettingsGUI
{
    [SerializeField] public AnimationWindowState state;

    private const int IndentWidth = 10;
    private const int EdgeMargin = 5;

    private GUIStyle s_MainTitleStyle => new GUIStyle
    {
        alignment = TextAnchor.MiddleCenter,
        fontStyle = FontStyle.Bold,
        normal =
        {
            textColor = Color.white,
            background = Texture2D.grayTexture
        },
        fixedHeight = 20
    };

    private static GUIContent s_LoopAnimationField =
        new GUIContent("Loop Animation", "Whether to loop the animation when it finishes.");
    private static GUIContent s_PlaybackSpeedField =
        new GUIContent("Playback Speed", "The speed to play back animations in the animation window.");
    private static GUIContent s_PlayFromBeginningField =
        new GUIContent("Play From Beginning", "When playback is started, play the animation from the beginning.");

    private static GUIContent s_AudioEnabledField =
        new GUIContent("Audio Enabled", "Whether to enable audio syncing with the animation.");
    private static GUIContent s_AudioClipField =
        new GUIContent("Audio Clip", "The audio clip to play in sync with the animation.");
    private static GUIContent s_BpmField =
        new GUIContent("BPM", "The beats per minute of the audio.");
    private static GUIContent s_WaveformColorField =
        new GUIContent("Waveform Color", "The color of the waveform for the audio visualization.");

    private static GUIContent s_BpmGuideField =
        new GUIContent("BPM Guide Enabled", "Whether to enable BPM guides.");
    private static GUIContent s_BeatPrecisionField =
        new GUIContent("Beat Precision", "The amount of in-between beats for the BPM guides.");
    private static GUIContent s_GuideColorField =
        new GUIContent("Guide Color", "The color of the BPM guides.");
    private static GUIContent s_BeatLabelsField =
        new GUIContent("Beat Labels", "Whether the BPM guides should be numbered.");
    private static GUIContent s_LatencyCompensationField =
        new GUIContent("Latency Compensation", "Compensate for audio latency in milliseconds.");

    private static GUIContent s_AudioOffsetField =
        new GUIContent("Offset", "How much to offset the audio by (in beats).");

    private float _indent = 0;

    private void IncreaseIndent()
    {
        _indent += IndentWidth;
    }

    private void DecreaseIndent()
    {
        _indent -= IndentWidth;
    }

    private void DoIndent()
    {
        GUILayout.Space(_indent);
    }

    private void BeginHorizontal()
    {
        GUILayout.BeginHorizontal();
        DoIndent();
    }

    private void EndHorizontal()
    {
        GUILayout.Space(EdgeMargin);
        GUILayout.EndHorizontal();
    }

    private void VerticalSpace()
    {
        GUILayout.Space(10);
    }

    public void OnGUI(float hierarchyWidth)
    {
        _indent = EdgeMargin;

        GUILayout.Label("Animation Window Settings", s_MainTitleStyle);

        VerticalSpace();
        BeginHorizontal();
        state.controlInterface.loop = EditorGUILayout.Toggle(s_LoopAnimationField, state.controlInterface.loop);
        EndHorizontal();

        BeginHorizontal();
        state.controlInterface.playbackSpeed = EditorGUILayout.FloatField(s_PlaybackSpeedField, state.controlInterface.playbackSpeed);
        EndHorizontal();

        BeginHorizontal();
        state.controlInterface.playFromBeginning = EditorGUILayout.Toggle(s_PlayFromBeginningField, state.controlInterface.playFromBeginning);
        EndHorizontal();

        AudioControlsState audioControls = state.audioControlsState;
        VerticalSpace();
        BeginHorizontal();
        audioControls.m_isAudioEnabled = EditorGUILayout.Toggle(s_AudioEnabledField, audioControls.m_isAudioEnabled);
        EndHorizontal();

        if (audioControls.m_isAudioEnabled)
        {
            IncreaseIndent();
            AudioControlsOnGUI(audioControls);
            DecreaseIndent();
        }

        if (GUI.changed)
        {
            state.audioControlsState.Save();
        }

        GUILayoutUtility.GetRect(hierarchyWidth, hierarchyWidth, 0f, float.MaxValue, GUILayout.ExpandHeight(true));
    }

    private void AudioControlsOnGUI(AudioControlsState audioControls)
    {
        VerticalSpace();

        BeginHorizontal();
        audioControls.m_audioClip = EditorGUILayout.ObjectField(s_AudioClipField, audioControls.m_audioClip, typeof(AudioClip), false) as AudioClip;
        EndHorizontal();

        BeginHorizontal();
        audioControls.m_waveformColor = EditorGUILayout.ColorField(s_WaveformColorField, audioControls.m_waveformColor);
        EndHorizontal();

        BeginHorizontal();
        audioControls.m_latencyMilliseconds = EditorGUILayout.IntField(s_LatencyCompensationField, audioControls.m_latencyMilliseconds);
        EndHorizontal();

        VerticalSpace();
        BeginHorizontal();
        audioControls.m_bpmGuideEnabled = EditorGUILayout.Toggle(s_BpmGuideField, audioControls.m_bpmGuideEnabled);
        EndHorizontal();

        if (audioControls.m_bpmGuideEnabled)
        {
            IncreaseIndent();
            BPMGuideControlsOnGUI(audioControls);
            DecreaseIndent();
        }

        VerticalSpace();
        AudioOffsetGUI();
    }

    private void AudioOffsetGUI()
    {
        AudioOffsetContainer audioOffsetContainer = state.GetAudioOffsetContainer();

        BeginHorizontal();
        GUILayout.Label("Audio Offset");

        if (audioOffsetContainer)
        {
            if (GUILayout.Button("Remove Audio Offset"))
            {
                state.RemoveAudioOffsetContainer();
            }
            EndHorizontal();

            IncreaseIndent();
            AudioOffsetOptions(audioOffsetContainer);
            DecreaseIndent();
        }
        else
        {
            if (GUILayout.Button("Add Audio Offset"))
            {
                state.AddAudioOffsetContainer();
            }
            EndHorizontal();
        }
    }

    private void AudioOffsetOptions(AudioOffsetContainer audioOffsetContainer)
    {
        BeginHorizontal();
        audioOffsetContainer.offset = EditorGUILayout.FloatField(s_AudioOffsetField, audioOffsetContainer.offset);
        EndHorizontal();
    }

    private void BPMGuideControlsOnGUI(AudioControlsState audioControls)
    {
        VerticalSpace();

        BeginHorizontal();
        float inputBpm = EditorGUILayout.FloatField(s_BpmField, audioControls.m_bpm);
        audioControls.m_bpm = Mathf.Max(inputBpm, 1);
        EndHorizontal();

        BeginHorizontal();
        audioControls.m_bpmGuidePrecision = EditorGUILayout.IntField(s_BeatPrecisionField, audioControls.m_bpmGuidePrecision);
        EndHorizontal();

        BeginHorizontal();
        audioControls.m_bpmGuideColor = EditorGUILayout.ColorField(s_GuideColorField, audioControls.m_bpmGuideColor);
        EndHorizontal();

        BeginHorizontal();
        audioControls.m_showBeatLabels = EditorGUILayout.Toggle(s_BeatLabelsField, audioControls.m_showBeatLabels);
        EndHorizontal();
    }
}
