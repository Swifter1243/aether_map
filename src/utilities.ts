import { rm } from "./deps.ts";

export function between(start: number, end: number) {
    return (o: rm.BeatmapObject) => o.beat >= start && o.beat <= end
}