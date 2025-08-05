import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { prefabs } from "../main.ts";
import { between } from '../utilities.ts'

export function outro(map: rm.V3Difficulty)
{
    const outroScene = prefabs.outro.instantiate(map, TIMES.OUTRO)

    doNotemods(map)

    outroScene.destroyObject(TIMES.MAP_END)
}

function doNotemods(map: rm.V3Difficulty) {
    const OUTRO_NOTE_TRACK = 'outroNote'

    map.allNotes.filter(between(575, TIMES.MAP_END)).forEach(x => {
        x.track.add(OUTRO_NOTE_TRACK)
    })
}