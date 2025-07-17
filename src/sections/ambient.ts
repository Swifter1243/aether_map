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
    doDisappearing()

    function doDisappearing() {
        const DISAPPEAR_BEAT_START = 306.01
        const DISAPPEAR_DURATION = 20
        const DISAPPEAR_TRACK = "disappeared"

        const disappeared = between(DISAPPEAR_BEAT_START, DISAPPEAR_BEAT_START + DISAPPEAR_DURATION)
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