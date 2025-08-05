import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { setDirectionalMagnitude } from '../effects.ts'
import { simpleRotationPath } from '../effects.ts'
import { assignDirectionalRotation } from '../effects.ts'
import { noteHop, wheelEffect } from '../effects.ts'
import { prefabs } from "../main.ts";
import { approximately, beatsToObjectSpawnLife, between } from '../utilities.ts'

export function outro(map: rm.V3Difficulty)
{
    const outroScene = prefabs.outro.instantiate(map, TIMES.OUTRO)

    doNotemods(map)

    outroScene.destroyObject(TIMES.MAP_END)
}

function doNotemods(map: rm.V3Difficulty) {
    const OUTRO_NOTE_TRACK = 'outroNote'

    const WHEEL_EFFECT_TRACK = 'outroWheelTrack'
    const WHEEL_LIFE = 8
    const wheelFromBeat = beatsToObjectSpawnLife(WHEEL_LIFE)

    applyWhiteNotes(0)
    setDirectionalMagnitude(map, 20, 575)

    const outroRotationMovement = simpleRotationPath(map, OUTRO_NOTE_TRACK)

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

    rm.assignPathAnimation(map, {
        track: WHEEL_EFFECT_TRACK,
        beat: 575 - 10,
        animation: {
            dissolve: [[0,wheelFromBeat(4)],[1,wheelFromBeat(2)]]
        }
    })

    rm.assignPathAnimation(map, {
        track: WHEEL_EFFECT_TRACK,
        beat: 575,
        animation: {
            dissolve: [1]
        }
    })

    applyBlackNotes(575)
    map.allNotes.filter(approximately(575)).forEach(x => {
        noteHop(x)
    })

    outroRotationMovement(573, [[4,-4,0,0],[0,0,0,0.5]])
    outroRotationMovement(573, [0,0,0], 2, 'easeOutBack')
    
    wheelEffect(map, 10, [575, 576, 578, 579, 581])
    map.allNotes.filter(between(576, 581)).forEach(x => {
        x.life = WHEEL_LIFE
        x.track.add(WHEEL_EFFECT_TRACK)
    })

    applyWhiteNotes(581)

    map.allNotes.filter(between(583, 589)).forEach(x => {
        noteHop(x, 10)
        assignDirectionalRotation(x)
    })
}