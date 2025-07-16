import { TIMES } from "../constants.ts"
import { rm } from "../deps.ts"
import { generateShake, randomVec3 } from "../effects.ts"
import { lightShow, pipeline, prefabs } from "../main.ts"
import { between, pointsBeatsToNormalized } from "../utilities.ts"

export function bridge(map: rm.V3Difficulty) {
    const bridgeScene = prefabs.bridge.instantiate(map, TIMES.BRIDGE)

    doNotemods(map)

    bridgeScene.destroyObject(TIMES.BUILDUP)
}

const START = 362
const END = 477

function doNotemods(map: rm.V3Difficulty) {
    doPauses(map)
}

function assignGemstoneToNotes(map: rm.V3Difficulty, track: string, beat = 0) {
    rm.assignObjectPrefab(map, {
        beat,
        colorNotes: {
            track,
            asset: prefabs["gemstone note"].path,
            debrisAsset: prefabs["gemstone note debris"].path,
        },
    })
}

function assignWireframeToNotes(map: rm.V3Difficulty, track: string, beat = 0) {
    rm.assignObjectPrefab(map, {
        beat,
        colorNotes: {
            track,
            asset: prefabs["wireframe note"].path,
            debrisAsset: prefabs["wireframe note debris"].path,
        },
    })
}

function doPauses(map: rm.V3Difficulty) {
    const isInPauses = between(START, END)

    const MAX_PAUSE_TRACKS = 99999
    let pauseTrack = 0
    function getNextPauseTrack(): string {
        pauseTrack = (pauseTrack + 1) % MAX_PAUSE_TRACKS
        return `pauseNote_${pauseTrack}`
    }

    const pauseEvents = lightShow.lightEvents
        .filter((x) => isInPauses(x) && x.type == 0)
        .reverse()
        .map((e) => {
            return {
                beat: e.beat,
                isPlaying: e.value != rm.EventAction.OFF,
            }
        })

    const DYNAMIC_GEMSTONE_TRACK = "dynamicGemstone"
    const STATIC_WIREFRAME_TRACK = "staticWireframe"
    const pauseNotes = map.allNotes.filter(isInPauses)

    const rand = rm.seededRandom(37834728)

    assignWireframeToNotes(map, STATIC_WIREFRAME_TRACK)
    assignGemstoneToNotes(map, DYNAMIC_GEMSTONE_TRACK)

    pauseEvents.forEach((e) => {
        rm.animateTrack(map, {
            track: DYNAMIC_GEMSTONE_TRACK,
            beat: e.beat,
            animation: {
                interactable: [e.isPlaying ? 1 : 0],
            },
        })

        if (!e.isPlaying) {
            pauseNotes.forEach((x) => {
                if (Math.abs(x.beat - e.beat) < 0.1) {
                    x.track.add(STATIC_WIREFRAME_TRACK)
                } else {
                    x.track.add(DYNAMIC_GEMSTONE_TRACK)
                }
            })
        }
    })

    pauseNotes.forEach((x) => {
        x.animation.scale = [[0, 0, 0, 0], [1, 1, 1, 0]]
        x.animation.offsetWorldRotation = [[0, rand(-1, 1) * 2, 0, 0], [0, 0, 0, 0.5]]
        x.noteJumpMovementSpeed = 12
        x.life = 30 * 2
        
        const beat = (ms: number) => rm.inverseLerp(x.life, 0, ms) * 0.5
        const jumpInBeat = 4
        x.animation.offsetPosition = [[0,0,10,beat(jumpInBeat + 4)],[0,0,0,beat(jumpInBeat),'easeInExpo']]
        x.animation.localRotation = [
            [0,0,0,beat(jumpInBeat + 2)],
            [...randomVec3(8, rand), beat(jumpInBeat)], 
            [0,0,0,beat(jumpInBeat - 2),'easeOutCirc']
        ]

        const pauseTrack = getNextPauseTrack()
        x.track.add(pauseTrack)

        const life = x.life
        const halfLife = life / 2

        let timePoints: rm.ComplexPointsLinear = []

        let lastOnBeat = x.beat
        let lastOffTime = 0.5

        for (let i = 0; i < pauseEvents.length; i++) {
            const e = pauseEvents[i]

            if (e.beat > x.beat) {
                continue
            }
            if ((e.beat < lastOnBeat - lastOffTime * life) && e.isPlaying) {
                break
            }

            if (e.isPlaying) {
                const duration = lastOnBeat - e.beat
                const normalizedDuration = duration / life
                lastOffTime -= normalizedDuration
            } else {
                lastOnBeat = e.beat
            }

            timePoints.push([lastOffTime, e.beat])

            const isGameplaySwitch = e.beat > TIMES.BRIDGE + 3
            const variation = rand(-1, 1) * 0.1 + (0.5 - lastOffTime) * 3
            const switchBeat = isGameplaySwitch ? (e.beat + variation) : e.beat
            if (e.isPlaying) {
                assignGemstoneToNotes(map, pauseTrack, switchBeat)
            } else {
                assignWireframeToNotes(map, pauseTrack, switchBeat)
            }

            if (isGameplaySwitch) {
                rm.animateTrack(map, {
                    track: pauseTrack,
                    beat: switchBeat,
                    duration: 0.3,
                    animation: {
                        offsetPosition: generateShake(0.1, rand),
                        localRotation: generateShake(4, rand)
                    },
                })
            }
        }

        let startBeat = x.beat - halfLife
        if (lastOffTime > 0) {
            const remainingTime = lastOffTime
            const remainingBeats = remainingTime * life
            startBeat = lastOnBeat - remainingBeats
        }

        timePoints.push(
            [0, startBeat - 1],
            [0, startBeat],
            [0.5, x.beat],
            [1, x.beat + halfLife],
        )

        timePoints = timePoints.sort((a, b) => rm.getPointTime(a) - rm.getPointTime(b))
        const normalizedTimePoints = pointsBeatsToNormalized(timePoints)

        rm.animateTrack(map, {
            beat: normalizedTimePoints.minTime,
            duration: normalizedTimePoints.duration,
            track: pauseTrack,
            animation: {
                time: normalizedTimePoints.points,
            },
        })
    })
}
