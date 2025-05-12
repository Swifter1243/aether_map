using UnityEngine;
using static UnityEditor.AnimationUtility;

namespace AnimationCurveManipulationTool {

    public static class BezierUtility {

        public static void BezierToTangents(Vector2 _startPoint, Vector2 _startTangent, Vector2 _endPoint, Vector2 _endTangent, out float _inTangent, out float _outTangent) {
            float dx = _endTangent.x - _endPoint.x;
            float dy = _endTangent.y - _endPoint.y;
            if (dx == 0) {
                _outTangent = dy / (_endTangent.y - _endPoint.y);
            }
            else if (dy == 0) {
                //_outTangent = (_endTangent.x - _endPoint.x) / dx;
                _outTangent = 0;
            }
            else {
                _outTangent = dy / dx;
            }

            dx = _startTangent.x - _startPoint.x;
            dy = _startTangent.y - _startPoint.y;
            if (dx == 0) {
                _inTangent = dy / (_startTangent.y - _startPoint.y);
            }
            else if (dy == 0) {
                //_inTangent = (_startTangent.x - _startPoint.x) / dx;
                _inTangent = 0;
            }
            else {
                _inTangent = dy / dx;
            }
        }

        public static void TangentsToBezier(Vector2 _startPoint, float _inTangent, Vector2 _endPoint, float _outTangent, out Vector2 _startTangent, out Vector2 _endTangent) {
            float dx = _endPoint.x - _startPoint.x;
            float dy = _endPoint.y - _startPoint.y;

            if (dx == 0) {
                _endTangent = new Vector2(_endPoint.x, _endPoint.y + dy / _outTangent);
                _startTangent = new Vector2(_startPoint.x, _startPoint.y + dy / _inTangent);
            }
            else if (dy == 0) {
                _endTangent = new Vector2(_endPoint.x + dx / _outTangent, _endPoint.y);
                _startTangent = new Vector2(_startPoint.x + dx / _inTangent, _startPoint.y);
            }
            else {
                _endTangent = new Vector2(_endPoint.x + dx, _endPoint.y + _outTangent * dx);
                _startTangent = new Vector2(_startPoint.x + dx, _startPoint.y + _inTangent * dx);
            }
        }

        public static void ApplyCurveToKeyframes(ref Keyframe keyframe1, ref Keyframe keyframe2, Vector2 inTangent, Vector2 outTangent, int _applyMode = 1) {
            BezierToTangents(Vector2.zero, inTangent, outTangent, Vector2.one, out var inTangentValue, out var outTangentValue);

            if (_applyMode == 0 || _applyMode == 1) {
                AnimationUtilityInternal.SetKeyBroken(ref keyframe1, true);
                AnimationUtilityInternal.SetKeyRightWeightedMode(ref keyframe1, true);
                AnimationUtilityInternal.SetKeyRightTangentMode(ref keyframe1, TangentMode.Free);
                keyframe1.outWeight = inTangent.x;
                keyframe1.outTangent = inTangentValue;
            }

            if (_applyMode == 2 || _applyMode == 1) {
                AnimationUtilityInternal.SetKeyBroken(ref keyframe2, true);
                AnimationUtilityInternal.SetKeyLeftWeightedMode(ref keyframe2, true);
                AnimationUtilityInternal.SetKeyLeftTangentMode(ref keyframe2, TangentMode.Free);
                keyframe2.inWeight = 1 - outTangent.x;
                keyframe2.inTangent = outTangentValue;
            }

        }

        public static void GetTangentsFromKeyframes(Keyframe keyframe1, Keyframe keyframe2, out Vector2 inTangent, out Vector2 outTangent) {
            float inWeight = 1 - keyframe2.inWeight;
            float outWeight = keyframe1.outWeight;
            float inSlope = inWeight * (keyframe2.value - keyframe1.value) / (keyframe2.time - keyframe1.time);
            float outSlope = outWeight * (keyframe2.value - keyframe1.value) / (keyframe2.time - keyframe1.time);
            inTangent = new Vector2(inWeight, inSlope);
            outTangent = new Vector2(1 - outWeight, outSlope);
        }

    }

}