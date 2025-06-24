import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { prefabs } from "../main.ts";

export function bridge(map: rm.V3Difficulty)
{
    const bridgeScene = prefabs.bridge.instantiate(map, TIMES.BRIDGE)

    bridgeScene.destroyObject(TIMES.BUILDUP)
}