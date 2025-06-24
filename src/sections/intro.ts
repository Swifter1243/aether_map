import { TIMES } from "../constants.ts";
import { rm } from "../deps.ts";
import { bokeh } from "../effects.ts";
import { materials, prefabs } from "../main.ts";

export function intro(map: rm.V3Difficulty) {
    const introScene = prefabs.intro.instantiate(map, TIMES.INTRO)
    
    bokeh(materials.introbokeh, map, TIMES.INTRO1, 10, 15)
    bokeh(materials.introbokeh, map, TIMES.INTRO2, 10, 15)

    introScene.destroyObject(TIMES.DROP)
}