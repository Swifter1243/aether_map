import { TIMES } from '../constants.ts'
import { rm } from '../deps.ts'
import { fadeWhite } from '../effects.ts'
import { prefabs } from '../main.ts'
import { approximately, between } from '../utilities.ts'

export function drop(map: rm.V3Difficulty) {
    const dropScene = prefabs.drop.instantiate(map, TIMES.DROP)

    doNotemods(map)

    fadeWhite(map, TIMES.DROP_END, 16)

    dropScene.destroyObject(TIMES.DROP_END)
}

function noteHop(x: rm.AnyNote, duration = 2) {
    x.noteJumpMovementSpeed = 0.002
    x.life = duration * 2
    x.disableNoteGravity = true
    x.animation.dissolve = [[0, 0], [1, 0]]
    x.animation.dissolveArrow = x.animation.dissolve
    x.animation.offsetPosition = [
        [0, 0, 5, 0],
        [0, 0, 12, 0.25, 'easeOutCirc'],
        [0, 0, 0, 0.5, 'easeInSine'],
        [0, 0, -30, 1, 'easeLinear'],
    ]
}

function doNotemods(map: rm.V3Difficulty) {
    const DROP_MOVEMENT_TRACK = 'dropMovement'

    map.allNotes.filter(between(TIMES.DROP, TIMES.DROP_END)).forEach((x) => {
        x.track.add(DROP_MOVEMENT_TRACK)
        x.disableNoteGravity = true
        
        if (!(x instanceof rm.Arc || x instanceof rm.Chain)) {
            x.spawnEffect = false
        }
    })

    rm.assignPathAnimation(map, {
        beat: 7,
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [[-10,-4,0,0], [2, -2, 0, 0.5,'easeOutSine']],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 89,
        track: DROP_MOVEMENT_TRACK,
        duration: 4,
        easing: 'easeOutBack',
        animation: {
            offsetWorldRotation: [0, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 91,
        track: DROP_MOVEMENT_TRACK,
        duration: 4,
        easing: 'easeOutBack',
        animation: {
            offsetWorldRotation: [-5, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 91,
        track: DROP_MOVEMENT_TRACK,
        duration: 4,
        easing: 'easeInOutBack',
        animation: {
            offsetWorldRotation: [5, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 95,
        track: DROP_MOVEMENT_TRACK,
        duration: 2,
        easing: 'easeOutExpo',
        animation: {
            offsetWorldRotation: [[-2, 0, 20,0],[-2, 0, 0,0.5]]
        },
    })

    rm.assignPathAnimation(map, {
        beat: 97,
        track: DROP_MOVEMENT_TRACK,
        duration: 4,
        easing: 'easeOutBack',
        animation: {
            offsetWorldRotation: [0, 0, 0]
        },
    })

    map.allNotes.filter(between(91, 93)).forEach((x) => {
        noteHop(x)

        const left = x.x < 2 ? -1 : 1
        const up = approximately(93)(x)
        // x.animation.offsetWorldRotation = [
        //     [up ? -10 : 0, 10 * left, 0, 0],
        //     [0, 0, 0, 0.5, 'easeOutExpo'],
        // ]
    })

    map.allNotes.filter(between(95, 97)).forEach((x) => {
        noteHop(x)
    })

    map.allNotes.filter(between(99, 101)).forEach((x) => {
        noteHop(x)
    })
}
