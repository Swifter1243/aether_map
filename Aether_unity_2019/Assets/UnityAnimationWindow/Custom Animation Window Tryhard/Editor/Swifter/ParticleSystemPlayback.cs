﻿using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace UnityAnimationWindow.Custom_Animation_Window_Tryhard.Editor.Swifter
{
    public class ParticleSystemPlayback
    {
        private List<ParticleSystemPlayer> m_ParticleSystemPlayers = new List<ParticleSystemPlayer>();

        private struct ActiveKeyframe
        {
            public bool active;
            public float time;
            public string path;
        }

        private class ParticleSystemActiveTracker
        {
            private readonly string[] m_Paths;
            private bool m_Active = true;
            public readonly ParticleSystem particleSystem;
            public readonly List<float> activeTimes = new List<float>();

            public ParticleSystemActiveTracker(string path, ParticleSystem particleSystem)
            {
                this.particleSystem = particleSystem;
                m_Paths = DecomposeParents(path);
            }

            private string[] DecomposeParents(string path)
            {
                string[] separated = path.Split('/');
                string[] result = new string[separated.Length];
                string built = "";

                for (int i = 0; i < separated.Length; i++)
                {
                    if (i > 0) built += '/';
                    built += separated[i];
                    result[i] = built;
                }

                return result;
            }
            
            private bool IsPathActive(string path, Dictionary<string, bool> objectActiveStates)
            {
                return !objectActiveStates.ContainsKey(path) || objectActiveStates[path];
            }

            private bool IsActiveNow(Dictionary<string, bool> objectActiveStates)
            {
                bool active = true;
                    
                foreach (string path in m_Paths)
                {
                    active &= IsPathActive(path, objectActiveStates);
                }

                return active;
            }

            public void TestActiveTime(Dictionary<string, bool> objectActiveStates, float time)
            {
                bool active = IsActiveNow(objectActiveStates);
                
                if (active != m_Active)
                {
                    activeTimes.Add(time);
                }
                
                m_Active = active;
            }
        }
        
        public void Setup(GameObject root, AnimationClip clip)
        {
            m_ParticleSystemPlayers.Clear();
            
            // Setup particle system data
            var particleSystemTrackers =  CollectParticleSystems(root).Select(p =>
            {
                string path = AnimationUtility.CalculateTransformPath(p.transform, root.transform);
                return new ParticleSystemActiveTracker(path, p);
            }).ToArray();

            if (particleSystemTrackers.Length == 0)
            {
                return;
            }
            
            // Compile SetActive keyframes
            var activeKeyframes = CollectActiveKeyframes(clip).ToList();
            activeKeyframes.Sort((a, b) => a.time.CompareTo(b.time));
            
            Dictionary<string, bool> objectActiveStates = new Dictionary<string, bool>();
            foreach (ActiveKeyframe activeKeyframe in activeKeyframes)
            {
                objectActiveStates[activeKeyframe.path] = activeKeyframe.active;

                foreach (ParticleSystemActiveTracker particleSystemTracker in particleSystemTrackers)
                {
                    particleSystemTracker.TestActiveTime(objectActiveStates, activeKeyframe.time);
                }
            }
            
            // Add particle system players
            foreach (ParticleSystemActiveTracker particleSystemTracker in particleSystemTrackers)
            {
                m_ParticleSystemPlayers.Add(new ParticleSystemPlayer(particleSystemTracker.particleSystem, particleSystemTracker.activeTimes));
            }
        }

        private IEnumerable<ActiveKeyframe> CollectActiveKeyframes(AnimationClip clip)
        {
            foreach (EditorCurveBinding binding in AnimationUtility.GetCurveBindings(clip))
            {
                if (binding.propertyName == "m_IsActive")
                {
                    AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, binding);
                    if (curve != null)
                    {
                        foreach (Keyframe key in curve.keys)
                        {
                            bool active = Mathf.Approximately(key.value, 1f);
                            yield return new ActiveKeyframe
                            {
                                active = active, 
                                time = key.time,
                                path = binding.path
                            };
                        }
                    }
                }
            }
        }

        private IEnumerable<ParticleSystem> CollectParticleSystems(GameObject root)
        {
            if (root.TryGetComponent(out ParticleSystem rootParticleSystem))
            {
                yield return rootParticleSystem;
            }

            foreach (ParticleSystem childParticleSystem in root.GetComponentsInChildren<ParticleSystem>())
            {
                yield return childParticleSystem;
            }
        }
        
        public void Pause()
        {
            foreach (ParticleSystemPlayer particleSystemPlayer in m_ParticleSystemPlayers)
            {
                particleSystemPlayer.Pause();
            }
        }
        
        public void Seek(float time)
        {
            foreach (ParticleSystemPlayer particleSystemPlayer in m_ParticleSystemPlayers)
            {
                particleSystemPlayer.Seek(time);
            }
        }
        
        public void Reset(float time)
        {
            foreach (ParticleSystemPlayer particleSystemPlayer in m_ParticleSystemPlayers)
            {
                particleSystemPlayer.Reset(time);
            }
        }
    }
}