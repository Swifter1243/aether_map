import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { lightShow, prefabs } from "../main.ts";
import { between, pointsBeatsToNormalized } from "../utilities.ts";

export function bridge(map: rm.V3Difficulty)
{
    const bridgeScene = prefabs.bridge.instantiate(map, TIMES.BRIDGE)
    
    doNotemods(map)

    bridgeScene.destroyObject(TIMES.BUILDUP)
}

function doNotemods(map: rm.V3Difficulty) {
    const START = 362
    const END = 477
    const isInPauses = between(START, END)

    const MAX_PAUSE_TRACKS = 40
    let pauseTrack = 0
    function getNextPauseTrack(): string {
        pauseTrack = (pauseTrack + 1) % MAX_PAUSE_TRACKS
        return `pauseTrack_${pauseTrack}`
    }

    const pauseEvents = lightShow.lightEvents.filter(x => isInPauses(x) && x.type == 0)

    map.allNotes.filter(isInPauses).forEach(x => {
        const pauseTrack = getNextPauseTrack()
        const halfLife = x.life / 2
        x.track.add(pauseTrack)

        const timePoints: rm.ComplexPointsLinear = [
            [0, x.beat - halfLife - 1],
            [0, x.beat - halfLife],
            [0.5, x.beat],
            [1, x.beat + halfLife],
        ]
        const normalizedTimePoints = pointsBeatsToNormalized(timePoints)

        rm.animateTrack(map, {
            beat: normalizedTimePoints.minTime,
            duration: normalizedTimePoints.duration,
            track: pauseTrack,
            animation: {
                time: normalizedTimePoints.points
            }
        })
    })
}