import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { fadeWhite, applyFakeJumps, simpleRotationPath, visibility, setFakeJumps } from "../effects.ts";
import { materials, prefabs } from "../main.ts";
import { between } from '../utilities.ts'

export function buildup(map: rm.V3Difficulty)
{
    const buildupScene = prefabs.buildup.instantiate(map, TIMES.BUILDUP)

    fadeWhite(map, TIMES.BUILDUP, 16)

    doNotemods(map)

    materials["541 - terrain"].set(map, {
        _Light1Strength: [[0, 0], [1, 1]]
    }, 541, 20)

    buildupScene.destroyObject(TIMES.OUTRO)
}

function doNotemods(map: rm.V3Difficulty) {
    const STRETCHED_NOTE_TRACK = 'buildupStretchedNote'
    const NOTE_STRETCHER_TRACK = 'buildupNoteStretcher'
    const BUILDUP_NOTE = 'buildupNote'
    const JUMPS_CONTEXT = setFakeJumps(map, 509, {
        objectLife: 8 * 2,
        jumpInBeat: 4,
        jumpInDuration: 4
    })

    const buildupRotationMovement = simpleRotationPath(map, BUILDUP_NOTE)

    map.allNotes.filter(between(510, 541)).forEach(x => {
        x.track.add(STRETCHED_NOTE_TRACK)
        x.life = JUMPS_CONTEXT.objectLife
        applyFakeJumps(x, rm.random, JUMPS_CONTEXT)
    })

    map.allNotes.filter(between(510, 573)).forEach(x => {
        x.track.add(BUILDUP_NOTE)
    })

    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: BUILDUP_NOTE,
            asset: prefabs['black outline note'].path,
            debrisAsset: prefabs['black outline note debris'].path
        }
    })

    rm.assignTrackParent(map, {
        childrenTracks: [STRETCHED_NOTE_TRACK],
        parentTrack: NOTE_STRETCHER_TRACK
    })

    function stretchNotes(beat: number) {
        rm.animateTrack(map, {
            track: NOTE_STRETCHER_TRACK,
            beat,
            duration: 3,
            animation: {
                scale: [[1,1,3,0],[1,1,1,1,'easeOutCirc']]
            }
        })
    }

    function speedUpNotes(beat: number) {
        const duration = 6
        rm.animateTrack(map, {
            track: NOTE_STRETCHER_TRACK,
            beat: beat - duration / 2,
            duration,
            animation: {
                scale: [[1,1,1,0],[1,1,2,1,'easeInOutCirc']]
            }
        })
    }

    section1()
    section2()

    function section1() {
        const SECTION_1_TRACK = 'buildupSection1'

        visibility(map, SECTION_1_TRACK, 0, false)
        visibility(map, SECTION_1_TRACK, 509, true)

        stretchNotes(509)
        buildupRotationMovement(509, [[0,0,360,0],[0,0,180,0.25],[0,0,0,0.5]])
        buildupRotationMovement(509, [[0,0,180,0],[0,0,0,0.5]], 3, 'easeOutSine')

        speedUpNotes(516.75)
        buildupRotationMovement(516.75 -2, [[20,0,0,0],[-4,0,0,0.25,'easeInOutSine'],[0,0,0,0.5,'easeInOutSine']], 5, 'easeInOutBack')

        map.allNotes.filter(between(510, 525)).forEach(x => {
            x.track.add(SECTION_1_TRACK)
        })
    }

    function section2() {
        const SECTION_2_TRACK = 'buildupSection2'

        visibility(map, SECTION_2_TRACK, 0, false)
        visibility(map, SECTION_2_TRACK, 525, true)

        stretchNotes(525)
        buildupRotationMovement(525, [[0,0,-360,0],[0,0,-180,0.25],[0,0,0,0.5]])
        buildupRotationMovement(525, [[0,0,-180,0],[0,0,0,0.5]], 3, 'easeOutSine')

        speedUpNotes(533)

        map.allNotes.filter(between(526, 541)).forEach(x => {
            x.track.add(SECTION_2_TRACK)
        })

        const ROT_START_BEAT = 533
        const ROT_END_BEAT = 541
        const ROT_DURATION = ROT_END_BEAT - ROT_START_BEAT
        const TARGET_ROT_Y = 40
        const ROT_ITER = TARGET_ROT_Y / Math.floor(ROT_DURATION / 2)
        let rotZ = 0

        for (let t = ROT_START_BEAT; t < ROT_END_BEAT; t += 2) {
            const oldRotZ = rotZ
            rotZ += ROT_ITER

            rm.animateTrack(map, {
                track: NOTE_STRETCHER_TRACK,
                beat: t - 1,
                duration: 2,
                easing: 'easeInOutExpo',
                animation: {
                    rotation: [[-oldRotZ,0,0,0],[-rotZ,0,0,1]]
                }
            })

            const LEAD_IN_TIME = 0.5

            buildupRotationMovement(t - LEAD_IN_TIME, [[30,0,0,0],[0,0,0,0.5]], LEAD_IN_TIME, 'easeInCirc')
            buildupRotationMovement(t, [0,0,0], 2 - LEAD_IN_TIME, 'easeOutBack')
        }
    }
}