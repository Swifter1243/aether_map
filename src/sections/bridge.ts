import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { lightShow, prefabs } from "../main.ts";
import { between } from "../utilities.ts";

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

    const MAX_PAUSE_TRACKS = 20
    let pauseTrack = 0
    function getNextPauseTrack(): string {
        pauseTrack = (pauseTrack + 1) % MAX_PAUSE_TRACKS
        return `pauseTrack_${pauseTrack}`
    }

    const pauseEvents = lightShow.lightEvents.filter(x => isInPauses(x) && x.type == 0)

    map.allNotes.filter(isInPauses).forEach(x => {
        const pauseLength = x.life
        const pauseTrack = getNextPauseTrack()
        x.track.add(pauseTrack)

        rm.animateTrack(map, {
            beat: x.beat - pauseLength / 2,
            duration: pauseLength,
            track: pauseTrack,
            animation: {
                time: [[0,0],[1,1]]
            }
        })
    })
}