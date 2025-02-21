using System;
using System.Reflection;
using UnityEditor;
using UnityEngine;

public static class AudioClipUtility
{
    public static int SecondsToSamplePosition(AudioClip clip, float seconds)
    {
       return Mathf.Clamp((int)(seconds * clip.frequency), 0, clip.samples);
    }

    public static float SampleClipAtTime(AudioClip clip, float time)
    {
        int samplePosition = Mathf.FloorToInt(SecondsToSamplePosition(clip, time));
        float[] samples = new float[clip.channels];
        clip.GetData(samples, samplePosition);
        return Mathf.Abs(samples[0]);
    }

    public static float[] GetClipSamples(AudioClip clip, int offset = 0)
    {
        float[] samples = new float[(clip.samples - offset) * clip.channels];
        clip.GetData(samples, offset);
        return samples;
    }

    public static AudioClip CloneClip(AudioClip clip)
    {
        if (!clip) return null;
        float[] samples = new float[clip.samples * clip.channels];
        clip.GetData(samples, 0);
        AudioClip newClip = AudioClip.Create(clip.name, samples.Length, clip.channels, clip.frequency, false);
        newClip.SetData(samples, 0);
        return newClip;
    }
        
    public static void PlayAudioClip(AudioClip clip, float time)
    {
        if (!clip) return;
        
        int samplePosition = SecondsToSamplePosition(clip, time);
        Type audioUtilType = typeof(Editor).Assembly.GetType("UnityEditor.AudioUtil");
        MethodInfo playMethod = audioUtilType.GetMethod("PlayClip", BindingFlags.Static | BindingFlags.Public);
        playMethod?.Invoke(null, new object[] { clip, samplePosition, false });
    }

    public static void StopAudioClip(AudioClip clip)
    {
        if (!clip) return;
        
        Type audioUtilType = typeof(Editor).Assembly.GetType("UnityEditor.AudioUtil");
        MethodInfo stopMethod = audioUtilType.GetMethod("StopClip", BindingFlags.Static | BindingFlags.Public);
        stopMethod?.Invoke(null, new object[] { clip });
    }
}