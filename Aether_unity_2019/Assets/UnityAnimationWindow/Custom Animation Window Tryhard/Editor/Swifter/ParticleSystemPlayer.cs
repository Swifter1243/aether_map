using System.Collections.Generic;
using UnityEngine;

namespace UnityAnimationWindow.Custom_Animation_Window_Tryhard.Editor.Swifter
{
    public class ParticleSystemPlayer
    {
        private readonly ParticleSystem m_ParticleSystem;
        private readonly List<float> m_ActiveTimes;
        private float m_LastSeekTime = 0;
        private float m_LastSeekNormalTime = 0;
        
        public ParticleSystemPlayer(ParticleSystem particleSystem, List<float> activeTimes)
        {
            m_ParticleSystem = particleSystem;
            m_ActiveTimes = activeTimes;
        }

        private float GetNormalTime(float time)
        {
            float lastActiveTime = m_ActiveTimes.FindLast(t => time >= t);
            return time - lastActiveTime;
        }

        public void Pause()
        {
            m_ParticleSystem.Pause();
        }

        public void Reset(float time)
        {
            float normalTime = GetNormalTime(time);
            m_LastSeekTime = time;
            m_LastSeekNormalTime = normalTime;
            m_ParticleSystem.Simulate(normalTime);
        }
        
        public void Seek(float time)
        {
            float normalTime = GetNormalTime(time);
            float normalTimeDelta = normalTime - m_LastSeekNormalTime;
            float timeDelta = time - m_LastSeekTime;

            bool reversingTime = timeDelta < 0;
            bool reversingNormalTime = normalTimeDelta < 0;
            bool normalTimeSkippedBackward = reversingNormalTime && !reversingTime;
            bool normalTimeSkippedForward = !reversingNormalTime && reversingTime;

            if (normalTimeSkippedBackward || normalTimeSkippedForward)
            {
                m_ParticleSystem.Simulate(normalTime, true, true);
            }
            else
            {
                m_ParticleSystem.Simulate(timeDelta, true, false);
            }
            
            m_LastSeekNormalTime = normalTime;
            m_LastSeekTime = time;
        }
    }
}