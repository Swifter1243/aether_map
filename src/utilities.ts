import { rm } from "./deps.ts"

export function between(start: number, end: number) {
    return (o: rm.BeatmapObject) => o.beat >= start && o.beat <= end
}

export function approximately(beat: number, lenience = 0.1) {
    return (o: rm.BeatmapObject) => Math.abs(o.beat - beat) < lenience / 2
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
