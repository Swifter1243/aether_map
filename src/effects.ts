import { materials } from "./main.ts";
import { rm } from "./deps.ts";
import { cutDirectionVector } from './utilities.ts'

export function bokeh(material: rm.Material, map: rm.AbstractDifficulty, beat: number, duration = 10, radius = 25)
{
    material.blit(map, {
        beat,
        duration
    })

    material.set(map, {
        _Radius: [[radius, 0], [0, 1, 'easeOutSine']],
    }, beat, duration)
}

export function fadeWhite(map: rm.AbstractDifficulty, beat: number, duration: number, amount = 1) {
    const transitionMat = materials['fadewhite']
    const mixProperty: keyof typeof transitionMat['propertyTypes'] = '_Mix'
    transitionMat.blit(map, {
        beat: beat - duration / 2,
        duration,
        properties: [
            {
                id: mixProperty,
                type: transitionMat.propertyTypes[mixProperty],
                value: [[0, 0.48], [amount, 0.5, 'easeInCubic'], [0, 1, 'easeOutExpo']]
            }
        ]
    })
}

export function randomVec3(amplitude: number, random: (min: number, max: number) => number): rm.Vec3 {
    return [
        random(-amplitude, amplitude),
        random(-amplitude, amplitude),
        random(-amplitude, amplitude)
    ]
}

export function generateShake(amplitude: number, random: (min: number, max: number) => number, pointAmount = 5): rm.ComplexPointsVec3 {
    const points: rm.ComplexPointsVec3 = []

    for (let i = 0; i <= pointAmount; i++) {
        const t = i / pointAmount
        const amp = amplitude * (1 - t)
        points.push([...randomVec3(amp, random), t])
    }

    return points
}

function getCutDirectionTrack(cut: rm.NoteCut) {
    return `directionRotation_${cut}`
}

export function setDirectionalMagnitude(map: rm.V3Difficulty, magnitude: number, beat: number, duration = 0, eventEasing?: rm.EASE) {
    for (const cutKey in rm.NoteCut) {
        const cutStr = rm.NoteCut[cutKey]

        if (typeof cutStr !== 'number')
            continue

        const cut = parseInt(cutStr) as rm.NoteCut
        const dir = cutDirectionVector(cut)
        const track = getCutDirectionTrack(cut)
        rm.assignPathAnimation(map, {
            beat,
            duration,
            easing: eventEasing,
            track,
            animation: {
                offsetWorldRotation: [[dir[1] * magnitude, dir[0] * magnitude, 0, 0], [0,0,0,0.5, 'easeOutCirc']]
            } 
        })
    }
}

export function assignDirectionalRotation(object: rm.BeatmapGameplayObject) {
    if (object instanceof rm.ColorNote || object instanceof rm.Chain) {
        const track = getCutDirectionTrack(object.cutDirection)
        object.track.add(track)
    }
}