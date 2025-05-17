using System;
using UnityEditor;
using UnityEngine;

[System.Serializable]
public class AudioControlsState : PlayerPrefsSerializer
{
    [SerializeField] public bool m_isAudioEnabled = false;
    [SerializeField] public Color m_waveformColor = new Color(0, 0.4f, 0.5f, 1);
    [SerializeField] public bool m_bpmGuideEnabled = false;
    [SerializeField] public float m_bpm = 60f;
    [SerializeField] public Color m_bpmGuideColor = new Color(1, 1, 1, 0.4f);
    [SerializeField] public bool m_showBeatLabels = false;
    [SerializeField] public int m_bpmGuidePrecision = 1;
    [SerializeField] public int m_latencyMilliseconds = 0;

    private AudioClip _m_audioClip;
    private AudioClip m_audioClipVolumeAdjusted;

    protected override string PlayerPrefsKey => "AudioControlsState_";

    public AudioClip m_audioClip
    {
        get => _m_audioClip;
        set
        {
            if (_m_audioClip != value)
            {
                _m_audioClip = value;
                OnAudioChanged(value);
            }
        }
    }

    public override void Load()
    {
        m_isAudioEnabled = LoadBool("isAudioEnabled");
        string path = LoadString("audioClipPath");
        if (path != null)
        {
            m_audioClip = AssetDatabase.LoadAssetAtPath<AudioClip>(path);
        }
        m_waveformColor = LoadColor("waveformColor", new Color(0, 0.4f, 0.5f, 1));
        m_bpmGuideEnabled = LoadBool("bpmGuideEnabled");
        m_bpm = Mathf.Max(1, LoadFloat("bpm", 60));
        m_bpmGuideColor = LoadColor("bpmGuideColor", new Color(1, 1, 1, 0.6f));
        m_showBeatLabels = LoadBool("showBeatLabels");
        m_bpmGuidePrecision = Math.Max(1, LoadInt("bpmGuidePrecision", 1));
        m_latencyMilliseconds = LoadInt("latencyMilliseconds");
    }

    public override void Save()
    {
        SaveBool("isAudioEnabled", m_isAudioEnabled);
        if (m_audioClip != null)
        {
            string path = AssetDatabase.GetAssetPath(m_audioClip);
            SaveString("audioClipPath", path);
        }
        SaveColor("waveformColor", m_waveformColor);
        SaveBool("bpmGuideEnabled", m_bpmGuideEnabled);
        SaveFloat("bpm", m_bpm);
        SaveColor("bpmGuideColor", m_bpmGuideColor);
        SaveBool("showBeatLabels", m_showBeatLabels);
        SaveInt("bpmGuidePrecision", m_bpmGuidePrecision);
        SaveInt("latencyMilliseconds", m_latencyMilliseconds);
    }

    private void OnAudioChanged(AudioClip newClip)
    {
        m_audioClipVolumeAdjusted = AudioClipUtility.CloneClip(newClip);
    }

    public void PlayAudio(float time)
    {
        if (!m_isAudioEnabled)
        {
            return;
        }

        time += m_latencyMilliseconds / 1000f;
        AudioClipUtility.PlayAudioClip(_m_audioClip, time);
    }

    public void StopAudio()
    {
        AudioClipUtility.StopAudioClip(_m_audioClip);
    }

    public void RestartAudio(float time)
    {
        StopAudio();
        PlayAudio(time);
    }
}
