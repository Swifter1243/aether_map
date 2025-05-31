import * as rm from "https://deno.land/x/remapper@4.1.0/src/mod.ts"
import * as bundleInfo from './bundleinfo.json' with { type: 'json' }

const pipeline = await rm.createPipeline({ bundleInfo })

const bundle = rm.loadBundle(bundleInfo)
const materials = bundle.materials
const prefabs = bundle.prefabs

const TIMES = {
    INTRO1: 5,
    INTRO2: 37,
    INTRO3: 64,
    DROP_INTRO: 69,
    DROP: 77,
    DROP_END: 261
} as const

// ----------- { SCRIPT } -----------

async function doMap(file: rm.DIFFICULTY_NAME) {
    const map = await rm.readDifficultyV3(pipeline, file)

    infoSetup(map)
    visualsSetup(map)
    
    intro(map)
    drop(map)

    const dropAmbientTransitionDuration = 16
    const transitionMat = materials['drop-ambient transition']
    const mixProperty: keyof typeof transitionMat['propertyTypes'] = '_Mix'
    transitionMat.blit(map, {
        beat: TIMES.DROP_END - dropAmbientTransitionDuration / 2,
        duration: dropAmbientTransitionDuration,
        properties: [
            {
                id: mixProperty,
                type: transitionMat.propertyTypes[mixProperty],
                value: [[0, 0.48], [1, 0.5, 'easeInCubic'], [0, 1, 'easeOutExpo']]
            }
        ]
    })

    ambient(map)
}

function infoSetup(map: rm.V3Difficulty) {
    map.require('Vivify')
    map.require('Noodle Extensions')
    map.require('Chroma')
}

function visualsSetup(map: rm.V3Difficulty) {
    rm.environmentRemoval(map, [
        'Environment'
    ])

    rm.setCameraProperty(map, {
        properties: {
            clearFlags: 'Skybox'
        }
    })
}

function moveScene(map: rm.V3Difficulty, prefab: rm.Prefab, start: number, end: number, movementSpeed = 0.5) {
    const dur = end - start

    const instance = prefab.instantiate(map, start)

    rm.animateTrack(map, {
        beat: start,
        track: instance.track.value,
        duration: dur,
        animation: {
            position: [
                [0, 0, 0, 0],
                [0, 0, -dur * movementSpeed, 1]
            ]
        }
    })

    instance.destroyObject(end)
}

function bokeh(material: rm.Material, map: rm.AbstractDifficulty, beat: number, duration = 10, radius = 25)
{
    material.blit(map, {
        beat,
        duration
    })

    material.set(map, {
        _Radius: [[radius, 0], [0, 1, 'easeOutSine']],
    }, beat, duration)
}

function intro(map: rm.V3Difficulty) {
    rm.setRenderingSettings(map, {
        beat: TIMES.INTRO1,
        renderSettings: {
            skybox: materials.introskybox.path
        }
    })
    
    moveScene(map, prefabs.intro_1, TIMES.INTRO1, TIMES.INTRO2)
    bokeh(materials.introbokeh, map, TIMES.INTRO1)
    moveScene(map, prefabs.intro_2, TIMES.INTRO2, TIMES.INTRO3)
    bokeh(materials.introbokeh, map, TIMES.INTRO2)

    const tempScene = prefabs.intro_2.instantiate(map, TIMES.INTRO3)

    const vortexTexture1 = rm.createScreenTexture(map, {
        beat: TIMES.DROP_INTRO,
        id: '_VortexTexture1'
    })

    const vortexDuration = TIMES.DROP - TIMES.DROP_INTRO

    rm.blit(map, {
        beat: TIMES.DROP_INTRO,
        asset: materials.vortexblit.path,
        destination: vortexTexture1.id,
        pass: 0,
        priority: 0,
        duration: vortexDuration
    })

    rm.blit(map, {
        beat: TIMES.DROP_INTRO,
        asset: materials.vortexblit.path,
        pass: 1,
        priority: 1,
        duration: vortexDuration
    })

    vortexTexture1.destroyObject(TIMES.DROP)
    tempScene.destroyObject(TIMES.DROP)
}

function drop(map: rm.V3Difficulty)
{
    const dropScene = prefabs.drop.instantiate(map, TIMES.DROP)

    dropScene.destroyObject(TIMES.DROP_END)
}

function ambient(map: rm.V3Difficulty)
{
    const ambientScene = prefabs.ambient.instantiate(map, TIMES.DROP_END)

    bokeh(materials["261 - bokeh"], map, TIMES.DROP_END, 10, 4)

    // TODO: ambientScene.destroyObject(???)
}

await Promise.all([
    doMap('ExpertPlusStandard')
])

// ----------- { OUTPUT } -----------

pipeline.export({
    outputDirectory: '../OutputMaps/Aether',
    zip: {
        name: 'Aether',
        includeBundles: true
    }
})
