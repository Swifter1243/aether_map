using System;
using UnityAnimationWindow.Custom_Animation_Window_Tryhard.Editor.Swifter;
using UnityAnimationWindow.Swifter;
using UnityEditor;
using UnityEditorInternal.Enemeteen;
using UnityEngine;
using TimeArea = UnityEditor.Enemeteen.TimeArea;

[System.Serializable]
class AudioWaveformVisualizer
{
    [SerializeField] public AnimationWindowState state;
    private float[] _samples = new float[MaxWindowSamples];
    private const int MaxWindowSamples = 100;
    private const int BeatLabelWidth = 40;
    private const float SubBeatLineInset = 0.2f;
    
    private GUIStyle s_beatLabelStyle =>
        new GUIStyle
        {
            fontStyle = FontStyle.Bold,
            normal =
            {
                textColor = state.audioControlsState.m_bpmGuideColor,
            }
        };

    public void DrawWaveform(Rect audioWaveformRect)
    {
        GL.Begin(GL.LINES);
        HandleUtility.ApplyWireMaterial();
        GL.Color(state.audioControlsState.m_waveformColor);

        float startX = audioWaveformRect.xMin;
        float endX = audioWaveformRect.xMax;
        float middleY = audioWaveformRect.center.y;
        float halfHeight = audioWaveformRect.height / 2;
        
        AudioClip clip = state.audioControlsState.m_audioClip;
        if (!clip)
        {
            startX = Math.Max(0, state.TimeToPixel(0)) + startX;
            GL.Vertex(new Vector3(startX, middleY, 0));
            GL.Vertex(new Vector3(endX, middleY, 0));
        }
        else
        {
            for (float x = startX; x < endX; x++)
            {
                float sample = SampleAudioDataAtPixel(audioWaveformRect, clip, x);

                if (sample < 0)
                {
                    continue;
                }
                
                float waveformHeight = halfHeight * sample;
                waveformHeight = Mathf.Max(waveformHeight, 1);
            
                float y1 = middleY - waveformHeight;
                float y2 = middleY + waveformHeight;
            
                DrawVerticalLineFast(x, y1, y2);
            }
        }
        
        GL.End();
    }

    public void DrawBPMGuide(Rect audioBPMRect)
    {
        float startTime = Mathf.Max(0, PixelToTime(audioBPMRect, audioBPMRect.xMin));
        float endTime = PixelToTime(audioBPMRect, audioBPMRect.xMax);

        float bpm = state.audioControlsState.m_bpm;
        float step = 60f / state.audioControlsState.m_bpmGuidePrecision / bpm;
        float startTimeBounded = Mathf.Ceil(startTime / step) * step;
        
        GUI.BeginGroup(audioBPMRect);
        
        DrawBeatGuides(audioBPMRect, step, startTimeBounded, endTime, bpm);
        
        float pixelDistance = state.TimeToPixel(step) - state.zeroTimePixel;
        float minimumPixelDistance = BeatLabelWidth;
        while (pixelDistance < minimumPixelDistance)
        {
            step *= 2;
            pixelDistance *= 2;
        }
        startTimeBounded = Mathf.Ceil(startTime / step) * step;

        if (state.audioControlsState.m_showBeatLabels)
        {
            DrawBeatLabels(step, startTimeBounded, endTime, bpm);
        }
        
        GUI.EndGroup();
    }

    private bool IsOnExactBeat(float beat)
    {
        float precision = 0.9f / state.audioControlsState.m_bpmGuidePrecision;
        bool closeDown = beat % 1 < precision;
        bool closeUp = (1 - beat % 1) < precision;
        return closeDown || closeUp;
    }

    private void DrawBeatGuides(Rect audioBPMRect, float step, float startTimeBounded, float endTime, float bpm)
    {
        GL.Begin(GL.LINES);
        HandleUtility.ApplyWireMaterial();
        GL.Color(state.audioControlsState.m_bpmGuideColor);
        
        float subBeatLineInset = audioBPMRect.height * SubBeatLineInset;
        
        for (float t = startTimeBounded; t < endTime; t += step)
        {
            float x = state.TimeToPixel(t);
            float beat = TimingUtility.SecondsToBeat(bpm, t) + state.GetAudioBeatOffset();
            
            if (IsOnExactBeat(beat))
            {
                DrawVerticalLineFast(x, 0, audioBPMRect.height);
            }
            else
            {
                DrawVerticalLineFast(x, subBeatLineInset, audioBPMRect.height - subBeatLineInset);
            }
        }
        GL.End();
    }

    private void DrawBeatLabels(float step, float startTimeBounded, float endTime, float bpm)
    {
        GUIStyle labelStyle = s_beatLabelStyle;
            
        for (float t = startTimeBounded; t < endTime; t += step)
        {
            float x = state.TimeToPixel(t);
            float beat = TimingUtility.SecondsToBeat(bpm, t) + state.GetAudioBeatOffset();

            if (IsOnExactBeat(beat))
            {
                GUI.Label(new Rect(x + 4, -1, BeatLabelWidth, 20), Mathf.RoundToInt(beat).ToString(), labelStyle);   
            }
        }
    }

    private float PixelToTime(Rect rect, float x)
    {
        return state.PixelToTime(x - rect.xMin);
    }

    private float TimeToPixel(Rect rect, float t)
    {
        return state.TimeToPixel(t) + rect.xMin;
    }

    private float SampleAudioDataAtPixel(Rect audioWaveformRect, AudioClip clip, float x)
    {
        float x1 = x - 0.5f;
        float x2 = x + 0.5f;
        
        float t1 = PixelToTime(audioWaveformRect, x1);
        float t2 = PixelToTime(audioWaveformRect, x2);

        if (t1 < 0 || t2 > clip.length)
        {
            return -1;
        }

        t1 += state.GetAudioSecondOffset();
        t2 += state.GetAudioSecondOffset();
        
        int p1 = AudioClipUtility.SecondsToSamplePosition(clip, t1);
        int p2 = AudioClipUtility.SecondsToSamplePosition(clip, t2);
        
        int width = p2 - p1;
        width = Math.Min(width, MaxWindowSamples);
        clip.GetData(_samples, p1);
        
        float s = 0;
        
        for (int i = 0; i < width; i++)
        {
            s += Math.Abs(_samples[i]);
        }
        s /= width;
        return Mathf.Sqrt(s);
    }

    public static void DrawVerticalLineFast(float x, float minY, float maxY) {
        if (Application.platform == RuntimePlatform.WindowsEditor) {
            x = (int)x + 0.5f;
        }
        GL.Vertex(new Vector3(x, minY, 0));
        GL.Vertex(new Vector3(x, maxY, 0));
    }
}