import { TIMES } from "../constants.ts"
import { rm } from "../deps.ts"
import { lightShow, prefabs } from "../main.ts"
import { between, pointsBeatsToNormalized } from "../utilities.ts"

export function bridge(map: rm.V3Difficulty) {
    const bridgeScene = prefabs.bridge.instantiate(map, TIMES.BRIDGE)

    doNotemods(map)

    bridgeScene.destroyObject(TIMES.BUILDUP)
}

function doNotemods(map: rm.V3Difficulty) {
    doPauses(map)
}

function doPauses(map: rm.V3Difficulty) {
    const START = 362
    const END = 477
    const isInPauses = between(START, END)

    const MAX_PAUSE_TRACKS = 99999
    let pauseTrack = 0
    function getNextPauseTrack(): string {
        pauseTrack = (pauseTrack + 1) % MAX_PAUSE_TRACKS
        return `pauseTrack_${pauseTrack}`
    }

    const pauseEvents = lightShow.lightEvents
        .filter((x) => isInPauses(x) && x.type == 0)
        .reverse()
        .map((e) => {
            return {
                beat: e.beat,
                isPaused: e.value != rm.EventAction.OFF,
            }
        })

    map.allNotes.filter(isInPauses).forEach((x) => {
        x.animation.scale = [[0, 0, 0, 0], [1, 1, 1, 0]]
        x.animation.dissolve = [[0, 0], [1, 0]]
        x.noteJumpMovementSpeed = 8
        x.life = 30 * 2

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
            if ((e.beat < lastOnBeat - lastOffTime * life) && e.isPaused) {
                break
            }

            if (e.isPaused) {
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
