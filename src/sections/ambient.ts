import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { bokeh } from "../effects.ts";
import { materials, prefabs } from "../main.ts";
import { between } from "../utilities.ts"

export function ambient(map: rm.V3Difficulty)
{
    const ambientScene = prefabs.ambient.instantiate(map, TIMES.DROP_END)

    bokeh(materials["261 - bokeh"], map, TIMES.DROP_END, 10, 4)

    doNotemods(map)

    ambientScene.destroyObject(TIMES.BRIDGE)
}

function doNotemods(map: rm.V3Difficulty) {
    const START = 261.1
    const END = 362

    const AMBIENT_TRACK = "ambientNote"

    const isInAmbient = between(START, END)
    map.allNotes.filter(isInAmbient).forEach(x => {
        x.life = 10
        x.track.add(AMBIENT_TRACK)
    })

    doPaths()
    doDisappearing()

    function doPaths() {
        const setPath = (beat: number, animation: rm.AssignPathAnimationData) => {
            rm.assignPathAnimation(map, {
                track: AMBIENT_TRACK,
                beat,
                animation
            })
        }
        const setSimpleRotationPath = (beat: number, startingVec: rm.Vec3) => {
            setPath(beat, {
                offsetWorldRotation: [
                    [...startingVec, 0],
                    [0, 0, 0, 0.5]
                ]
            })
        }

        setSimpleRotationPath(261, [-20, 0, 0])
        setSimpleRotationPath(285, [20, 10, 0])
        setSimpleRotationPath(306, [10, -5, 0])
        setSimpleRotationPath(325.5, [-3, 20, 0])
        setSimpleRotationPath(341, [2, -8, 0])
        setSimpleRotationPath(353, [0, 0, 0])
    }

    function doDisappearing() {
        const DISAPPEAR_BEAT_START = 306.01
        const DISAPPEAR_BEAT_END = 325
        const DISAPPEAR_TRACK = "disappeared"

        const disappeared = between(DISAPPEAR_BEAT_START, DISAPPEAR_BEAT_END)
        map.allNotes.filter(disappeared).forEach(x => {
            x.track.add(DISAPPEAR_TRACK)
            if (!(x instanceof rm.Arc)) {
                x.fake = true
            }
        })
        rm.animateTrack(map, {
            beat: DISAPPEAR_BEAT_START,
            track: DISAPPEAR_TRACK,
            animation: {
                offsetPosition: [0, -69240, 0]
            }
        })
    }
}