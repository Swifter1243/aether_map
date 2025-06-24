import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { fadeWhite } from "../effects.ts";
import { materials, prefabs } from "../main.ts";

export function buildup(map: rm.V3Difficulty)
{
    const buildupScene = prefabs.buildup.instantiate(map, TIMES.BUILDUP)

    fadeWhite(map, TIMES.BUILDUP, 16)

    materials["541 - terrain"].set(map, {
        _Light1Strength: [[0, 0], [1, 1]]
    }, 541, 20)

    buildupScene.destroyObject(TIMES.OUTRO)
}