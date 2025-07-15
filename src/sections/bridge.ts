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

    const pauseEvents = lightShow.lightEvents.filter((x) => isInPauses(x) && x.type == 0).reverse()

    map.allNotes.filter(isInPauses).forEach((x) => {
        x.animation.scale = [[0, 0, 0, 0], [1, 1, 1, 0]]
        x.animation.dissolve = [[0, 0], [1, 0]]
        x.animation.offsetPosition = [[0, 0, -70, 0], [0, 0, 0, 0.48, "easeInOutExpo"], [0, 0, 0, 0.5]]
        x.noteJumpMovementSpeed = 20
        x.life = 30

        const pauseTrack = getNextPauseTrack()
        x.track.add(pauseTrack)

        const life = x.life
        const halfLife = life / 2

        let timePoints: rm.ComplexPointsLinear = []

        let lastOnBeat = x.beat
        let lastOffTime = 0.5

        for (let i = 0; i < pauseEvents.length; i++) {
            const e = pauseEvents[i]
            const on = e.value != rm.EventAction.OFF
            const time = e.beat

            if (e.beat > x.beat) {
                continue
            }
            if ((e.beat < lastOnBeat - lastOffTime * life) && on) {
                break
            }

            if (on) { // ON
                // compare last beat with current beat to find time
                // set last time
                const duration = lastOnBeat - time
                const normalizedDuration = duration / life
                lastOffTime -= normalizedDuration
                timePoints.push([lastOffTime, time])
            } else { // OFF
                // set from last time
                // mark last beat
                timePoints.push([lastOffTime, time])
                lastOnBeat = time
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
