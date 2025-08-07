import { TIMES } from '../constants.ts'
import { rm } from '../deps.ts'
import { assignDirectionalRotation, fadeWhite, noteHop, sequencedShakeRotation, setDirectionalMagnitude, simpleRotationPath, visibility, wheelEffect } from '../effects.ts'
import { materials, prefabs } from '../main.ts'
import { approximately, between, join, randomVec3 } from '../utilities.ts'

export function drop(map: rm.V3Difficulty) {
    const dropScene = prefabs.drop.instantiate(map, TIMES.DROP)

    doNotemods(map)

    fadeWhite(map, TIMES.DROP_END, 16)

    dropScene.destroyObject(TIMES.DROP_END)
}

function doNotemods(map: rm.V3Difficulty) {
    const DROP_MOVEMENT_TRACK = 'dropMovement'
    const ARROW_MOVEMENT_LEFT_TRACK = 'arrowMovementLeft'
    const ARROW_MOVEMENT_RIGHT_TRACK = 'arrowMovementRight'
    const BLACK_OUTLINE_TRACK = 'dropBlackOutline'
    const WHITE_OUTLINE_TRACK = 'dropWhiteOutline'
    const WHEEL_EFFECT_TRACK = 'dropWheelEffect'

    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: BLACK_OUTLINE_TRACK,
            asset: prefabs['black outline note'].path,
            debrisAsset: prefabs['black outline note debris'].path,
            anyDirectionAsset: prefabs['black outline note dot'].path
        }
    })

    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: WHITE_OUTLINE_TRACK,
            asset: prefabs['white outline note'].path,
            debrisAsset: prefabs['white outline note debris'].path,
            anyDirectionAsset: prefabs['white outline note dot'].path
        }
    })

    map.allNotes.filter(between(TIMES.DROP + 1, TIMES.DROP_END)).forEach((x) => {
        x.track.add(DROP_MOVEMENT_TRACK)
        x.disableNoteGravity = true
        x.animation.dissolve = [[0, 0], [1, 0.1]]
        x.animation.dissolveArrow = x.animation.dissolve
    })

    const wheelVisibility = (beat: number, visible: boolean) => visibility(map, WHEEL_EFFECT_TRACK, beat, visible)

    const dropRotationMovement = simpleRotationPath(map, DROP_MOVEMENT_TRACK)

    blackSection()
    whiteSection()
    blackSection2()
    whiteSection2()
    transitionNotes()

    function blackSection() {
        const DARK_NOTES_TRACK = 'dropDarkNotesTrack'

        map.allNotes.filter(between(79, 107)).forEach(x => {
            x.track.add(BLACK_OUTLINE_TRACK)
        })

        dropRotationMovement(77, [-4, 10, -10])
        dropRotationMovement(77, [0, 0, 0], 3, 'easeOutBack')

        wheelVisibility(70, false)

        rm.assignPathAnimation(map, {
            beat: 79,
            track: WHEEL_EFFECT_TRACK,
            animation: {
                offsetWorldRotation: [[20,-20,0,0],[0,0,0,0.5]],
            },
        })
        rm.assignPathAnimation(map, {
            beat: 80,
            track: WHEEL_EFFECT_TRACK,
            duration: 2,
            easing: 'easeOutBack',
            animation: {
                offsetWorldRotation: [0,0,0],
            },
        })

        wheelVisibility(80, true)
        wheelEffect(map, 5, [80, 81, 81.75, 82.25, 83, 84.25, 85])
        map.allNotes.filter(between(82, 85)).forEach((x) => {
            x.life = 8
            x.track.add(WHEEL_EFFECT_TRACK)
        })

        dropRotationMovement(85 - 1, [[0, -6, 0, 0], [0, 0, 0, 0.5]], 2, 'easeInOutExpo')
        dropRotationMovement(87 - 1, [[0, 6, 0, 0], [0, 0, 0, 0.5]], 2, 'easeInOutExpo')

        map.allNotes.filter(join(
            approximately(87),
            approximately(89),
        )).forEach((x) => {
            noteHop(x, 8)
        })

        dropRotationMovement(89, [0, 0, 0], 4, 'easeOutExpo')

        dropRotationMovement(91, [-5, 0, 0])
        dropRotationMovement(91, [5, 0, 0], 4, 'easeInOutBack')

        dropRotationMovement(95, [[-2, 0, 20, 0], [-2, 0, 0, 0.5]], 2, 'easeOutExpo')

        dropRotationMovement(97, [0, 0, 0], 4, 'easeOutBack')

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

        map.allNotes.filter(join(
            between(91, 93),
            between(95, 97),
            between(99, 101),
            approximately(109),
        )).forEach((x) => {
            noteHop(x)

            if (!(x instanceof rm.Bomb)) {
                const left = x.color === rm.NoteColor.RED
                x.track.add(left ? ARROW_MOVEMENT_LEFT_TRACK : ARROW_MOVEMENT_RIGHT_TRACK)
            }
        })

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

        dropRotationMovement(107, [[0, 0, -50, 0], [0, 0, 0, 0.5]])

        dropRotationMovement(107, [0, 0, 0], 4, 'easeOutCirc')

        dropRotationMovement(109, [3, 0, 0], 4, 'easeOutCirc')
    }

    function whiteSection() {
        const DROP_DISAPPEARING_TRACK = 'dropDisappearing'

        map.allNotes.filter(between(109, 133)).forEach(x => {
            x.track.add(WHITE_OUTLINE_TRACK)
        })

        dropRotationMovement(111, [0, 0, 0], 1, 'easeOutExpo')

        wheelVisibility(100, false)

        rm.assignPathAnimation(map, {
            beat: 100,
            track: WHEEL_EFFECT_TRACK,
            animation: {
                offsetWorldRotation: [[20,-20,0,0],[0,0,0,0.5]],
            },
        })
        rm.assignPathAnimation(map, {
            beat: 111,
            track: WHEEL_EFFECT_TRACK,
            easing: 'easeOutBack',
            duration: 1.25,
            animation: {
                offsetWorldRotation: [[10,-10,0,0],[0,0,0,0.5]],
            },
        })
        rm.assignPathAnimation(map, {
            beat: 112.25,
            track: WHEEL_EFFECT_TRACK,
            duration: 2,
            easing: 'easeOutBack',
            animation: {
                offsetWorldRotation: [0,0,0],
            },
        })

        wheelVisibility(111, true)
        wheelEffect(map, -5, [112.25, 113, 113.75, 114.25, 115, 116.25, 117])
        map.allNotes.filter(between(113, 117)).forEach((x) => {
            x.life = 8
            x.track.add(WHEEL_EFFECT_TRACK)
        })

        dropRotationMovement(117 - 1, [[0, 3, 0, 0], [0, 0, 0, 0.5]], 2, 'easeOutExpo')

        dropRotationMovement(119 - 1, [[0, -7, 0, 0], [0, 0, 0, 0.5]], 2, 'easeInOutExpo')

        map.allNotes.filter(join(
            approximately(119),
            approximately(121),
        )).forEach((x) => {
            noteHop(x, 8)
        })

        dropRotationMovement(89 + 32, [0, 3, 0], 4, 'easeOutExpo')

        dropRotationMovement(91 + 32, [-5, -3, 0])
        dropRotationMovement(91 + 32, [5, -3, 0], 4, 'easeInOutBack')

        dropRotationMovement(95 + 32, [[-2, 0, 20, 0], [-2, 0, 0, 0.5]], 2, 'easeOutExpo')

        dropRotationMovement(97 + 32, [0, 0, 0], 4, 'easeOutBack')

        map.allNotes.filter(join(
            between(123, 125),
            approximately(127),
            approximately(129),
            between(131, 133),
        )).forEach((x) => {
            noteHop(x)

            if (!(x instanceof rm.Bomb)) {
                const left = x.color === rm.NoteColor.RED
                x.track.add(left ? ARROW_MOVEMENT_LEFT_TRACK : ARROW_MOVEMENT_RIGHT_TRACK)
            }
        })

        map.allNotes.filter(between(117, 133)).forEach((x) => {
            x.track.add(DROP_DISAPPEARING_TRACK)
        })

        enum VISIBILITY {
            VISIBLE,
            PARTIAL,
            INVISIBLE
        }

        const whiteVisibility = (beat: number, visible: VISIBILITY) => {
            if (visible == VISIBILITY.INVISIBLE) {
                visibility(map, DROP_DISAPPEARING_TRACK, beat, false)
            }
            else {
                visibility(map, DROP_DISAPPEARING_TRACK, beat, true)

                const whiteOutlineMats = [
                    materials['white outline note'],
                    materials['white outline note debris']
                ]

                whiteOutlineMats.forEach(m => {
                    m.set(map, {
                        _BorderWidth: visible == VISIBILITY.VISIBLE ? m.defaults._BorderWidth : 0
                    }, beat)
                })
            }
        }

        whiteVisibility(117, VISIBILITY.VISIBLE)
        whiteVisibility(118 + 1 / 6, VISIBILITY.PARTIAL)
        whiteVisibility(119, VISIBILITY.VISIBLE)
        whiteVisibility(120 + 1 / 4, VISIBILITY.PARTIAL)

        whiteVisibility(121, VISIBILITY.VISIBLE)
        whiteVisibility(122.5, VISIBILITY.PARTIAL)
        whiteVisibility(123, VISIBILITY.VISIBLE)
        whiteVisibility(124.5, VISIBILITY.PARTIAL)

        whiteVisibility(125, VISIBILITY.VISIBLE)
        whiteVisibility(126.5, VISIBILITY.PARTIAL)
        whiteVisibility(127, VISIBILITY.VISIBLE)
        whiteVisibility(128, VISIBILITY.INVISIBLE)
        whiteVisibility(128.25, VISIBILITY.VISIBLE)

        whiteVisibility(130.75, VISIBILITY.INVISIBLE)
        whiteVisibility(131, VISIBILITY.VISIBLE)
    }

    function blackSection2() {
        map.allNotes.filter(between(134, 171)).forEach(x => {
            x.track.add(BLACK_OUTLINE_TRACK)
        })

        map.allNotes.filter(between(134, 149)).forEach(x => {
            noteHop(x, 9)
            assignDirectionalRotation(x)
        })

        setDirectionalMagnitude(map, 30, 1)
        dropRotationMovement(133, [[0,0,0,0],[-6,0,0,0.5]], 3, 'easeOutCirc')

        dropRotationMovement(149 - 2 / 2, [[-3,-3,40,0],[-6,-4,0,0.5,'easeOutCirc']], 2, 'easeInOutBack')

        dropRotationMovement(151 - 2 / 2, [[-3,0,0,0],[-6,0,0,0.5,'easeOutCirc']], 1, 'easeInExpo')
        dropRotationMovement(151, [[-3,14,-20,0],[-6,10,0,0.5,'easeOutCirc']], 3, 'easeOutBack')

        dropRotationMovement(157 - 5 / 2, [[-3,-14,30,0],[-6,-10,0,0.5,'easeOutCirc']], 5, 'easeInOutBack')

        dropRotationMovement(161 - 4 / 2, [[-3,0,-10,0],[-6,0,0,0.5,'easeOutCirc']], 4, 'easeInOutBack')

        dropRotationMovement(165 - 2, [-3, 0, 0], 2, 'easeInCirc')

        map.allNotes.filter(between(167, 177)).forEach(x => {
            noteHop(x, 9)
            assignDirectionalRotation(x)
        })
    }

    function whiteSection2() {
        const ROTATION_SEQUENCE_1_TRACK = "dropRotationSequence1"

        dropRotationMovement(173, [0, 0, 0], 4, 'easeOutExpo')

        map.allNotes.filter(between(173, 195)).forEach(x => {
            x.track.add(WHITE_OUTLINE_TRACK)
        })

        const SHAKE_SEQUENCE_1_START = 176
        const SHAKE_SEQUENCE_1_END = 184
        map.allNotes.filter(between(SHAKE_SEQUENCE_1_START, SHAKE_SEQUENCE_1_END + 10)).forEach(x => {
            x.track.add(ROTATION_SEQUENCE_1_TRACK)
            x.life = 2 * 2
        })

        const shakeRandom = rm.seededRandom(8)
        sequencedShakeRotation(map, ROTATION_SEQUENCE_1_TRACK, SHAKE_SEQUENCE_1_START, SHAKE_SEQUENCE_1_END, [177, 177.5, 177.75, 178.5, 179, 179.75, 180.25, 181], 7, shakeRandom, 80, 90)

        map.allNotes.filter(between(177, 181)).forEach(x => {
            const t = rm.inverseLerp(177, 181, x.beat)
            x.worldRotation = [rm.lerp(5, -7, t), 0, 0]
        })

        dropRotationMovement(181 - 8/2, [-7, 0, 0], 8, 'easeInOutExpo')

        map.allNotes.filter(between(181, 195)).forEach(x => {
            assignDirectionalRotation(x)
        })
        setDirectionalMagnitude(map, 4, 173)
        setDirectionalMagnitude(map, 10, 189 - 4/2, 4, 'easeInOutExpo')

        dropRotationMovement(189 - 4/2, [0, 0, 0], 4, 'easeInOutExpo')
    }

    function transitionNotes() {
        const ZOOM_MIDPOINT: rm.Vec3 = [0, 1, 10]
        const INV_ZOOM_MIDPOINT = rm.arrayMultiply(ZOOM_MIDPOINT, -1)

        const PARENT_TO_ORIGIN_TRACK = 'dropTransitionNotesToOrigin'
        const PARENT_SCALE_TRACK = 'dropTransitionNotesScale'
        const PARENT_TO_ZOOM_TRACK = 'dropTransitionNotesToZoom'
        const TRANSITION_NOTES_TRACK = 'dropTransitionNote'

        const ZOOM_TIME = 8
        const TRANSITION_TIME = TIMES.DROP_END

        rm.assignObjectPrefab(map, {
            colorNotes: {
                track: TRANSITION_NOTES_TRACK,
                asset: prefabs['glass note'].path,
                debrisAsset: prefabs['glass note debris'].path
            }
        })

        map.allNotes.filter(approximately(TRANSITION_TIME)).forEach(x => {
            x.noteJumpMovementSpeed = 0.002
            x.life = ZOOM_TIME * 2
            x.animation.offsetPosition = [[...ZOOM_MIDPOINT, 0], [...INV_ZOOM_MIDPOINT,1]]
            x.track.add(TRANSITION_NOTES_TRACK)
        })

        rm.assignTrackParent(map, {
            childrenTracks: [PARENT_SCALE_TRACK],
            parentTrack: PARENT_TO_ZOOM_TRACK
        })

        rm.assignTrackParent(map, {
            childrenTracks: [PARENT_TO_ORIGIN_TRACK],
            parentTrack: PARENT_SCALE_TRACK
        })

        rm.assignTrackParent(map, {
            childrenTracks: [TRANSITION_NOTES_TRACK],
            parentTrack: PARENT_TO_ORIGIN_TRACK
        })

        rm.animateTrack(map, {
            beat: 1,
            track: PARENT_TO_ORIGIN_TRACK,
            animation: {
                localPosition: INV_ZOOM_MIDPOINT
            }
        })

        rm.animateTrack(map, {
            beat: 2,
            track: PARENT_TO_ZOOM_TRACK,
            animation: {
                localPosition: ZOOM_MIDPOINT
            }
        })

        const orbitRandom = rm.seededRandom(57)

        rm.animateTrack(map, {
            beat: TRANSITION_TIME - ZOOM_TIME,
            duration: ZOOM_TIME,
            track: PARENT_SCALE_TRACK,
            animation: {
                scale: [[0,0,0,0],[1,1,1,1,'easeInQuad']],
                localRotation: [[...randomVec3(80, orbitRandom),0],[0,0,0,1,'easeOutSine']]
            }
        })
    }
}
