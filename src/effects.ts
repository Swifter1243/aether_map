import { materials } from "./main.ts";
import { rm } from "./deps.ts";
import { beatsToObjectSpawnLife, between, cutDirectionAngle, cutDirectionVector, gridYToLocalOffset, RandFunc, randomVec3, sequencedRotation } from './utilities.ts'

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
                offsetWorldRotation: [[-dir[1] * magnitude, dir[0] * magnitude, 0, 0], [0,0,0,0.5, 'easeOutCirc']]
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

function getFakeJumpTrack(y: number) {
    return `fakeJump${y}`
}

export type FakeJumpsContext = {
    objectLife: number,
    jumpInBeat: number,
    jumpInDuration: number
}

export function setFakeJumps(map: rm.V3Difficulty, beat: number, context: FakeJumpsContext): FakeJumpsContext {
    const fromBeat = beatsToObjectSpawnLife(context.objectLife)

    for (let y = 0; y <= 2; y++) {
        const invY = -gridYToLocalOffset(y) / 0.6
        const track = getFakeJumpTrack(y)

        rm.assignPathAnimation(map, {
            beat,
            track,
            animation: {
                offsetPosition: [
                    [0, invY, 10, fromBeat(context.jumpInBeat + context.jumpInDuration)], 
                    [0, invY, 0, fromBeat(context.jumpInBeat), 'easeInExpo'], 
                    [0, 0, 0, 0.5, 'easeOutQuad']
                ]
            }
        })
    }

    return context
}

const RANDOM_NOTE_SPAWN_ROTATIONS = [
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

function getRandomNoteSpawnRotation(random: RandFunc): rm.Vec3 {
    const index = Math.floor(random(0, RANDOM_NOTE_SPAWN_ROTATIONS.length))
    return RANDOM_NOTE_SPAWN_ROTATIONS[index]
}

export function applyFakeJumps(o: rm.BeatmapGameplayObject, random: RandFunc, context: FakeJumpsContext) {
    const fromBeat = beatsToObjectSpawnLife(context.objectLife)

    const track = getFakeJumpTrack(o.y)
    o.track.add(track)
    
    const impactRotation = getRandomNoteSpawnRotation(random)
    if (o instanceof rm.ColorNote) {
        const invRotation: rm.Vec3 = [0, 0, -(cutDirectionAngle(o.cutDirection) + 180) % 360]
        o.animation.localRotation = [
            [...invRotation, fromBeat(context.jumpInBeat + 2)],
            [...rm.combineRotations(impactRotation, invRotation), fromBeat(context.jumpInBeat)],
            [0, 0, 0, fromBeat(context.jumpInBeat * 0.5), 'easeOutExpo']
        ]
    }
    else {
        o.animation.localRotation = [
            [0, 0, 0, fromBeat(context.jumpInBeat + 2)],
            [...impactRotation, fromBeat(context.jumpInBeat)],
            [0, 0, 0, fromBeat(context.jumpInBeat * 0.75), 'easeOutExpo']
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

export function wheelEffect(map: rm.V3Difficulty, yIncrement: number, times: number[]) {
    const start = times.reduce((a, b) => Math.min(a, b))
    const end = times.reduce((a, b) => Math.max(a, b))
    const notes = map.allNotes.filter(between(start, end))

    const timeGroups: Record<number, rm.AnyNote[]> = rm.arraySplit2(notes, (x) => {
        let time = 0

        times.forEach((t) => {
            if (x.beat >= t) {
                time = t
            }
        })

        return time
    })

    const accumulatedTracks: string[] = []

    Object.entries(timeGroups)
        .sort((a, b) => parseFloat(a[0]) - parseFloat(b[0]))
        .forEach(([_, timeNotes], i) => {
            if (i === 0) {
                return
            }

            const beat = times[i - 1]
            const track = `wheelNote${i}`
            accumulatedTracks.push(track)
            const tracks = rm.copy(accumulatedTracks)

            const shakeX = rm.random(-1, 1)

            rm.assignPathAnimation(map, {
                beat: start - timeNotes[0].life / 2 - 6,
                track: track,
                animation: {
                    offsetWorldRotation: [[shakeX, yIncrement * 2, 0, 0], [shakeX, yIncrement, 0, 0.5]],
                },
            })

            rm.assignPathAnimation(map, {
                beat,
                duration: 2,
                easing: 'easeOutExpo',
                track: track,
                animation: {
                    offsetWorldRotation: [0, 0, 0],
                },
            })

            timeNotes.forEach((x) => {
                x.track.add(tracks)
            })
        })
}

export function noteHop(x: rm.AnyNote, distance = 12, duration = 2) {
    x.noteJumpMovementSpeed = 0.002
    x.life = duration * 2
    x.disableNoteGravity = true
    x.animation.dissolve = [[0, 0], [1, 0]]
    x.animation.dissolveArrow = x.animation.dissolve
    x.animation.offsetPosition = [
        [0, 0, distance / 2, 0],
        [0, 0, distance, 0.25, 'easeOutCirc'],
        [0, 0, 0, 0.5, 'easeInSine'],
        [0, 0, -distance * 2.5, 1, 'easeLinear'],
    ]
}