import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { setDirectionalMagnitude } from '../effects.ts'
import { assignDirectionalRotation } from '../effects.ts'
import { noteHop, wheelEffect } from '../effects.ts'
import { prefabs } from "../main.ts";
import { approximately, between } from '../utilities.ts'

export function outro(map: rm.V3Difficulty)
{
    const outroScene = prefabs.outro.instantiate(map, TIMES.OUTRO)

    doNotemods(map)

    outroScene.destroyObject(TIMES.MAP_END)
}

function doNotemods(map: rm.V3Difficulty) {
    const OUTRO_NOTE_TRACK = 'outroNote'
    applyWhiteNotes(0)
    setDirectionalMagnitude(map, 20, 575)

    map.allNotes.filter(between(575, TIMES.MAP_END)).forEach(x => {
        x.track.add(OUTRO_NOTE_TRACK)
    })

    function applyWhiteNotes(beat: number) {
        rm.assignObjectPrefab(map, {
            beat,
            colorNotes: {
                track: OUTRO_NOTE_TRACK,
                asset: prefabs['white outline note'].path,
                debrisAsset: prefabs['white outline note debris'].path
            }
        })
    }

    function applyBlackNotes(beat: number) {
        rm.assignObjectPrefab(map, {
            beat,
            colorNotes: {
                track: OUTRO_NOTE_TRACK,
                asset: prefabs['black outline note'].path,
                debrisAsset: prefabs['black outline note debris'].path
            }
        })
    }

    applyBlackNotes(575)
    map.allNotes.filter(approximately(575)).forEach(x => {
        noteHop(x)
    })

    wheelEffect(map, 10, [575, 576, 578, 579, 581])

    applyWhiteNotes(581)

    map.allNotes.filter(between(583, 589)).forEach(x => {
        noteHop(x)
        assignDirectionalRotation(x)
    })
}