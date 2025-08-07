import { TIMES } from "../constants.ts"
import { rm } from "../deps.ts"
import { applyFakeJumps, generateShake, setFakeJumps } from "../effects.ts"
import { lightShow, prefabs } from "../main.ts"
import { approximately, between, pointsBeatsToNormalized } from "../utilities.ts"

export function bridge(map: rm.V3Difficulty) {
    const bridgeScene = prefabs.bridge.instantiate(map, TIMES.BRIDGE)

    doNotemods(map)

    bridgeScene.destroyObject(TIMES.BUILDUP)
}

const START = 362.3
const END = 477

function doNotemods(map: rm.V3Difficulty) {
    doPausing()
    doTransitionNotes()

    function doPausing() {
        const isInPauses = between(START, END)

        const pauseEvents = lightShow.lightEvents
            .filter((x) => isInPauses(x) && x.type == 0)
            .map((e) => {
                return {
                    beat: e.beat,
                    isPlaying: e.value != rm.EventAction.OFF,
                }
            })

        const DYNAMIC_GEMSTONE_TRACK = "dynamicGemstone"
        const STATIC_WIREFRAME_TRACK = "staticWireframe"
        const PAUSE_TRACK = "pauseTrack"
        const JUMPS_CONTEXT = setFakeJumps(map, TIMES.DROP_END, {
            objectLife: 30 * 2,
            jumpInBeat: 2,
            jumpInDuration: 2
        })
        const pauseNotes = map.allNotes.filter(isInPauses)

        rm.animateTrack(map, {
            track: PAUSE_TRACK,
            animation: {
                scale: [0, 0, 0]
            }
        })
        rm.animateTrack(map, {
            track: PAUSE_TRACK,
            beat: START,
            animation: {
                scale: [1, 1, 1]
            }
        })

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

        const MAX_PAUSE_TRACKS = 99999
        let pauseTrack = 0
        function getNextPauseTrack(): string {
            pauseTrack = (pauseTrack + 1) % MAX_PAUSE_TRACKS
            return `pauseNote_${pauseTrack}`
        }

        pauseNotes.forEach((x) => {
            setupAttributes()
            applyFakeJumps(x, rand, JUMPS_CONTEXT)

            const pauseTrack = getNextPauseTrack()
            x.track.add(pauseTrack)

            const life = x.life
            const halfLife = life / 2

            doSpawnAnimation()
            doTimeRemapping()

            function doTimeRemapping() {
                let timePoints: rm.ComplexPointsLinear = []
                let lastOnBeat = x.beat
                let lastOffTime = 0.5

                for (let i = pauseEvents.length - 1; i >= 0; i--) {
                    const e = pauseEvents[i]

                    // skip event if it happens after the note.
                    const eventIsPastNote = e.beat > x.beat
                    if (eventIsPastNote) {
                        continue
                    }

                    // skip event if it's before the note spawned, after time remapping.
                    const eventIsBeforeNote = e.beat < lastOnBeat - lastOffTime * life
                    if (eventIsBeforeNote && e.isPlaying) {
                        break
                    }

                    // events are navigated backwards, so on acts like off and off acts like on.
                    if (e.isPlaying) {
                        const duration = lastOnBeat - e.beat
                        const normalizedDuration = duration / life
                        lastOffTime -= normalizedDuration
                    } else {
                        lastOnBeat = e.beat
                    }

                    timePoints.push([lastOffTime, e.beat])

                    const isGameplaySwitch = e.beat > TIMES.BRIDGE + 3
                    let switchVariation = e.beat
                    if (e.isPlaying && i > 0) {
                        const nextSwitchBeat = pauseEvents[i - 1].beat
                        let t = (0.5 - lastOffTime) * 15
                        t = rm.clamp(t, 0, 1)
                        t = rm.lerp(0.01, 0.99, t)
                        switchVariation = rm.lerp(e.beat, nextSwitchBeat, t)
                    }
                    const switchBeat = isGameplaySwitch ? switchVariation : e.beat
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
                    [1, x.beat + halfLife]
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
            }

            function setupAttributes() {
                x.animation.scale = [[0, 0, 0, 0], [1, 1, 1, 0]]
                x.animation.offsetWorldRotation = [[0, rand(-1, 1) * 2, 0, 0], [0, 0, 0, 0.5]]
                x.noteJumpMovementSpeed = 12
                x.life = JUMPS_CONTEXT.objectLife
                x.track.add(PAUSE_TRACK)
            }

            function doSpawnAnimation() {
                rm.animateTrack(map, {
                    track: pauseTrack,
                    animation: {
                        scale: [0, 0, 0]
                    }
                })
                rm.animateTrack(map, {
                    track: pauseTrack,
                    beat: x.beat - halfLife,
                    duration: 1,
                    animation: {
                        scale: [[0, 0, 0, 0], [1, 1, 1, 0.48, 'easeStep'], [0, 0, 0, 0.49, 'easeStep'], [1, 1, 1, 0.5, 'easeStep']],
                        offsetPosition: generateShake(2, rand).map(x => {
                            rm.setPointEasing(x, 'easeStep')
                            return x
                        })
                    }
                })
            }
        })
    }

    function doTransitionNotes() {
        const TRANSITION_NOTES_TRACK = 'transitionNotes'

        map.allNotes.filter(approximately(509)).forEach(x => {
            x.track.add(TRANSITION_NOTES_TRACK)
            x.life = 5 * 2
            x.animation.dissolve = [[0,0],[1,0.3]]
            x.animation.scale = [[0,0,0,0],[1,1,1,0.3,'easeOutExpo']]
            x.animation.offsetWorldRotation = [[-3,0,0,0],[0,0,0,0.3,'easeOutSine']]
        })

        rm.assignObjectPrefab(map, {
            colorNotes: {
                track: TRANSITION_NOTES_TRACK,
                asset: prefabs['black outline note'].path,
                debrisAsset: prefabs['black outline note debris'].path,
                anyDirectionAsset: prefabs['black outline note dot'].path
            }
        })
    }
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