import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { bokeh } from "../effects.ts";
import { materials, prefabs } from "../main.ts";

export function ambient(map: rm.V3Difficulty)
{
    const ambientScene = prefabs.ambient.instantiate(map, TIMES.DROP_END)

    bokeh(materials["261 - bokeh"], map, TIMES.DROP_END, 10, 4)

    ambientScene.destroyObject(TIMES.BRIDGE)
}