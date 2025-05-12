using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Reflection;

namespace AnimationCurveManipulationTool {

    public class AnimationKeyTimeBinding {

        private object objectReference;

        public AnimationKeyTimeBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        private static System.Type bindedType;
        public static System.Type GetBindedType() {
            if (bindedType == null) {
                bindedType = ReflectionUtility.unityEditorAssembly.GetType("UnityEditorInternal.AnimationKeyTime");
            }
            return bindedType;
        }

        public object GetObjectReference() { return objectReference; }


        public static AnimationKeyTimeBinding Time(float time, float frameRate) {
            AnimationKeyTimeBinding key = new AnimationKeyTimeBinding(Activator.CreateInstance(GetBindedType()));
            key.m_Time = Mathf.Max(time, 0f);
            key.m_FrameRate = frameRate;
            key.m_Frame = Mathf.RoundToInt(key.m_Time * frameRate);
            return key;
        }

        private float m_FrameRate {
            get {
                return (float)objectReference.GetType()
                    .GetField("m_FrameRate", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
            set {
                objectReference.GetType()
                    .GetField("m_FrameRate", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }
        private int m_Frame {
            get {
                return (int)objectReference.GetType()
                    .GetField("m_Frame", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
            set {
                objectReference.GetType()
                    .GetField("m_Frame", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }
        private float m_Time {
            get {
                return (float)objectReference.GetType()
                    .GetField("m_Time", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
            set {
                objectReference.GetType()
                    .GetField("m_Time", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .SetValue(objectReference, value);
            }
        }
    }

}