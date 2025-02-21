using UnityEditor;
using UnityEngine;

[System.Serializable]
public class AudioControlsState
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

    private const string PlayerPrefsKey = "AudioControlsState_";

    private bool LoadBool(string name, bool defaultValue = false)
    {
        int value = PlayerPrefs.GetInt(PlayerPrefsKey + name, defaultValue ? 1 : 0);
        return value == 1;
    }

    private int LoadInt(string name, int defaultValue = 0)
    {
        return PlayerPrefs.GetInt(PlayerPrefsKey + name, defaultValue);
    }

    private string LoadString(string name, string defaultValue = null)
    {
        return PlayerPrefs.GetString(PlayerPrefsKey + name, defaultValue);
    }

    private float LoadFloat(string name, float defaultValue = 0)
    {
        return PlayerPrefs.GetFloat(PlayerPrefsKey + name, defaultValue);
    }

    private Color LoadColor(string name, Color defaultValue = default)
    {
        float r = LoadFloat(name + "_r", defaultValue.r);
        float g = LoadFloat(name + "_g", defaultValue.g);
        float b = LoadFloat(name + "_b", defaultValue.b);
        float a = LoadFloat(name + "_a", defaultValue.a);
        return new Color(r, g, b, a);
    }

    private void SaveBool(string name, bool value)
    {
        PlayerPrefs.SetInt(PlayerPrefsKey + name, value ? 1 : 0);
    }

    private void SaveInt(string name, int value)
    {
        PlayerPrefs.SetInt(PlayerPrefsKey + name, value);
    }

    private void SaveString(string name, string value)
    {
        PlayerPrefs.SetString(PlayerPrefsKey + name, value);
    }

    private void SaveFloat(string name, float value)
    {
        PlayerPrefs.SetFloat(PlayerPrefsKey + name, value);
    }

    private void SaveColor(string name, Color value)
    {
        SaveFloat(name + "_r", value.r);
        SaveFloat(name + "_g", value.g);
        SaveFloat(name + "_b", value.b);
        SaveFloat(name + "_a", value.a);
    }

    public void Load()
    {
        m_isAudioEnabled = LoadBool("isAudioEnabled");
        string path = LoadString("audioClipPath");
        if (path != null)
        {
            m_audioClip = AssetDatabase.LoadAssetAtPath<AudioClip>(path);
        }
        m_waveformColor = LoadColor("waveformColor", new Color(0, 0.4f, 0.5f, 1));
        m_bpmGuideEnabled = LoadBool("bpmGuideEnabled");
        m_bpm = LoadFloat("bpm", 60);
        m_bpmGuideColor = LoadColor("bpmGuideColor", new Color(1, 1, 1, 0.6f));
        m_showBeatLabels = LoadBool("showBeatLabels");
        m_bpmGuidePrecision = LoadInt("bpmGuidePrecision", 1);
        m_latencyMilliseconds = LoadInt("latencyMilliseconds");
    }

    public void Save()
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
