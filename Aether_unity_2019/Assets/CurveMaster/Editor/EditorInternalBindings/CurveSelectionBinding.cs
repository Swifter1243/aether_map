using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Reflection;

namespace AnimationCurveManipulationTool {

    public class CurveSelectionBinding {

        public enum SelectionType {
            Key = 0,
            InTangent = 1,
            OutTangent = 2,
            Count = 3,
        }

        private object objectReference;

        public CurveSelectionBinding(object _objectReference) {
            objectReference = _objectReference;
        }

        public int curveId {
            get {
                return (int)objectReference.GetType()
                    .GetField("curveID", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public int key {
            get {
                return (int)objectReference.GetType()
                    .GetField("key", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public bool semiSelected {
            get {
                return (bool)objectReference.GetType()
                    .GetField("semiSelected", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }

        public SelectionType type {
            get {
                return (SelectionType)objectReference.GetType()
                    .GetField("type", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .GetValue(objectReference);
            }
        }
        public override int GetHashCode() {
            return (int)objectReference.GetType()
                    .GetMethod("GetHashCode", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .Invoke(objectReference, new object[0]);
        }

    }

}
