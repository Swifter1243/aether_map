import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { fadeWhite, fakeJump } from "../effects.ts";
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
    const STRETCHED_NOTE_TRACK = 'stretchedNote'
    const NOTE_STRETCHER_TRACK = 'noteStretcher'

    map.allNotes.filter(between(510, 541)).forEach(x => {
        x.track.add(STRETCHED_NOTE_TRACK)
        x.life = 8 * 2
        fakeJump(x, rm.random)
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
        const duration = 5
        rm.animateTrack(map, {
            track: NOTE_STRETCHER_TRACK,
            beat: beat - duration / 2,
            duration,
            animation: {
                scale: [[1,1,1,0],[1,1,2,1,'easeInOutExpo']]
            }
        })
    }

    section1()
    section2()

    function section1() {
        stretchNotes(509)
        speedUpNotes(516.75)

        map.allNotes.filter(between(510, 525))
    }

    function section2() {
        map.allNotes.filter(between(526, 541))
    }
}