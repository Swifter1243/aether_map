import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { fadeWhite, applyFakeJumps, simpleRotationPath, visibility, setFakeJumps, assignDirectionalRotation } from "../effects.ts";
import { materials, prefabs } from "../main.ts";
import { randomVec3 } from '../utilities.ts'
import { beatsToObjectSpawnLife, between, derivativeFunction } from '../utilities.ts'

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
    const SPEED_TRACK = 'buildupSpeed'
    const BUILDUP_NOTE = 'buildupNote'
    const TARGET_ROT_X = -45
    const JUMPS_CONTEXT = setFakeJumps(map, 509, {
        objectLife: 8 * 2,
        jumpInBeat: 3,
        jumpInDuration: 2
    })
    const fromBeat = beatsToObjectSpawnLife(JUMPS_CONTEXT.objectLife)

    const buildupRotationMovement = simpleRotationPath(map, BUILDUP_NOTE)

    map.allNotes.filter(between(510, 541)).forEach(x => {
        x.track.add(SPEED_TRACK)
        x.life = JUMPS_CONTEXT.objectLife
        applyFakeJumps(x, rm.random, JUMPS_CONTEXT)
        x.animation.scale = [[0,0,0,0],[1,1,1,0.5 - fromBeat(0.5)]]
        assignDirectionalRotation(x)
    })

    map.allNotes.filter(between(510, 573)).forEach(x => {
        x.track.add(BUILDUP_NOTE)
    })

    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: BUILDUP_NOTE,
            asset: prefabs['black outline note'].path,
            debrisAsset: prefabs['black outline note debris'].path,
            anyDirectionAsset: prefabs['black outline note dot'].path
        }
    })

    const SPEED_UP_ANIMATION: rm.RuntimeDifficultyPointsVec3 = [[0,0,400,0],[0,0,0,fromBeat(JUMPS_CONTEXT.jumpInBeat)]]

    rm.assignPathAnimation(map, {
        track: SPEED_TRACK,
        animation: {
            offsetPosition: SPEED_UP_ANIMATION
        }
    })
    rm.assignPathAnimation(map, {
        track: BUILDUP_NOTE,
        animation: {
            offsetPosition: [
                [0,-10,0,0],
                [0,-4,0,fromBeat(JUMPS_CONTEXT.jumpInBeat + JUMPS_CONTEXT.jumpInDuration)],
                [0,0,0,fromBeat(JUMPS_CONTEXT.jumpInBeat),'easeInQuad']
            ]
        }
    })

    function slowDownNotes(beat: number) {
        rm.assignPathAnimation(map, {
            track: SPEED_TRACK,
            beat,
            duration: 4,
            easing: 'easeOutExpo',
            animation: {
                offsetPosition: [0,0,0]
            }
        })
    }

    function speedUpNotes(beat: number) {
        const duration = 4
        rm.assignPathAnimation(map, {
            track: SPEED_TRACK,
            beat: beat - duration / 2,
            duration,
            easing: 'easeInOutCirc',
            animation: {
                offsetPosition: SPEED_UP_ANIMATION
            }
        })
    }

    section1()
    section2()
    section3()

    function section1() {
        const SECTION_1_TRACK = 'buildupSection1'

        visibility(map, SECTION_1_TRACK, 0, false)
        visibility(map, SECTION_1_TRACK, 509, true)

        slowDownNotes(509)
        buildupRotationMovement(509, [[0,0,360,0],[0,0,180,0.25],[0,0,0,0.5]])
        buildupRotationMovement(509, [[0,0,180,0],[0,0,0,0.5]], 4, 'easeOutCirc')

        speedUpNotes(516.75)
        buildupRotationMovement(516.75 -2, [[20,0,0,0],[-4,0,0,0.25,'easeInOutSine'],[0,0,0,0.5,'easeInOutSine']], 5, 'easeInOutBack')

        map.allNotes.filter(between(510, 525)).forEach(x => {
            x.track.add(SECTION_1_TRACK)
        })
    }

    function section2() {
        const SECTION_2_TRACK = 'buildupSection2'
        const LIFT_TRACK = 'buildupNoteLift'
        const RECOIL_TRACK = 'buildupRecoilTrack'

        const lift = simpleRotationPath(map, LIFT_TRACK)
        const recoil = simpleRotationPath(map, RECOIL_TRACK)

        visibility(map, SECTION_2_TRACK, 0, false)
        visibility(map, SECTION_2_TRACK, 525, true)

        slowDownNotes(525)
        buildupRotationMovement(525, [[0,0,-360,0],[0,0,-180,0.25],[0,0,0,0.5]])
        buildupRotationMovement(525, [[0,0,-180,0],[0,0,0,0.5]], 4, 'easeOutCirc')

        speedUpNotes(533)
        buildupRotationMovement(533 -2, [0,0,0], 5, 'easeInOutBack')

        map.allNotes.filter(between(526, 541)).forEach(x => {
            x.track.add(SECTION_2_TRACK)
            x.track.add(LIFT_TRACK)
            x.track.add(RECOIL_TRACK)
        })

        const ROT_START_BEAT = 531
        const ROT_END_BEAT = 541

        for (let beat = ROT_START_BEAT; beat < ROT_END_BEAT; beat += 2) {
            const t = rm.inverseLerp(ROT_START_BEAT, ROT_END_BEAT, beat)
            const remap = (x: number) => Math.pow(x, 1.2)
            const slope = derivativeFunction(remap)
            const t2 = remap(t)
            const rot = t2 * TARGET_ROT_X

            lift(beat - 1, [[0,0,0,0], [rot, 0, 0,fromBeat(1.5),'easeInExpo']], 2, 'easeInOutExpo')

            const LEAD_IN_TIME = 0.5

            if (beat > ROT_START_BEAT) {
                recoil(beat - LEAD_IN_TIME, [[0,0,0,0],[4 * slope(t),0,0,fromBeat(1.5),'easeInExpo'],[0,0,0,0.5]], LEAD_IN_TIME, 'easeInCirc')
            }
            recoil(beat, [0,0,0], 2 - LEAD_IN_TIME, 'easeOutBack')
        }

        rm.assignPathAnimation(map, {
            track: BUILDUP_NOTE,
            beat: ROT_END_BEAT,
            animation: {
                offsetPosition: [0,0,0],
                offsetWorldRotation: [0,0,0]
            }
        })
    }

    function section3() {
        const SECTION_3_TRACK = 'buildupSection3'

        visibility(map, SECTION_3_TRACK, 0, false)
        visibility(map, SECTION_3_TRACK, 541, true)

        const rand = rm.seededRandom(30)

        map.allNotes.filter(between(542, 574)).forEach(x => {
            x.track.add(SECTION_3_TRACK)

            const t = rm.inverseLerp(542, 574, x.beat)
            const rot = TARGET_ROT_X * (1 - t)

            x.noteJumpMovementSpeed = 10
            x.life = 20 * 2
            x.worldRotation = [rot, 0, 0]
            x.animation.offsetWorldRotation = [[-rot,rand(-2, 2),0,0],[0,0,0,0.5]]
            x.animation.localRotation = [[...randomVec3(180,rand),0],[0,0,0,0.5]]
            x.animation.scale = [[0,0,0,0.1],[1,1,1,0.5,'easeOutSine']]
        })
    }
}