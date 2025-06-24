import { materials } from "./main.ts";
import { rm } from "./deps.ts";

export function bokeh(material: rm.Material, map: rm.AbstractDifficulty, beat: number, duration = 10, radius = 25)
{
    material.blit(map, {
        beat,
        duration
    })

    material.set(map, {
        _Radius: [[radius, 0], [0, 1, 'easeOutSine']],
    }, beat, duration)
}

export function fadeWhite(map: rm.AbstractDifficulty, beat: number, duration: number, amount = 1) {
    const transitionMat = materials['fadewhite']
    const mixProperty: keyof typeof transitionMat['propertyTypes'] = '_Mix'
    transitionMat.blit(map, {
        beat: beat - duration / 2,
        duration,
        properties: [
            {
                id: mixProperty,
                type: transitionMat.propertyTypes[mixProperty],
                value: [[0, 0.48], [amount, 0.5, 'easeInCubic'], [0, 1, 'easeOutExpo']]
            }
        ]
    })
}