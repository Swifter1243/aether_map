import { rm } from "./deps.ts"

export type ObjectPredicate = (o: rm.BeatmapObject) => boolean

export function between(start: number, end: number): ObjectPredicate {
    return (o: rm.BeatmapObject) => o.beat >= start && o.beat <= end
}

export function approximately(beat: number, lenience = 0.1): ObjectPredicate {
    return (o: rm.BeatmapObject) => Math.abs(o.beat - beat) < lenience / 2
}

export function join(...predicates: ObjectPredicate[]): ObjectPredicate {
    return (o: rm.BeatmapObject) => predicates.some(fn => fn(o))
}

export function gridYToLocalOffset(y: number): number {
    switch (y) {
        case 0:
            return 0
        case 1:
            return 0.55
        case 2:
            return 1.05
        default:
            return 0
    }
}

export function cutDirectionAngle(cut: rm.NoteCut) {
    switch (cut) {
        case rm.NoteCut.UP:
            return 180
        case rm.NoteCut.DOWN:
            return 0
        case rm.NoteCut.LEFT:
            return -90
        case rm.NoteCut.RIGHT:
            return 90
        case rm.NoteCut.UP_LEFT:
            return -135
        case rm.NoteCut.UP_RIGHT:
            return 135
        case rm.NoteCut.DOWN_LEFT:
            return -45
        case rm.NoteCut.DOWN_RIGHT:
            return 45
        case rm.NoteCut.DOT:
            return 0
    }
}

export function cutDirectionVector(cut: rm.NoteCut): rm.Vec2 {
    switch (cut) {
        case rm.NoteCut.UP:
            return [0, 1]
        case rm.NoteCut.DOWN:
            return [0, -1]
        case rm.NoteCut.LEFT:
            return [-1, 0]
        case rm.NoteCut.RIGHT:
            return [1, 0]
        case rm.NoteCut.UP_LEFT:
            return rm.normalize([-1, 1])
        case rm.NoteCut.UP_RIGHT:
            return rm.normalize([1, 1])
        case rm.NoteCut.DOWN_LEFT:
            return rm.normalize([-1, -1])
        case rm.NoteCut.DOWN_RIGHT:
            return rm.normalize([1, -1])
        case rm.NoteCut.DOT:
            return [0, 0]
    }
}

export type RandFunc = (min: number, max: number) => number

export function randomVec3(amplitude: number, random: RandFunc): rm.Vec3 {
    return [
        random(-amplitude, amplitude),
        random(-amplitude, amplitude),
        random(-amplitude, amplitude)
    ]
}

export function pointsBeatsToNormalized<T extends number[]>(points: rm.ComplexPointsAbstract<T>): {
    points: rm.ComplexPointsAbstract<T>
    minTime: number
    maxTime: number
    duration: number
} {
    let minTime = rm.getPointTime(points[0])
    let maxTime = minTime

    points.forEach((x) => {
        const time = rm.getPointTime(x)
        minTime = Math.min(minTime, time)
        maxTime = Math.max(maxTime, time)
    })

    const normalizedPoints = points.map((x) => {
        const time = rm.getPointTime(x)
        const normalizedTime = rm.inverseLerp(minTime, maxTime, time)
        rm.setPointTime(x, normalizedTime)
        return x
    })

    return {
        points: normalizedPoints,
        maxTime,
        minTime,
        duration: maxTime - minTime,
    }
}

export function sequencedRotation(map: rm.V3Difficulty, track: string, start: number, end: number, times: number[], sequenceFn: (beat: number) => rm.Vec3) {
    const totalTimes = [start, ...times, end].sort()
    const sequence: rm.Vec3[] = [[0,0,0], ...times.map(sequenceFn)]
    sequence.pop()
    sequence.push([0,0,0])

    rm.assignPathAnimation(map, {
        beat: start,
        track,
        animation: {
            offsetWorldRotation: [0, 0, 0]
        }
    })

    for (let i = 1; i < totalTimes.length - 1; i++) {
        const lastTime = totalTimes[i - 1]
        const currTime = totalTimes[i]
        const nextTime = totalTimes[i + 1]

        const inDuration = (currTime - lastTime) * 0.25
        const outDuration = (nextTime - currTime) * 0.75

        const lastVec = sequence[i - 1]
        const currVec = sequence[i]
        const midVec = rm.arrayLerp(lastVec, currVec, 0.25)

        rm.assignPathAnimation(map, {
            beat: currTime - inDuration,
            duration: inDuration,
            track,
            easing: 'easeInExpo',
            animation: {
                offsetWorldRotation: [[...midVec, 0], [0,0,0,0.5]]
            }
        })

        rm.assignPathAnimation(map, {
            beat: currTime,
            duration: outDuration,
            track,
            easing: 'easeOutSine',
            animation: {
                offsetWorldRotation: [[...currVec, 0], [0,0,0,0.5]]
            }
        })
    }
}

export function beatsToObjectSpawnLife(objectLife: number): (b: number) => number {
    return (beat: number) => rm.inverseLerp(objectLife / 2, 0, beat) * 0.5
}

export function derivativeFunction(fn: (x: number) => number) {
    return (x: number) => {
        const EPSILON = 1e-3
        const y1 = fn(x)
        const y2 = fn(x + EPSILON)
        return (y2 - y1) / (EPSILON)
    }
}

export enum DIFF_MODE {
    EXPERTPLUS,
    HARD
}

export function getDiffMode(map: rm.V3Difficulty): DIFF_MODE {
    const info = map.difficultyInfo
    if (info.characteristic === 'Lawless') 
        return DIFF_MODE.EXPERTPLUS
    return DIFF_MODE.HARD
}

export function diffValue<T>(map: rm.V3Difficulty, values: { [K in keyof typeof DIFF_MODE]: T }): T {
    const mode = getDiffMode(map)
    const key = DIFF_MODE[mode] as keyof typeof DIFF_MODE
    return values[key]
}