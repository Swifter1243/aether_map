import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { setFakeJumps } from '../effects.ts'
import { applyFakeJumps } from '../effects.ts'
import { simpleRotationPath } from '../effects.ts'
import { bokeh } from "../effects.ts";
import { materials, prefabs } from "../main.ts";
import { beatsToObjectSpawnLife, between } from '../utilities.ts'

export function intro(map: rm.V3Difficulty) {
    const introScene = prefabs.intro.instantiate(map, TIMES.INTRO)

    doNotemods(map)
    
    bokeh(materials.introbokeh, map, TIMES.INTRO1, 10, 15)
    bokeh(materials.introbokeh, map, TIMES.INTRO2, 10, 15)

    introScene.destroyObject(TIMES.DROP)
}

function doNotemods(map: rm.V3Difficulty) {
    const INTRO_TRACK = 'intro'
    const JUMPS_CONTEXT = setFakeJumps(map, 0, {
        jumpInBeat: 4,
        jumpInDuration: 4,
        objectLife: 8 * 2
    })

    const introRotationMovement = simpleRotationPath(map, INTRO_TRACK)
    const jumpsToBeat = beatsToObjectSpawnLife(JUMPS_CONTEXT.objectLife)

    rm.assignPathAnimation(map, {
        track: INTRO_TRACK,
        beat: 0,
        animation: {
            dissolve: [[0, jumpsToBeat(8)], [1, jumpsToBeat(4)]]
        }
    })

    rm.assignPathAnimation(map, {
        track: INTRO_TRACK,
        beat: 5,
        animation: {
            dissolve: [1]
        }
    })

    map.allNotes.filter(between(0, 77)).forEach(x => {
        x.track.add(INTRO_TRACK)
        x.life = JUMPS_CONTEXT.objectLife
        applyFakeJumps(x, rm.random, JUMPS_CONTEXT)
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

    introRotationMovement(0, [[7,3,0,0,'easeInOutSine'],[-3,-1,0,0.25,'easeInOutSine'],[0,0,0,0.5,'easeInOutSine']])

    const rotationRandom = rm.seededRandom(38)

    for (let b = 0; b <= 64 - 10; b += 10) {
        introRotationMovement(b, [
            [rotationRandom(-10, 10),rotationRandom(-3, 3),0,0,'easeInOutSine'],
            [rotationRandom(-5, 5),rotationRandom(-1, 1),0,0.25,'easeInOutSine'],
            [0,0,0,0.5,'easeInOutSine']
        ], 10, 'easeInOutSine')
    }

    rm.assignPathAnimation(map, {
        track: INTRO_TRACK,
        animation: {
            offsetPosition: [0,0,0]
        }
    })

    rm.assignPathAnimation(map, {
        beat: 64 - 5/2,
        duration: 5,
        easing: 'easeInOutBack',
        track: INTRO_TRACK,
        animation: {
            offsetPosition: [[0,0,50,0],[0,0,0,jumpsToBeat(JUMPS_CONTEXT.jumpInBeat)]]
        }
    })

    introRotationMovement(64 - 2, [[5,3,0,0,'easeInOutSine'],[-3,-1,0,0.25,'easeInOutSine'],[0,0,0,0.5,'easeInOutSine']], 4, 'easeInOutBack')
}