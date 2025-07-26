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
        x.animation.dissolve = [[0,0],[1,0.1]]
        x.animation.dissolveArrow = x.animation.dissolve
        
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
        easing: 'easeOutExpo',
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

    const ARROW_MOVEMENT_LEFT_TRACK = 'arrowMovementLeft'
    const ARROW_MOVEMENT_RIGHT_TRACK = 'arrowMovementRight'

    rm.assignPathAnimation(map, {
        beat: 89,
        track: ARROW_MOVEMENT_LEFT_TRACK,
        animation: {
            offsetWorldRotation: [
                [0, -5, 0, 0],
                [0, 0, 0, 0.5, 'easeOutExpo']
            ]
        }
    })
    rm.assignPathAnimation(map, {
        beat: 89,
        track: ARROW_MOVEMENT_RIGHT_TRACK,
        animation: {
            offsetWorldRotation: [
                [0, 5, 0, 0],
                [0, 0, 0, 0.5, 'easeOutExpo']
            ]
        }
    })

    const isHopNote = (x: rm.BeatmapObject) => 
        between(91, 93)(x) ||
        between(95, 97)(x) ||
        between(99, 101)(x) ||
        approximately(109)(x)

    map.allNotes.filter(isHopNote).forEach((x) => {
        noteHop(x)

        if (!(x instanceof rm.Bomb)) {
            const left = x.color === rm.NoteColor.RED
            x.track.add(left ? ARROW_MOVEMENT_LEFT_TRACK : ARROW_MOVEMENT_RIGHT_TRACK)
        }
    })

    const DARK_NOTES_TRACK = 'dropDarkNotesTrack'

    rm.assignPathAnimation(map, {
        track: DARK_NOTES_TRACK,
        animation: {
            dissolve: [[0,0],[1,0.2]],
            dissolveArrow: [[0,0],[1,0.2]],
            offsetWorldRotation: [[0,0,90,0],[0,0,0,0.5]],
            offsetPosition: [0,0,4]
        }
    })

    rm.assignPathAnimation(map, {
        beat: 101,
        duration: 1,
        easing: 'easeOutExpo',
        track: DARK_NOTES_TRACK,
        animation: {
            dissolve: [[0,0],[1,0.5,'easeOutExpo']],
            dissolveArrow: [[0,0],[1,0.5,'easeOutExpo']],
            offsetPosition: [0,0,0]
        }
    })
    rm.assignPathAnimation(map, {
        beat: 101,
        duration: 3,
        easing: 'easeOutBack',
        track: DARK_NOTES_TRACK,
        animation: {
            offsetWorldRotation: [0,0,0],
        }
    })

    rm.assignPathAnimation(map, {
        beat: 105,
        duration: 2,
        easing: 'easeInCirc',
        track: DARK_NOTES_TRACK,
        animation: {
            offsetPosition: [[0,0,50,0],[0,0,0,0.5]],
            offsetWorldRotation: [[0,0,30,0],[0,0,0,0.5]]
        }
    })

    map.allNotes.filter(between(102, 107)).forEach((x) => {
        x.track.add(DARK_NOTES_TRACK)
        x.noteJumpMovementSpeed = 10
        x.life = 5
    })

    rm.assignPathAnimation(map, {
        beat: 107,
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [[0,0,-50,0],[0,0,0,0.5]]
        }
    })

    rm.assignPathAnimation(map, {
        beat: 107,
        duration: 4,
        easing: 'easeOutCirc',
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [0,0,0]
        }
    })

    rm.assignPathAnimation(map, {
        beat: 109,
        duration: 4,
        easing: 'easeOutCirc',
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [10,0,0]
        }
    })

    rm.assignPathAnimation(map, {
        beat: 111,
        duration: 4,
        easing: 'easeOutBack',
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [0,0,0]
        }
    })
}
