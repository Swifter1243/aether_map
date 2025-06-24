import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { fadeWhite } from "../effects.ts";
import { prefabs } from "../main.ts";

export function buildup(map: rm.V3Difficulty)
{
    const buildupScene = prefabs.buildup.instantiate(map, TIMES.BUILDUP)

    fadeWhite(map, TIMES.BUILDUP, 16)

    buildupScene.destroyObject(TIMES.OUTRO)
}