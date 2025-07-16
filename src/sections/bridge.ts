import { TIMES } from "../constants.ts"
import { rm } from "../deps.ts"
import { generateShake } from "../effects.ts"
import { lightShow, prefabs } from "../main.ts"
import { between, cutDirectionAngle, gridYToLocalOffset, pointsBeatsToNormalized } from "../utilities.ts"

export function bridge(map: rm.V3Difficulty) {
    const bridgeScene = prefabs.bridge.instantiate(map, TIMES.BRIDGE)

    doNotemods(map)

    bridgeScene.destroyObject(TIMES.BUILDUP)
}

const START = 362.3
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
    const PAUSE_TRACK = "pauseTrack"
    const pauseNotes = map.allNotes.filter(isInPauses)

    rm.animateTrack(map, {
        track: PAUSE_TRACK,
        animation: {
            scale: [0,0,0]
        }
    })
    rm.animateTrack(map, {
        track: PAUSE_TRACK,
        beat: START,
        animation: {
            scale: [1,1,1]
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

    pauseNotes.forEach((x) => {
        x.animation.scale = [[0, 0, 0, 0], [1, 1, 1, 0]]
        x.animation.offsetWorldRotation = [[0, rand(-1, 1) * 2, 0, 0], [0, 0, 0, 0.5]]
        x.noteJumpMovementSpeed = 12
        x.life = 30 * 2
        x.track.add(PAUSE_TRACK)
        
        if (!(x instanceof rm.Arc || x instanceof rm.Chain)) {
            x.spawnEffect = false
        }
        
        const beat = (ms: number) => rm.inverseLerp(x.life, 0, ms) * 0.5
        const jumpInBeat = 4
        const invY = -gridYToLocalOffset(x.y) / 0.6

        const randomNoteSpawnRotations = [
            [-0.9543871, -0.1183784, 0.2741019],
            [0.7680854, -0.08805521, 0.6342642],
            [-0.6780157, 0.306681, -0.6680131],
            [0.1255014, 0.9398643, 0.3176546],
            [0.365105, -0.3664974, -0.8557909],
            [-0.8790653, -0.06244748, -0.4725934],
            [0.01886305, -0.8065798, 0.5908241],
            [-0.1455435, 0.8901445, 0.4318099],
            [0.07651193, 0.9474725, -0.3105508],
            [0.1306983, -0.2508438, -0.9591639]
        ].map(x => rm.arrayMultiply(x, (180 / Math.PI) / 2)) as rm.Vec3[]

        const impactRotation = randomNoteSpawnRotations[Math.floor(rand(0, randomNoteSpawnRotations.length))]

        x.animation.offsetPosition = [[0,invY,10,beat(jumpInBeat + 4)],[0,invY,0,beat(jumpInBeat),'easeInExpo'],[0,0,0,0.5,'easeOutQuad']]
        if (x instanceof rm.ColorNote) {
            const invRotation: rm.Vec3 = [0, 0, -(cutDirectionAngle(x.cutDirection) + 180) % 360]
            x.animation.localRotation = [
                [...invRotation, beat(jumpInBeat + 2)],
                [...rm.combineRotations(impactRotation, invRotation), beat(jumpInBeat)], 
                [0,0,0,beat(jumpInBeat * 0.3),'easeOutExpo']
            ]
        }
        else {
            x.animation.localRotation = [
                [0,0,0,beat(jumpInBeat + 2)],
                [...impactRotation, beat(jumpInBeat)], 
                [0,0,0,beat(jumpInBeat * 0.3),'easeOutExpo']
            ]
        }

        const pauseTrack = getNextPauseTrack()
        x.track.add(pauseTrack)

        const life = x.life
        const halfLife = life / 2

        rm.animateTrack(map, {
            track: pauseTrack,
            animation: {
                scale: [0,0,0]
            }
        })
        rm.animateTrack(map, {
            track: pauseTrack,
            beat: x.beat - halfLife,
            duration: 1,
            animation: {
                scale: [[0,0,0,0],[1,1,1,0.48,'easeStep'],[0,0,0,0.49,'easeStep'],[1,1,1,0.5,'easeStep']],
                offsetPosition: generateShake(2, rand).map(x => {
                    rm.setPointEasing(x, 'easeStep')
                    return x
                })
            }
        })

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
