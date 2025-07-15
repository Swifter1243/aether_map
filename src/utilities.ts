import { rm } from "./deps.ts";

export function between(start: number, end: number) {
    return (o: rm.BeatmapObject) => o.beat >= start && o.beat <= end
}

export function pointsBeatsToNormalized<T extends number[]>(points: rm.ComplexPointsAbstract<T>): {
    points: rm.ComplexPointsAbstract<T>,
    minTime: number,
    maxTime: number,
    duration: number
} {
    let minTime = rm.getPointTime(points[0])
    let maxTime = minTime

    points.forEach(x => {
        const time = rm.getPointTime(x)
        minTime = Math.min(minTime, time)
        maxTime = Math.max(maxTime, time)
    })

    const normalizedPoints = points.map(x => {
        const time = rm.getPointTime(x)
        const normalizedTime = rm.inverseLerp(minTime, maxTime, time)
        rm.setPointTime(x, normalizedTime)
        return x
    })

    return {
        points: normalizedPoints,
        maxTime,
        minTime,
        duration: maxTime - minTime
    }
}