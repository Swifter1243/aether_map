import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { bokeh } from "../effects.ts";
import { materials, prefabs } from "../main.ts";
import { between } from '../utilities.ts'

export function intro(map: rm.V3Difficulty) {
    const introScene = prefabs.intro.instantiate(map, TIMES.INTRO)

    doNotemods(map)
    
    bokeh(materials.introbokeh, map, TIMES.INTRO1, 10, 15)
    bokeh(materials.introbokeh, map, TIMES.INTRO2, 10, 15)

    introScene.destroyObject(TIMES.DROP)
}

function doNotemods(map: rm.V3Difficulty) {
    const INTRO_TRACK = 'intro'

    map.allNotes.filter(between(0, 77)).forEach(x => {
        x.track.add(INTRO_TRACK)
    })

    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: INTRO_TRACK,
            asset: prefabs['terrain note'].path,
            debrisAsset: prefabs['terrain note debris'].path,
            anyDirectionAsset: prefabs['terrain note dot'].path
        }
    })

    const terrainMats = [
        materials['terrain note'],
        materials['terrain note debris']
    ]

    terrainMats.forEach(m => {
        m.set(map, {
            _AmbientStrength: 0,
            _SunStrength: 0
        }, 0)

        m.set(map, {
            _AmbientStrength: m.defaults._AmbientStrength,
            _SunStrength: m.defaults._SunStrength
        }, 5)
    })
}