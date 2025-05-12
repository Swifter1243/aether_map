using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using static UnityEditor.AnimationUtility;

namespace AnimationCurveManipulationTool {

    public static class AnimationUtilityInternal {

        public static bool GetKeyBroken(Keyframe _key) {
            return (bool)typeof(AnimationUtility).GetMethod("GetKeyBroken", BindingFlags.Static | BindingFlags.NonPublic)
                .Invoke(null, new object[] { _key });
        }

        public static void SetKeyBroken(ref Keyframe _key, bool _broken) {
            var args = new object[] { _key, _broken };  //Store into array first since we need to pass key as ref
            typeof(AnimationUtility).GetMethod("SetKeyBroken", BindingFlags.Static | BindingFlags.NonPublic)
                .Invoke(null, args);
            _key = (Keyframe)args[0];
        }


        public static TangentMode GetKeyLeftTangentMode(Keyframe _key) {
            return (TangentMode)typeof(AnimationUtility).GetMethod("GetKeyLeftTangentMode", BindingFlags.Static | BindingFlags.NonPublic)
                .Invoke(null, new object[] { _key });
        }

        public static TangentMode GetKeyRightTangentMode(Keyframe _key) {
            return (TangentMode)typeof(AnimationUtility).GetMethod("GetKeyRightTangentMode", BindingFlags.Static | BindingFlags.NonPublic)
                .Invoke(null, new object[] { _key });
        }

        public static void SetKeyLeftTangentMode(ref Keyframe _key, TangentMode _tangentMode) {
            var args = new object[] { _key, _tangentMode };
            typeof(AnimationUtility).GetMethod("SetKeyLeftTangentMode", BindingFlags.Static | BindingFlags.NonPublic)
                .Invoke(null, args);
            _key = (Keyframe)args[0];
        }

        public static void SetKeyRightTangentMode(ref Keyframe _key, TangentMode _tangentMode) {
            var args = new object[] { _key, _tangentMode };
            typeof(AnimationUtility).GetMethod("SetKeyRightTangentMode", BindingFlags.Static | BindingFlags.NonPublic)
                .Invoke(null, args);
            _key = (Keyframe)args[0];
        }


        public static bool IsKeyLeftWeighted(Keyframe _key) {
            return _key.weightedMode == WeightedMode.Both || _key.weightedMode == WeightedMode.In;
        }

        public static bool IsKeyRightWeighted(Keyframe _key) {
            return _key.weightedMode == WeightedMode.Both || _key.weightedMode == WeightedMode.Out;
        }

        public static void SetKeyLeftWeightedMode(ref Keyframe _key, bool _isWeighted) {
            var isRightWeighted = _key.weightedMode == WeightedMode.Both || _key.weightedMode == WeightedMode.Out;
            if (_isWeighted && isRightWeighted) {
                _key.weightedMode = WeightedMode.Both;
            }
            else if (_isWeighted) {
                _key.weightedMode = WeightedMode.In;
            }
            else {
                _key.weightedMode = isRightWeighted ? WeightedMode.Out : WeightedMode.None;
            }
        }

        public static void SetKeyRightWeightedMode(ref Keyframe _key, bool _isWeighted) {
            var isLeftWeighted = _key.weightedMode == WeightedMode.Both || _key.weightedMode == WeightedMode.Out;
            if (_isWeighted && isLeftWeighted) {
                _key.weightedMode = WeightedMode.Both;
            }
            else if (_isWeighted) {
                _key.weightedMode = WeightedMode.Out;
            }
            else {
                _key.weightedMode = isLeftWeighted ? WeightedMode.In : WeightedMode.None;
            }
        }

    }

}