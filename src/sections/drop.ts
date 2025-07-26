import { TIMES } from '../constants.ts'
import { rm } from '../deps.ts'
import { fadeWhite } from '../effects.ts'
import { prefabs } from '../main.ts'
import { approximately, between, join } from '../utilities.ts'

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

function wheelEffect(map: rm.V3Difficulty, yIncrement: number, times: number[]) {
    const start = times.reduce((a, b) => Math.min(a, b))
    const end = times.reduce((a, b) => Math.max(a, b))
    const notes = map.allNotes.filter(between(start, end))

    const timeGroups: Record<number, rm.AnyNote[]> = rm.arraySplit2(notes, (x) => {
        let time = 0

        times.forEach((t) => {
            if (x.beat >= t) {
                time = t
            }
        })

        return time
    })

    const accumulatedTracks: string[] = []

    Object.entries(timeGroups)
        .sort((a, b) => parseFloat(a[0]) - parseFloat(b[0]))
        .forEach(([_, timeNotes], i) => {
            if (i === 0) {
                return
            }

            const beat = times[i - 1]
            const track = `wheelNote${i}`
            accumulatedTracks.push(track)
            const tracks = rm.copy(accumulatedTracks)
            
            const shakeX = rm.random(-1, 1)

            rm.assignPathAnimation(map, {
                beat: start - timeNotes[0].life / 2 - 0.1,
                track: track,
                animation: {
                    offsetWorldRotation: [[shakeX, yIncrement * 2, 0, 0], [shakeX, yIncrement, 0, 0.5]],
                },
            })

            rm.assignPathAnimation(map, {
                beat,
                duration: 2,
                easing: 'easeOutExpo',
                track: track,
                animation: {
                    offsetWorldRotation: [0, 0, 0],
                },
            })

            timeNotes.forEach((x) => {
                x.track.add(tracks)
            })
        })
}

function doNotemods(map: rm.V3Difficulty) {
    const DROP_MOVEMENT_TRACK = 'dropMovement'

    map.allNotes.filter(between(TIMES.DROP, TIMES.DROP_END)).forEach((x) => {
        x.track.add(DROP_MOVEMENT_TRACK)
        x.disableNoteGravity = true
        x.animation.dissolve = [[0, 0], [1, 0.1]]
        x.animation.dissolveArrow = x.animation.dissolve

        if (!(x instanceof rm.Arc || x instanceof rm.Chain)) {
            x.spawnEffect = false
        }
    })

    const WHEEL_EFFECT_TRACK = 'wheelEffect'

    rm.animateTrack(map, {
        beat: 70,
        track: WHEEL_EFFECT_TRACK,
        animation: {
            dissolve: [0],
            dissolveArrow: [0]
        }
    })

    rm.assignPathAnimation(map, {
        beat: 80,
        track: DROP_MOVEMENT_TRACK,
        duration: 3,
        easing: 'easeOutBack',
        animation: {
            offsetWorldRotation: [[0,-30,0,0],[0,0,0,0.5]],
        }
    })

    rm.animateTrack(map, {
        beat: 79,
        track: WHEEL_EFFECT_TRACK,
        animation: {
            dissolve: [1],
            dissolveArrow: [1]
        }
    })

    wheelEffect(map, 5, [80, 81, 81.75, 82.25, 83, 84.25, 85])
    map.allNotes.filter(between(81, 85)).forEach(x => {
        x.life = 8
        x.track.add(WHEEL_EFFECT_TRACK)
    })
    
    rm.assignPathAnimation(map, {
        beat: 85,
        duration: 3,
        easing: 'easeOutExpo',
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [2, -3, 0],
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
            offsetWorldRotation: [[-2, 0, 20, 0], [-2, 0, 0, 0.5]],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 97,
        track: DROP_MOVEMENT_TRACK,
        duration: 4,
        easing: 'easeOutBack',
        animation: {
            offsetWorldRotation: [0, 0, 0],
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
                [0, 0, 0, 0.5, 'easeOutExpo'],
            ],
        },
    })
    rm.assignPathAnimation(map, {
        beat: 89,
        track: ARROW_MOVEMENT_RIGHT_TRACK,
        animation: {
            offsetWorldRotation: [
                [0, 5, 0, 0],
                [0, 0, 0, 0.5, 'easeOutExpo'],
            ],
        },
    })

    const isHopNote = join(
        approximately(87),
        approximately(89),
        between(91, 93),
        between(95, 97),
        between(99, 101),
        approximately(109)
    )

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
            dissolve: [[0, 0], [1, 0.2]],
            dissolveArrow: [[0, 0], [1, 0.2]],
            offsetWorldRotation: [[0, 0, 90, 0], [0, 0, 0, 0.5]],
            offsetPosition: [0, 0, 4],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 101,
        duration: 1,
        easing: 'easeOutExpo',
        track: DARK_NOTES_TRACK,
        animation: {
            dissolve: [[0, 0], [1, 0.5, 'easeOutExpo']],
            dissolveArrow: [[0, 0], [1, 0.5, 'easeOutExpo']],
            offsetPosition: [0, 0, 0],
        },
    })
    rm.assignPathAnimation(map, {
        beat: 101,
        duration: 3,
        easing: 'easeOutBack',
        track: DARK_NOTES_TRACK,
        animation: {
            offsetWorldRotation: [0, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 105,
        duration: 2,
        easing: 'easeInCirc',
        track: DARK_NOTES_TRACK,
        animation: {
            offsetPosition: [[0, 0, 50, 0], [0, 0, 0, 0.5]],
            offsetWorldRotation: [[0, 0, 30, 0], [0, 0, 0, 0.5]],
        },
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
            offsetWorldRotation: [[0, 0, -50, 0], [0, 0, 0, 0.5]],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 107,
        duration: 4,
        easing: 'easeOutCirc',
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [0, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 109,
        duration: 4,
        easing: 'easeOutCirc',
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [10, 0, 0],
        },
    })

    rm.assignPathAnimation(map, {
        beat: 111,
        duration: 4,
        easing: 'easeOutBack',
        track: DROP_MOVEMENT_TRACK,
        animation: {
            offsetWorldRotation: [0, 0, 0],
        },
    })
}
