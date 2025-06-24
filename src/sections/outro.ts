import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { prefabs } from "../main.ts";

export function outro(map: rm.V3Difficulty)
{
    const outroScene = prefabs.outro.instantiate(map, TIMES.OUTRO)
}