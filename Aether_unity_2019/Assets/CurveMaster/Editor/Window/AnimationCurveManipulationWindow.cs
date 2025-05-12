using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace AnimationCurveManipulationTool {

    public class AnimationCurveManipulationWindow : EditorWindow {

        [MenuItem("Window/Animation/Curve Master")]
        private static void OpenWindow() {
            var window = GetWindow<AnimationCurveManipulationWindow>();
            window.titleContent.text = "Curve Master";
            window.Show();
        }

        [SerializeField] private CubicBezierEditor cubicBezierEditor = new CubicBezierEditor();
        [SerializeField] private int currentLibraryIndex;
        [SerializeField] private int currentPresetIndex;

        private int libraryIndexToRename = -1;
        private int presetIndexToRename = -1;

        private bool hasAnyCurvePair;
        private int curveCount;
        private int keyframeCount = 0;
        private AnimationClip selectedClip;
        private Vector2 tabsScrollPos;
        private Vector2 presetsScrollPos;
        [SerializeField] private int currentApplyMode = 1;

        private List<AnimationWindowKeyframeBinding> selectedKeysOrdered = new List<AnimationWindowKeyframeBinding>();

        private bool needsToUpdateInfo = false;
        private bool updateEachFrame = false;
        private AnimationCurveManipulationConfig config;

        private void OnEnable() {
            config = AnimationCurveManipulationConfig.Get();
            updateEachFrame = config != null && config.useCustomSelectionOrder;
            wantsMouseMove = updateEachFrame;
            
            if (updateEachFrame) {
                EditorApplication.update += OnUpdate;
            }
            cubicBezierEditor.onRepaintNeeded = Repaint;
            cubicBezierEditor.onRecordUndoRequest = () => {
                Undo.RecordObject(this, "modify curve value");
            };
            cubicBezierEditor.onValueChanged = () => {
                if (hasAnyCurvePair && !ReferenceEquals(config, null) && config.autoApply) {
                    ApplyCurve();
                }
            };
        }

        private void OnDisable() {
            DisableFrameUpdate();
        }

        public void EnableFrameUpdate() {
            updateEachFrame = true;
            EditorApplication.update += OnUpdate;
        }

        public void DisableFrameUpdate() {
            if (!updateEachFrame) return;
            updateEachFrame = false;
            EditorApplication.update -= OnUpdate;
        }

        private void OnGUI() {

            if (needsToUpdateInfo) {
                if (mouseOverWindow == this) {
                    KeyframeDataUtility.GetCurveAndKeyCount(out curveCount, out keyframeCount, out hasAnyCurvePair);
                    needsToUpdateInfo = false;
                }
            }
            else if (mouseOverWindow != this) {
                needsToUpdateInfo = true;
            }

            selectedClip = null;
            bool curvePositionRight = !ReferenceEquals(config, null) && config.curvePositionRight;

            Rect leftSectionRect;
            Rect rightSectionRect;
            float leftSectionWidth = (position.width - 10) * 0.4f;

            if (curvePositionRight) {
                rightSectionRect = new Rect(2, 5, position.width - leftSectionWidth - 10, position.height - 10);
                leftSectionRect = new Rect(rightSectionRect.xMax + 5, 5, leftSectionWidth, position.height - 10);
            }
            else {
                leftSectionRect = new Rect(5, 5, leftSectionWidth, position.height - 10);
                rightSectionRect = new Rect(leftSectionRect.xMax + 5, 5, position.width - leftSectionRect.xMax - 10, position.height - 10);
            }

            GUI.Box(leftSectionRect, GUIContent.none, Styles.frameBoxStyle);
            //GUI.Box(rightSectionRect, GUIContent.none, Styles.frameBoxStyle);

            DrawLeftSection(leftSectionRect);
            DrawRightSection(rightSectionRect);

            var e = Event.current;
            if (e.type == EventType.ValidateCommand) {
                if (e.commandName == "UndoRedoPerformed") {
                    Repaint();
                }
            }
        }

        private void OnUpdate() {
            CheckKeySelection();
        }

        private HashSet<int> keyframeHashes = new HashSet<int>();
        private void CheckKeySelection() {
            var animationWindow = AnimationWindowBinding.Get();
            if (animationWindow == null) return;
            var animEditor = animationWindow.animEditor;
            if (animEditor == null) return;
            var state = animEditor.state;
            var selectedKeys = state.selectedKeys;

            if (selectedKeys.Count == 0 && focusedWindow == this) {
                animEditor.UpdateSelectedKeysFromCurveEditor();
                selectedKeys = state.selectedKeys;
            }

            if (!updateEachFrame) {
                selectedKeysOrdered = selectedKeys;
                return;
            }

            keyframeHashes.Clear();
            foreach (var keyframe in selectedKeys) {
                keyframeHashes.Add(keyframe.GetHash());
            }

            foreach (var keyframe in selectedKeysOrdered.ToArray()) {
                if (!keyframeHashes.Contains(keyframe.GetHash())) {
                    selectedKeysOrdered.Remove(keyframe);
                }
            }

            keyframeHashes.Clear();
            foreach (var keyframe in selectedKeysOrdered) {
                keyframeHashes.Add(keyframe.GetHash());
            }

            foreach (var keyframe in selectedKeys) {
                if (!keyframeHashes.Contains(keyframe.GetHash())) {
                    selectedKeysOrdered.Add(keyframe);
                }
            }


        }

        private void DrawLeftSection(Rect _drawArea) {
            GUILayout.BeginArea(new Rect(_drawArea.x + 5, _drawArea.y + 5, _drawArea.width - 10, _drawArea.height - 10));
            {
                var curveRect = EditorGUILayout.GetControlRect(GUILayout.ExpandHeight(true));
                cubicBezierEditor.Draw(curveRect);

                EditorGUI.BeginChangeCheck();
                var newStringValue = EditorGUILayout.DelayedTextField(cubicBezierEditor.GetStringValue());
                if (EditorGUI.EndChangeCheck()) {
                    Undo.RecordObject(this, "modify curve value by string");
                    cubicBezierEditor.Parse(newStringValue);
                    GUI.FocusControl(null);
                }

                bool guiEnabled = GUI.enabled;

                GUI.enabled = guiEnabled && hasAnyCurvePair;
                if (GUILayout.Button("Apply", GUILayout.Height(30))) {
                    ApplyCurve();
                }
                GUI.enabled = guiEnabled;

                GUILayout.BeginHorizontal();
                {
                    GUI.enabled = guiEnabled && hasAnyCurvePair;
                    if (GUILayout.Button("Get Curve")) {
                        GetCurve();
                    }
                    GUI.enabled = guiEnabled;

                    GUILayout.FlexibleSpace();

                    var guiColor = GUI.color;

                    GUI.color = currentApplyMode == 0 ? Color.white : Color.grey;
                    if (GUILayout.Button("In", GUILayout.Width(35))) {
                        currentApplyMode = 0;
                    }
                    GUI.color = currentApplyMode == 1 ? Color.white : Color.grey;
                    if (GUILayout.Button("In/Out", GUILayout.Width(50))) {
                        currentApplyMode = 1;
                    }
                    GUI.color = currentApplyMode == 2 ? Color.white : Color.grey;
                    if (GUILayout.Button("Out", GUILayout.Width(35))) {
                        currentApplyMode = 2;
                    }

                    GUI.color = guiColor;
                }
                GUILayout.EndHorizontal();
                GUILayout.Space(5);

                GUILayout.BeginHorizontal();
                float settingsSize = EditorGUIUtility.singleLineHeight * 2;
                var debugArea = EditorGUILayout.GetControlRect(GUILayout.ExpandWidth(true), GUILayout.Height(settingsSize));
                var settingsArea = EditorGUILayout.GetControlRect(GUILayout.Width(settingsSize), GUILayout.Height(settingsSize));
                GUILayout.EndHorizontal();

                GUI.Box(debugArea, GUIContent.none);
                DrawDebugger(debugArea, curveCount, keyframeCount);
                if (GUI.Button(settingsArea, CurveMasterGUIContents.gearIcon)) {
                    SettingsWindow.OpenWindow();
                }

                GUILayout.Space(5);

            }
            GUILayout.EndArea();
        }

        private static void GetCurve() {
            var window = GetWindow<AnimationCurveManipulationWindow>();
            var selectedKeyframesGroup = KeyframeDataUtility.GetSelectedKeyframesGroup(2);
            foreach (var kvp in selectedKeyframesGroup) {
                var selectedKeyframes = kvp.Value;
                if (selectedKeyframes.Length > 1) {
                    Undo.RecordObject(window, "get curve");
                    window.cubicBezierEditor.SetByKeyframeValues(selectedKeyframes[0], selectedKeyframes[1], window.currentApplyMode);
                }
                break;
            }
        }

        private static float GetKeyframesValueRange(List<AnimationWindowKeyframeBinding> selectedKeyframes, out float _minValue) {
            float minVal = float.MaxValue;
            float maxVal = float.MinValue;
            foreach (var keyframe in selectedKeyframes) {
                float val = keyframe.value;
                if (minVal > val) {
                    minVal = val;
                }
                if (maxVal < val) {
                    maxVal = val;
                }
            }
            float range = maxVal - minVal;
            _minValue = minVal;
            return range;
        }

        private static float GetKeyframesValueRange(Keyframe[] selectedKeyframes, out float _minValue) {
            float minVal = float.MaxValue;
            float maxVal = float.MinValue;
            foreach (var keyframe in selectedKeyframes) {
                float val = keyframe.value;
                if (minVal > val) {
                    minVal = val;
                }
                if (maxVal < val) {
                    maxVal = val;
                }
            }
            float range = maxVal - minVal;
            _minValue = minVal;
            return range;
        }

        private static void ApplyCurve() {
            var window = GetWindow<AnimationCurveManipulationWindow>();
            var selectedKeyframesGroup = KeyframeDataUtility.GetSelectedKeyframesGroup(1);
            var invalidCurves = new List<int>();
            foreach (var kvp in selectedKeyframesGroup) {
                var selectedKeyframes = kvp.Value;
                float range = GetKeyframesValueRange(selectedKeyframes, out var minValue);

                if (range == 0) {
                    invalidCurves.Add(kvp.Key);
                    continue;
                }

                if (selectedKeyframes.Length == 1) {
                    //if (window.currentApplyMode == 0) {
                    //    var decoy = new Keyframe();
                    //    BezierUtility.ApplyCurveToKeyframes(ref selectedKeyframes[0], ref decoy, window.cubicBezierEditor.startTangent, window.cubicBezierEditor.endTangent, window.currentApplyMode);
                    //}
                    //else if (window.currentApplyMode == 2) {
                    //    var decoy = new Keyframe();
                    //    BezierUtility.ApplyCurveToKeyframes(ref decoy, ref selectedKeyframes[0], window.cubicBezierEditor.startTangent, window.cubicBezierEditor.endTangent, window.currentApplyMode);
                    //}
                }
                else {
                    for (int i = 1; i < selectedKeyframes.Length; i++) {
                        BezierUtility.ApplyCurveToKeyframes(ref selectedKeyframes[i - 1], ref selectedKeyframes[i], window.cubicBezierEditor.startTangent, window.cubicBezierEditor.endTangent, window.currentApplyMode);
                    }
                }
            }
            foreach (var curveId in invalidCurves) {
                selectedKeyframesGroup.Remove(curveId);
            }
            KeyframeDataUtility.ApplyCurvesTangent(selectedKeyframesGroup);
        }

        private static void AlignKeyframes() {
            var animationWindow = AnimationWindowBinding.Get();
            if (animationWindow == null) return;
            var animEditor = animationWindow.animEditor;
            if (animEditor == null) return;

            animEditor.SaveCurveEditorKeySelection();
            var window = GetWindow<AnimationCurveManipulationWindow>();
            window.CheckKeySelection();

            var state = animEditor.state;
            int curveIndex = 0;
            float[] timeSnaps = null;
            KeyframeDataUtility.ApplyKeyframeCurves(window.selectedKeysOrdered, _curveGroup => {
                if (curveIndex == 0) {
                    timeSnaps = new float[_curveGroup.keyframes.Count];
                    for (int i = 0; i < _curveGroup.keyframes.Count; i++) {
                        if (i==0) {
                            timeSnaps[i] = state.currentTime;
                        }
                        else {
                            float delta = _curveGroup.keyframes[i].time - _curveGroup.keyframes[i-1].time;
                            timeSnaps[i] = timeSnaps[i - 1] + delta;
                        }
                    }
                }
                for (int i = 0; i < _curveGroup.keyframes.Count; i++) {
                    if (i < timeSnaps.Length) {
                        _curveGroup.keyframes[i].time = timeSnaps[i];
                    }
                    else {
                        float delta = _curveGroup.keyframes[i].time - _curveGroup.keyframes[timeSnaps.Length - 1].time;
                        _curveGroup.keyframes[i].time = timeSnaps[timeSnaps.Length - 1] + delta;
                    }
                }
                curveIndex++;
            });
        }

        private static bool TryGetLatestOrderedSelection(out List<AnimationWindowKeyframeBinding> _selectedKeysOrder, out AnimationClip _selectedClip, out AnimationWindowStateBinding _state) {
            _selectedClip = null;
            _selectedKeysOrder = null;
            _state = null;
            var animationWindow = AnimationWindowBinding.Get();
            if (animationWindow == null) return false;
            var animEditor = animationWindow.animEditor;
            if (animEditor == null) return false;
            var state = animEditor.state;
            if (state == null) return false;
            _selectedClip = state.activeAnimationClip;
            animEditor.SaveCurveEditorKeySelection();
            var window = GetWindow<AnimationCurveManipulationWindow>();
            window.CheckKeySelection();
            _selectedKeysOrder = window.selectedKeysOrdered;
            _state = state;
            return true;
        }

        private static void OffsetKeyframesOnEachObject() {
            if (!TryGetLatestOrderedSelection(out var _selectedKeysOrder, out var _selectedClip, out var _state)) return;
            int pathIndex = 0;
            KeyframeDataUtility.ApplyKeyframePaths(_selectedKeysOrder, _pathGroup => {
                for (int i = 0; i < _pathGroup.keyframes.Count; i++) {
                    _pathGroup.keyframes[i].time += 1.0f / _selectedClip.frameRate * pathIndex;
                }
                pathIndex++;
            });
        }

        private static void OffsetKeyframesOnEachProperty() {
            if (!TryGetLatestOrderedSelection(out var _selectedKeysOrder, out var _selectedClip, out var _state)) return;
            int curveIndex = 0;
            KeyframeDataUtility.ApplyKeyframeCurves(_selectedKeysOrder, _curveGroup => {
                if (curveIndex != 0) {
                    for (int i = 0; i < _curveGroup.keyframes.Count; i++) {
                        _curveGroup.keyframes[i].time += 1.0f / _selectedClip.frameRate * curveIndex;
                    }
                }
                curveIndex++;
            });
        }

        private static void ReverseKeyframes() {
            if (!TryGetLatestOrderedSelection(out var _selectedKeysOrder, out var _selectedClip, out var _state)) return;
            KeyframeDataUtility.ApplyKeyframeCurves(_selectedKeysOrder, _curveGroup => {
                var selectedKeyframes = _curveGroup.keyframes;
                if (selectedKeyframes.Count < 2) return;
                float range = GetKeyframesValueRange(selectedKeyframes, out var minVal);
                if (range == 0) {
                    return;
                }

                for (int i = 0; i < selectedKeyframes.Count; i++) {
                    float delta = selectedKeyframes[i].value - minVal;
                    float reversedDelta = range - delta;
                    selectedKeyframes[i].value = minVal + reversedDelta;
                }
            });
        }

        private static void MirrorKeyframes() {
            KeyframeDataUtility.PasteKeysMirrored();
        }

        private static void SetKeys() {
            SetKeysPopup.Show();
        }

        private static void AddProperties() {
            AddPropertiesPopup.Show();
        }

        private void DrawDebugger(Rect _area, int _curveCount, int _keyframeCount) {
            var rect = new Rect(_area.x, _area.y, _area.width, EditorGUIUtility.singleLineHeight);
            var animationWindow = AnimationWindowBinding.Get();
            if (animationWindow == null) {
                GUI.Label(rect, "No Animation Window Opened", EditorStyles.miniLabel);
                return;
            }
            var animEditor = animationWindow.animEditor;
            if (animEditor == null) return;

            var state = animEditor.state;
            if (state == null) return;

            selectedClip = state.activeAnimationClip;
            if (selectedClip == null) {
                GUI.Label(rect, "No animation clip selected", EditorStyles.miniLabel);
            }
            else {
                GUI.Label(rect, "Clip: " + selectedClip.name, EditorStyles.miniLabel);
                rect.y += rect.height;

                if (_curveCount > 0) {
                    GUI.Label(rect, "Selected Curves: " + _curveCount + " | Selected Keyframes: " + _keyframeCount, EditorStyles.miniLabel);
                }

            }

        }


        private void DrawRightSection(Rect _drawArea) {
            GUILayout.BeginArea(_drawArea);
            {
                var upperRect = EditorGUILayout.GetControlRect(GUILayout.ExpandWidth(true), GUILayout.Height(EditorGUIUtility.singleLineHeight * 4.5f));
                var exportLibraryRect = new Rect(upperRect.x + 0.7f * upperRect.width, upperRect.y, 0.3f * upperRect.width, upperRect.height);
                var savePresetRect = new Rect(upperRect.x, upperRect.y, upperRect.width - exportLibraryRect.width, upperRect.height);
                GUI.Box(savePresetRect, GUIContent.none, Styles.frameBoxStyle);
                GUI.Box(exportLibraryRect, GUIContent.none, Styles.frameBoxStyle);
                DrawKeyframeManipulationArea(savePresetRect);
                DrawExportLibraryArea(exportLibraryRect);

                GUILayout.Space(5);

                DrawTabs();

                var presetsRect = EditorGUILayout.GetControlRect(GUILayout.ExpandWidth(true), GUILayout.ExpandHeight(true));
                DrawPresetsArea(presetsRect);
            }
            GUILayout.EndArea();
        }

        private void DrawKeyframeManipulationArea(Rect _drawArea) {
            var guiColor = GUI.color;
            GUI.color = new Color(0.75f, 0.75f, 0.75f, 1);

            var currentRect = new Rect(_drawArea.x + 5, _drawArea.y + EditorGUIUtility.singleLineHeight * 0.6f, _drawArea.width - 10, EditorGUIUtility.singleLineHeight);
            GUI.Label(currentRect, "Keyframe Manipulation", EditorStyles.boldLabel);
            currentRect.y += currentRect.height;

            var lineRect = currentRect;
            lineRect.height = 1;
            GUI.DrawTexture(lineRect, EditorGUIUtility.whiteTexture);
            currentRect.y += 7;
            GUI.color = guiColor;

            var animationWindow = AnimationWindowBinding.Get();
            if (animationWindow == null) {
                GUI.Label(currentRect, "No Animation Window Opened", EditorStyles.centeredGreyMiniLabel);
                return;
            }
            var animEditor = animationWindow.animEditor;
            var curveEditor = animEditor.curveEditor;
            if (curveEditor == null) {
                GUI.Label(currentRect, "Click on \"Curve\" button on the Animation Window to initialize", EditorStyles.centeredGreyMiniLabel);
                return;
            }

            currentRect.height *= 2;
            currentRect.width /= 7;
            currentRect.width -= 2;

            var useIcons = !ReferenceEquals(config, null) && config.displayButtonIcon;
            if (useIcons) {
                DrawKeyframeIconButtons(currentRect);
            }
            else {
                DrawKeyframeTextButtons(currentRect);
            }
        }

        private void DrawKeyframeIconButtons(Rect _currentRect) {
            var guiEnabled = GUI.enabled;
            int selectedKeysCount = updateEachFrame? selectedKeysOrdered.Count : keyframeCount;
            GUI.enabled = guiEnabled && selectedKeysCount > 1;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.offsetIcon)) {
                OffsetKeyframesOnEachObject();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.offsetPlusIcon)) {
                OffsetKeyframesOnEachProperty();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            GUI.enabled = guiEnabled && hasAnyCurvePair;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.reverseIcon)) {
                ReverseKeyframes();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.mirrorIcon)) {
                MirrorKeyframes();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            GUI.enabled = guiEnabled && selectedKeysCount > 0;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.alignIcon)) {
                AlignKeyframes();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            GUI.enabled = guiEnabled && selectedClip != null;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.setKeyIcon)) {
                SetKeys();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.addPropIcon)) {
                AddProperties();
            }
            GUI.enabled = guiEnabled;
        }

        private void DrawKeyframeTextButtons(Rect _currentRect) {
            var guiEnabled = GUI.enabled;
            int selectedKeysCount = selectedKeysOrdered.Count;
            GUI.enabled = guiEnabled && selectedKeysCount > 1;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.offsetLabel)) {
                OffsetKeyframesOnEachObject();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.offsetPlusLabel)) {
                OffsetKeyframesOnEachProperty();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            GUI.enabled = guiEnabled && hasAnyCurvePair;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.reverseLabel)) {
                ReverseKeyframes();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.mirrorLabel)) {
                MirrorKeyframes();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            GUI.enabled = guiEnabled && selectedKeysCount > 0;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.alignLabel)) {
                AlignKeyframes();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            GUI.enabled = guiEnabled && selectedClip != null;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.setKeyLabel)) {
                SetKeys();
            }
            _currentRect.x += _currentRect.width + 2.5f;
            if (GUI.Button(_currentRect, CurveMasterGUIContents.addPropLabel)) {
                AddProperties();
            }
            GUI.enabled = guiEnabled;
        }

        private void DrawExportLibraryArea(Rect _drawArea) {
            var guiColor = GUI.color;
            GUI.color = new Color(0.75f, 0.75f, 0.75f, 1);

            var currentRect = new Rect(_drawArea.x + 5, _drawArea.y + EditorGUIUtility.singleLineHeight * 0.6f, _drawArea.width - 10, EditorGUIUtility.singleLineHeight);
            GUI.Label(currentRect, "Export Library", EditorStyles.boldLabel);
            currentRect.y += currentRect.height;

            var lineRect = currentRect;
            lineRect.height = 1;
            GUI.DrawTexture(lineRect, EditorGUIUtility.whiteTexture);
            currentRect.y += 7;
            GUI.color = guiColor;

            if (GUI.Button(currentRect, "Import")) {
                var filePath = EditorUtility.OpenFilePanel("Import Library", Application.dataPath, "json");
                if (!string.IsNullOrEmpty(filePath)) {
                    Undo.RecordObject(config, "import curve library");
                    var json = File.ReadAllText(filePath);
                    var imported = CurveLibrary.FromJSON(json);
                    bool foundExisting = false;
                    for (int i=0; i< config.curveLibraries.Count; i++) {
                        var library = config.curveLibraries[i];
                        if (library.Compare(imported)) {
                            foundExisting = true;
                            int index = i;
                            if (EditorUtility.DisplayDialog("Library Already Exists", "Are you sure you want replace " + imported.libraryName + "?", "Replace", "Cancel")) {
                                config.curveLibraries[index] = imported;
                            }
                            break;
                        }
                    }
                    if (!foundExisting) {
                        config.curveLibraries.Add(imported);
                        EditorUtility.SetDirty(config);
#if UNITY_2021_3_OR_NEWER
                        AssetDatabase.SaveAssetIfDirty(config);
#else
                        AssetDatabase.SaveAssets();
#endif
                    }
                }
            }
            currentRect.y += currentRect.height + 2;

            var guiEnabled = GUI.enabled;
            GUI.enabled = guiEnabled && currentLibraryIndex >= 0 && currentLibraryIndex < config.curveLibraries.Count;
            if (GUI.Button(currentRect, "Export")) {
                var currentLibrary = config.curveLibraries[currentLibraryIndex];
                var filePath = EditorUtility.SaveFilePanel("Export Library", Application.dataPath, currentLibrary.libraryName, "json");
                if (!string.IsNullOrEmpty(filePath)) {
                    var json = currentLibrary.ToJSON();
                    File.WriteAllText(filePath, json);
                    AssetDatabase.Refresh();
                }
            }
            GUI.enabled = guiEnabled;
        }

        private void DrawTabs() {
            tabsScrollPos = GUILayout.BeginScrollView(tabsScrollPos, GUILayout.Height(30));
            GUILayout.BeginHorizontal();
            GUILayout.Space(5);

            if (config != null) {
                for (int i = 0; i < config.curveLibraries.Count; i++) {
                    var library = config.curveLibraries[i];
                    var buttonRect = EditorGUILayout.GetControlRect(false, 16, i == currentLibraryIndex ? Styles.tabSelected : Styles.tabUnselected);

                    if (i == libraryIndexToRename) {
                        HandleRenameLibrary(library, buttonRect, i);
                    }
                    else {
                        var e = Event.current;
                        if (e.type == EventType.MouseDown && e.button == 1) {
                            if (buttonRect.Contains(e.mousePosition)) {
                                var tabContextMenu = new GenericMenu();
                                int index = i;
                                tabContextMenu.AddItem(new GUIContent("Rename"), false, () => {
                                    libraryIndexToRename = index;
                                });
                                tabContextMenu.AddSeparator("");
                                tabContextMenu.AddItem(new GUIContent("Remove"), false, () => {
                                    if (EditorUtility.DisplayDialog("Remove Library", "Are you sure you want to remove Curve Library: " + library.libraryName + "?", "Remove", "Cancel")) {
                                        Undo.SetCurrentGroupName("remove curve library");
                                        Undo.RecordObject(config, "remove curve library");
                                        config.curveLibraries.RemoveAt(index);
                                        EditorUtility.SetDirty(config);
                                        if (currentLibraryIndex >= config.curveLibraries.Count) {
                                            Undo.RecordObject(this, "remove curve library");
                                            currentLibraryIndex = config.curveLibraries.Count - 1;
                                            if (currentLibraryIndex <= 0) currentLibraryIndex = 0;
                                        }
                                    }
                                });
                                tabContextMenu.ShowAsContext();
                                e.Use();
                            }
                        }
                        if (GUI.Button(buttonRect, library.libraryName, i == currentLibraryIndex ? Styles.tabSelected : Styles.tabUnselected)) {
                            currentLibraryIndex = i;
                        }
                    }
                }
                if (GUILayout.Button("  + Add Library  ", Styles.tabUnselected)) {
                    Undo.RecordObject(config, "add curve library");
                    config.curveLibraries.Add(new CurveLibrary());
                    EditorUtility.SetDirty(config);
                }
            }

            GUILayout.Space(5);
            GUILayout.EndHorizontal();
            GUILayout.EndScrollView();
        }

        private void HandleRenameLibrary(CurveLibrary _library, Rect _buttonRect, int _index) {
            var e = Event.current;
            EditorGUI.BeginChangeCheck();
            GUI.SetNextControlName("RenameLibrary-" + _index);
            var newLibraryName = EditorGUI.DelayedTextField(_buttonRect, _library.libraryName);
            GUI.FocusControl("RenameLibrary-" + _index);

            bool finishRename = false;
            if (EditorGUI.EndChangeCheck()) {
                finishRename = true;
            }
            else if ((e.type == EventType.KeyUp || e.type == EventType.KeyDown) && (e.keyCode == KeyCode.Return || e.keyCode == KeyCode.KeypadEnter)) {
                finishRename = true;
            }
            else if (e.type == EventType.MouseDown && !_buttonRect.Contains(e.mousePosition)) {
                finishRename = true;
            }
            if (finishRename) {
                Undo.RecordObject(config, "rename curve library");
                _library.libraryName = newLibraryName;
                EditorUtility.SetDirty(config);
                libraryIndexToRename = -1;
                GUI.FocusControl(null);
                Repaint();
            }
        }

        private void DrawPresetsArea(Rect _drawArea) {
            if (ReferenceEquals(config, null)) return;

            if (currentLibraryIndex < 0 || currentLibraryIndex >= config.curveLibraries.Count) return;
            var currentLibrary = config.curveLibraries[currentLibraryIndex];

            int childCount = currentLibrary.curvePresets.Count + 1;
            float childSize = 80f; // constant size of child rect

            int cols = Mathf.FloorToInt(_drawArea.width / childSize);
            int rows = Mathf.CeilToInt(childCount / (float)cols);

            var backgroundRect = _drawArea;
            backgroundRect.width = cols * childSize;

            var viewArea = new Rect(_drawArea.x, _drawArea.y, cols * childSize, rows * childSize);
            presetsScrollPos = GUI.BeginScrollView(_drawArea, presetsScrollPos, viewArea);

            Vector2 startPointInv = new Vector2(0, 1);
            Vector2 endPointInv = new Vector2(1, 0);

            int currentIndex = 0;
            for (int row = 0; row < rows; row++) {
                if (currentIndex >= childCount) break;
                for (int col = 0; col < cols; col++) {
                    if (currentIndex >= childCount) break;

                    Rect childRect = new Rect(
                        _drawArea.x + col * childSize,
                        _drawArea.y + row * childSize,
                        childSize,
                        childSize
                    );

                    // Draw the child rect here
                    if (currentIndex == childCount-1) {
                        if (GUI.Button(childRect, GUIContent.none)) {
                            Undo.RecordObject(config, "create new curve preset");
                            var newPreset = new CurvePreset(cubicBezierEditor.GetValue());
                            currentLibrary.curvePresets.Add(newPreset);
                            EditorUtility.SetDirty(config);
                        }
                        GUI.Label(childRect, new GUIContent("+"), Styles.largeText);
                    }
                    else {
                        var guiColor = GUI.color;
                        GUI.color = currentPresetIndex == currentIndex ? Color.white : Color.grey;

                        var currentPreset = currentLibrary.curvePresets[currentIndex];

                        GUI.Box(childRect, GUIContent.none, Styles.boxBackground);
                        Vector2 startTangentInv = new Vector2(currentPreset.curveValue[0], 1 - currentPreset.curveValue[1]);
                        Vector2 endTangentInv = new Vector2(currentPreset.curveValue[2], 1 - currentPreset.curveValue[3]);

                        var curveRect = new Rect(childRect.x + 14, childRect.y + 8, childRect.width - 28, childRect.height - 28);
                        var nameRect = new Rect(childRect.x + 2, childRect.y + childRect.height - EditorGUIUtility.singleLineHeight, childRect.width - 4, EditorGUIUtility.singleLineHeight);

                        Handles.BeginGUI();
                        Handles.DrawBezier(
                            curveRect.position + startPointInv * curveRect.size,
                            curveRect.position + endPointInv * curveRect.size,
                            curveRect.position + startTangentInv * curveRect.size,
                            curveRect.position + endTangentInv * curveRect.size,
                            Color.white,
                            null,
                            2f
                        );
                        Handles.EndGUI();
                        GUI.color = guiColor;

                        if (currentIndex == presetIndexToRename) {
                            HandleRenamePreset(currentPreset, nameRect, currentIndex);
                        }
                        else {
                            GUI.Box(nameRect, new GUIContent(currentPreset.presetName), EditorStyles.centeredGreyMiniLabel);
                        }

                        var e = Event.current;
                        if (e.type == EventType.MouseDown) {
                            if (e.button == 0) {
                                if (e.clickCount == 1) {
                                    if (curveRect.Contains(e.mousePosition)) {
                                        Undo.RecordObject(this, "select curve preset");
                                        currentPresetIndex = currentIndex;
                                        cubicBezierEditor.SetValue(currentPreset.curveValue);
                                        e.Use();
                                    }
                                }
                                else if (e.clickCount == 2) {
                                    if (nameRect.Contains(e.mousePosition)) {
                                        presetIndexToRename = currentIndex;
                                        e.Use();
                                    }
                                }
                            }
                            else if (e.button == 1) {
                                if (childRect.Contains(e.mousePosition)) {
                                    var presetContextMenu = new GenericMenu();
                                    var preset = currentPreset;
                                    presetContextMenu.AddItem(new GUIContent("Save"), false, () => {
                                        Undo.RecordObject(config, "save curve preset");
                                        preset.curveValue = cubicBezierEditor.GetValue();
                                        EditorUtility.SetDirty(config);
                                    });
                                    var index = currentIndex;
                                    presetContextMenu.AddItem(new GUIContent("Rename"), false, () => {
                                        presetIndexToRename = index;
                                    });
                                    presetContextMenu.AddSeparator("");
                                    presetContextMenu.AddItem(new GUIContent("Remove"), false, () => {
                                        if (EditorUtility.DisplayDialog("Remove Preset", "Are you sure you want to remove Curve Preset: " + preset.presetName + "?", "Remove", "Cancel")) {
                                            Undo.RecordObject(config, "remove curve preset");
                                            currentLibrary.curvePresets.RemoveAt(index);
                                            EditorUtility.SetDirty(config);
                                        }
                                    });
                                    presetContextMenu.ShowAsContext();
                                }
                            }
                        }
                    }
                    currentIndex++;

                }
            }

            GUI.EndScrollView();
        }

        private void HandleRenamePreset(CurvePreset _preset, Rect _rect, int _index) {
            var e = Event.current;
            EditorGUI.BeginChangeCheck();
            GUI.SetNextControlName("RenamePreset-" + _index);
            var newPresetName = EditorGUI.DelayedTextField(_rect, _preset.presetName);
            GUI.FocusControl("RenamePreset-" + _index);

            bool finishRename = false;
            if (EditorGUI.EndChangeCheck()) {
                finishRename = true;
            }
            else if ((e.type == EventType.KeyUp || e.type == EventType.KeyDown) && (e.keyCode == KeyCode.Return || e.keyCode == KeyCode.KeypadEnter)) {
                finishRename = true;
            }
            else if (e.type == EventType.MouseDown && !_rect.Contains(e.mousePosition)) {
                finishRename = true;
            }
            if (finishRename) {
                Undo.RecordObject(config, "rename curve preset");
                _preset.presetName = newPresetName;
                EditorUtility.SetDirty(config);
                presetIndexToRename = -1;
                GUI.FocusControl(null);
                Repaint();
            }
        }

    }

}
