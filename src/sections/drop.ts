import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { fadeWhite } from "../effects.ts";
import { prefabs } from "../main.ts";

export function drop(map: rm.V3Difficulty)
{
    const dropScene = prefabs.drop.instantiate(map, TIMES.DROP)

    fadeWhite(map, TIMES.DROP_END, 16)

    dropScene.destroyObject(TIMES.DROP_END)
}