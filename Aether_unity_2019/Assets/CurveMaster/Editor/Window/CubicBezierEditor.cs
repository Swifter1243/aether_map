using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    [System.Serializable]
    public class CubicBezierEditor {

        private const float MIN_X = 0.00000001f;
        private const float MAX_X = 0.9999999f;

        public System.Action onRepaintNeeded;
        public System.Action onRecordUndoRequest;
        public System.Action onValueChanged;

        private const int POINT_SIZE = 10;

        [SerializeField] private Vector2 m_startPoint = Vector2.zero;
        [SerializeField] private Vector2 m_endPoint = Vector2.one;
        [SerializeField] private Vector2 m_startTangent = new Vector2(0.25f, 0);
        [SerializeField] private Vector2 m_endTangent = new Vector2(0.75f, 1f);


        private bool isDragginStartTangent;
        private bool isDragginEndTangent;

        [SerializeField] private float zoomValue = 1f;


        public Vector2 startPoint => m_startPoint;
        public Vector2 endPoint => m_endPoint;
        public Vector2 startTangent => m_startTangent;
        public Vector2 endTangent => m_endTangent;

        public Vector4 curveValue => new Vector4(m_startTangent.x, m_startTangent.y, m_endTangent.x, m_endTangent.y);

        public string GetStringValue() {
            return "(" + startTangent.x + ", " + startTangent.y + ", " + endTangent.x + ", " + endTangent.y + ")";
        }

        private static void RecalculateKeyframeTangents(ref Keyframe _startKeyframe, ref Keyframe _endKeyframe, out float inTangent, out float outTangent) {

            if (float.IsNaN(_startKeyframe.outTangent)) {
                inTangent = 0;
            }
            else if (float.IsNegativeInfinity(_startKeyframe.outTangent)) {
                inTangent = -1 * _startKeyframe.outWeight;
            }
            else if (float.IsPositiveInfinity(_startKeyframe.outTangent)) {
                inTangent = 1 - _startKeyframe.outWeight;
            }
            else {
                inTangent = _startKeyframe.outTangent * _startKeyframe.outWeight;
            }

            if (float.IsNaN(_endKeyframe.inTangent)) {
                outTangent = 0;
            }
            else if (float.IsNegativeInfinity(_endKeyframe.inTangent)) {
                outTangent = -1 * _endKeyframe.inWeight;
            }
            else if (float.IsPositiveInfinity(_endKeyframe.inTangent)) {
                outTangent = 1 - _endKeyframe.inWeight;
            }
            else {
                outTangent = _endKeyframe.inTangent * _endKeyframe.inWeight;
            }
        }

        public void SetByKeyframeValues(Keyframe _startKeyframe, Keyframe _endKeyframe, int _applyMode = 1) {
            AnimationUtilityInternal.SetKeyRightWeightedMode(ref _startKeyframe, true);
            AnimationUtilityInternal.SetKeyLeftWeightedMode(ref _endKeyframe, true);

            RecalculateKeyframeTangents(ref _startKeyframe, ref _endKeyframe, out var inTangent, out var outTangent);

            BezierUtility.TangentsToBezier(Vector2.zero, inTangent, Vector2.one, outTangent, out var startTangent, out var endTangent);

            if (_applyMode == 0 || _applyMode == 1) {
                m_startTangent = startTangent;
                m_startTangent.x = _startKeyframe.outWeight;
            }

            if (_applyMode == 2 || _applyMode == 1) {
                m_endTangent = endTangent;
                m_endTangent.x = 1 - _endKeyframe.inWeight;
                float deltaY = endTangent.y - 1;
                m_endTangent.y = 1 - deltaY;
            }
        }

        public void SetValue(float[] _curveValue) {
            if (_curveValue.Length >= 2)
                m_startTangent = new Vector2(_curveValue[0], _curveValue[1]);
            if (_curveValue.Length >= 4)
                m_endTangent = new Vector2(_curveValue[2], _curveValue[3]);
            onValueChanged?.Invoke();
        }

        public float[] GetValue() {
            return new float[] { m_startTangent.x, m_startTangent.y, m_endTangent.x, m_endTangent.y };
        }

        public void Parse(string _curveStringValue) {
            if (string.IsNullOrEmpty(_curveStringValue)) return;

            var splits = _curveStringValue.Split(',');
            for (int i=0; i<splits.Length; i++) {
                splits[i] = Regex.Replace(splits[i], "[^0-9.-]", "");
            }
            if (0 < splits.Length) {
                if (float.TryParse(splits[0], out float newStartTangentX)) {
                    m_startTangent.x = newStartTangentX;
                    m_startTangent.x = Mathf.Clamp(m_startTangent.x, MIN_X, MAX_X);
                }
            }
            if (1 < splits.Length) {
                if (float.TryParse(splits[1], out float newStartTangentY)) {
                    m_startTangent.y = newStartTangentY;
                }
            }
            if (2 < splits.Length) {
                if (float.TryParse(splits[2], out float newEndTangentX)) {
                    m_endTangent.x = newEndTangentX;
                    m_endTangent.x = Mathf.Clamp(m_endTangent.x, MIN_X, MAX_X);
                }
            }
            if (3 < splits.Length) {
                if (float.TryParse(splits[3], out float newEndTangentY)) {
                    m_endTangent.y = newEndTangentY;
                }
            }

            onValueChanged?.Invoke();
        }

        public void Draw(Rect _curveRect) {
            GUI.Box(_curveRect, GUIContent.none, Styles.boxBackground);

            var originalRect = _curveRect;

            GUI.BeginClip(_curveRect);
            _curveRect.position = Vector2.zero;

            _curveRect.position += Vector2.one * 5f;
            _curveRect.size -= Vector2.one * 10f;

            Vector2 originalSize = _curveRect.size;
            _curveRect.size *= zoomValue;
            _curveRect.position += Vector2.right * (1 - zoomValue) * originalSize.x / 2f;
            _curveRect.position += Vector2.up * (1 - zoomValue) * originalSize.y / 2f;

            DrawGrid(_curveRect, _curveRect.width / 20f, _curveRect.height / 20f, 0.25f, new Color(0.5f, 0.5f, 0.5f, 1));
            DrawGrid(_curveRect, _curveRect.width / 5f, _curveRect.height / 5f, 0.35f, new Color(0.75f, 0.75f, 0.75f, 1));

            Vector2 startPointInv = new Vector2(m_startPoint.x, 1 - m_startPoint.y);
            Vector2 endPointInv = new Vector2(m_endPoint.x, 1 - m_endPoint.y);
            Vector2 startTangentInv = new Vector2(m_startTangent.x, 1 - m_startTangent.y);
            Vector2 endTangentInv = new Vector2(m_endTangent.x, 1 - m_endTangent.y);

            Handles.BeginGUI();
            Handles.DrawBezier(
                _curveRect.position + startPointInv * _curveRect.size,
                _curveRect.position + endPointInv * _curveRect.size,
                _curveRect.position + startTangentInv * _curveRect.size,
                _curveRect.position + endTangentInv * _curveRect.size,
                Color.white,
                null,
                2f
            );
            Handles.EndGUI();

            // Draw the points and tangents
            Handles.color = Color.red;
            DrawPoint(_curveRect, startPointInv);
            DrawPoint(_curveRect, endPointInv);
            DrawPoint(_curveRect, startTangentInv);
            DrawPoint(_curveRect, endTangentInv);
            Handles.color = Color.green;
            var startTanRect = DrawTangent(_curveRect, startPointInv, startTangentInv, Color.magenta);
            var endTanRect = DrawTangent(_curveRect, endPointInv, endTangentInv, Color.cyan);

            HandleEvents(originalRect, _curveRect, startTanRect, endTanRect);

            GUI.EndClip();
        }

        private void DrawGrid(Rect _curveRect, float _horizontalSpacing, float _verticalSpacing, float _gridOpacity, Color _gridColor) {
            Vector2 size = _curveRect.size * 8;
            int widthDivs = Mathf.CeilToInt(size.x / 0.2f / _horizontalSpacing);
            int heightDivs = Mathf.CeilToInt(size.y / 0.2f / _verticalSpacing);

            Handles.BeginGUI();
            Handles.color = new Color(_gridColor.r, _gridColor.g, _gridColor.b, _gridOpacity);

            //Vector3 newOffset = new Vector3(realPositionOffset.x % gridSpacing, realPositionOffset.y % gridSpacing, 0);
            Vector3 newOffset = _curveRect.position - size*4;

            for (int i = 0; i < widthDivs; i++) {
                Handles.DrawLine(new Vector3(_horizontalSpacing * i, -_horizontalSpacing, 0) + newOffset, new Vector3(_horizontalSpacing * i, size.y / 0.2f, 0f) + newOffset);
            }

            for (int j = 0; j < heightDivs; j++) {
                Handles.DrawLine(new Vector3(-_verticalSpacing, _verticalSpacing * j, 0) + newOffset, new Vector3(size.x / 0.2f, _verticalSpacing * j, 0f) + newOffset);
            }

            Handles.color = Color.white;
            Handles.EndGUI();
        }

        private void HandleEvents(Rect _originalRect, Rect _curveRect, Rect _startTangentRect, Rect _endTangentRect) {
            EditorGUIUtility.AddCursorRect(_startTangentRect, MouseCursor.MoveArrow);
            EditorGUIUtility.AddCursorRect(_endTangentRect, MouseCursor.MoveArrow);

            var e = Event.current;

            if (e.type == EventType.ScrollWheel) {
                if (_originalRect.Contains(e.mousePosition)) {
                    zoomValue -= e.delta.y * 0.01f;
                    if (zoomValue < 0.1f) zoomValue = 0.1f;
                    if (zoomValue > 1f) zoomValue = 1f;
                    onRepaintNeeded?.Invoke();
                }
            }

            if (e.type == EventType.MouseDown && e.button == 0) {
                if (_startTangentRect.Contains(e.mousePosition)) {
                    GUI.FocusControl(null);
                    isDragginStartTangent = true;
                }
                else if (_endTangentRect.Contains(e.mousePosition)) {
                    GUI.FocusControl(null);
                    isDragginEndTangent = true;
                }
            }

            if (isDragginStartTangent) {
                if (e.type == EventType.MouseDrag) {
                    onRecordUndoRequest?.Invoke();
                    var startTangentInv = (e.mousePosition - _curveRect.position) / _curveRect.size;
                    m_startTangent = new Vector2(startTangentInv.x, 1 - startTangentInv.y);
                    m_startTangent.x = Mathf.Clamp(m_startTangent.x, MIN_X, MAX_X);
                    onValueChanged?.Invoke();
                    onRepaintNeeded?.Invoke();
                }

                if ((e.type == EventType.MouseUp && e.button == 0) || e.type == EventType.Ignore) {
                    isDragginStartTangent = false;
                }
            }

            if (isDragginEndTangent) {
                if (e.type == EventType.MouseDrag) {
                    onRecordUndoRequest?.Invoke();
                    var endTangentInv = (e.mousePosition - _curveRect.position) / _curveRect.size;
                    m_endTangent = new Vector2(endTangentInv.x, 1 - endTangentInv.y);
                    m_endTangent.x = Mathf.Clamp(m_endTangent.x, MIN_X, MAX_X);
                    onValueChanged?.Invoke();
                    onRepaintNeeded?.Invoke();
                }

                if ((e.type == EventType.MouseUp && e.button == 0) || e.type == EventType.Ignore) {
                    isDragginEndTangent = false;
                }
            }
        }

        private void DrawPoint(Rect _rect, Vector2 _point) {
            Vector2 position = _rect.position + _point * _rect.size;
            GUI.DrawTexture(new Rect(position.x - POINT_SIZE / 2f, position.y - POINT_SIZE / 2f, POINT_SIZE, POINT_SIZE), Texture2D.whiteTexture);
        }

        private Rect DrawTangent(Rect _rect, Vector2 _point, Vector2 _tangent, Color _color) {
            Vector2 position = _rect.position + _point * _rect.size;
            Vector2 handlePosition = _rect.position + _tangent * _rect.size;
            Handles.DrawLine(position, handlePosition);
            var handleRect = new Rect(handlePosition.x - POINT_SIZE / 2f, handlePosition.y - POINT_SIZE / 2f, POINT_SIZE, POINT_SIZE);
            var guiColor = GUI.color;
            GUI.color = _color;
            GUI.DrawTexture(handleRect, Texture2D.whiteTexture);
            GUI.color = guiColor;
            return handleRect;
        }

    }

}
