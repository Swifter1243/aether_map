import { materials } from "./main.ts";
import { rm } from "./deps.ts";
import { cutDirectionAngle, cutDirectionVector, gridYToLocalOffset, RandFunc, randomVec3, sequencedRotation } from './utilities.ts'

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

export function sequencedShakeRotation(map: rm.V3Difficulty, track: string, start: number, end: number, times: number[], amplitude: number, random: RandFunc) {
    let angle = 0
    sequencedRotation(map, track, start, end, times, (_) => {
        angle += 180 + random(-30, 30)
        const rad = rm.toRadians(angle)
        const x = Math.sin(rad)
        const y = Math.cos(rad)
        return [x * amplitude, y * amplitude, 0]
    })
}

export function fakeJump(o: rm.BeatmapGameplayObject, random: RandFunc, jumpInBeat = 4, jumpInDuration = 4) {
    const beat = (ms: number) => rm.inverseLerp(o.life, 0, ms) * 0.5
    const invY = -gridYToLocalOffset(o.y) / 0.6

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

    const impactRotation = randomNoteSpawnRotations[Math.floor(random(0, randomNoteSpawnRotations.length))]

    o.animation.offsetPosition = [[0, invY, 10, beat(jumpInBeat + jumpInDuration)], [0, invY, 0, beat(jumpInBeat), 'easeInExpo'], [0, 0, 0, 0.5, 'easeOutQuad']]
    if (o instanceof rm.ColorNote) {
        const invRotation: rm.Vec3 = [0, 0, -(cutDirectionAngle(o.cutDirection) + 180) % 360]
        o.animation.localRotation = [
            [...invRotation, beat(jumpInBeat + 2)],
            [...rm.combineRotations(impactRotation, invRotation), beat(jumpInBeat)],
            [0, 0, 0, beat(jumpInBeat * 0.5), 'easeOutExpo']
        ]
    }
    else {
        o.animation.localRotation = [
            [0, 0, 0, beat(jumpInBeat + 2)],
            [...impactRotation, beat(jumpInBeat)],
            [0, 0, 0, beat(jumpInBeat * 0.75), 'easeOutExpo']
        ]
    }
}

export function simpleRotationPath(map: rm.V3Difficulty, track: string) {
    return (beat: number, rotation: rm.DifficultyPointsVec3, duration = 0, easing?: rm.EASE) => {
        return rm.assignPathAnimation(map, {
            beat,
            duration,
            easing,
            track,
            animation: {
                offsetWorldRotation: rotation
            }
        })
    }
}

export function visibility(map: rm.V3Difficulty, track: string, beat: number, visible: boolean) {
    return rm.animateTrack(map, {
        beat,
        track,
        animation: {
            dissolve: [visible ? 1 : 0],
            dissolveArrow: [visible ? 1 : 0]
        },
    })
}