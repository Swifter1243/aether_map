import { TIMES } from "../constants.ts"
import { rm } from "../deps.ts"
import { lightShow, prefabs } from "../main.ts"
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
            debrisAsset: prefabs["gemstone note debris"].path
        }
    })
}

function assignWireframeToNotes(map: rm.V3Difficulty, track: string, beat = 0) {
    rm.assignObjectPrefab(map, {
        beat,
        colorNotes: {
            track,
            asset: prefabs["wireframe note"].path,
            debrisAsset: prefabs["wireframe note debris"].path
        }
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
    const STATIC_GEMSTONE_TRACK = "staticGemstone"
    pauseEvents.forEach((e) => {
        rm.animateTrack(map, {
            track: DYNAMIC_GEMSTONE_TRACK,
            beat: e.beat,
            animation: {
                interactable: [e.isPlaying ? 1 : 0]
            },
        })

        if (!e.isPlaying) {
            map.allNotes.forEach(x => {
                if (Math.abs(x.beat - e.beat) < 0.1) {
                    x.track.delete(DYNAMIC_GEMSTONE_TRACK)
                    x.track.add(STATIC_GEMSTONE_TRACK)
                }
            })
        }

        assignGemstoneToNotes(map, STATIC_GEMSTONE_TRACK)
        if (e.isPlaying) {
            assignGemstoneToNotes(map, DYNAMIC_GEMSTONE_TRACK, e.beat)
        } else {
            assignWireframeToNotes(map, DYNAMIC_GEMSTONE_TRACK, e.beat)
        }
    })

    const rand = rm.seededRandom(37834728)

    map.allNotes.filter(isInPauses).forEach((x) => {
        x.animation.scale = [[0, 0, 0, 0], [1, 1, 1, 0]]
        x.animation.offsetWorldRotation = [[0,rand(-1, 1) * 2,0,0],[0,0,0,0.5]]
        x.noteJumpMovementSpeed = 12
        x.life = 30 * 2

        const pauseTrack = getNextPauseTrack()
        x.track.add(pauseTrack)
        x.track.add(DYNAMIC_GEMSTONE_TRACK)

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
