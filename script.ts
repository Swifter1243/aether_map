import * as rm from "https://deno.land/x/remapper@4.1.0/src/mod.ts"
import * as bundleInfo from './bundleinfo.json' with { type: 'json' }

const pipeline = await rm.createPipeline({ bundleInfo })

const bundle = rm.loadBundle(bundleInfo)
const materials = bundle.materials
const prefabs = bundle.prefabs

const TIMES = {
    INTRO: 0,
    INTRO1: 5,
    INTRO2: 37,
    INTRO3: 64,
    DROP_INTRO: 69,
    DROP: 77,
    DROP_END: 261,
    BRIDGE: 373,
    DROP2_BUILDUP: 509
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
    bridge(map)
}

function infoSetup(map: rm.V3Difficulty) {
    map.require('Vivify')
    map.require('Noodle Extensions')
    map.require('Chroma')

    map.difficultyInfo.settingsSetter = {
        graphics: {
            mainEffectGraphicsSettings: 'On',
            maxShockwaveParticles: 0,
            screenDisplacementEffectsEnabled: true,
        },
        chroma: {
            disableEnvironmentEnhancements: false,
        },
        modifiers: {
            noFailOn0Energy: true,
        },
        playerOptions: {
            leftHanded: false,
            reduceDebris: false,
            noteJumpDurationTypeSettings: 'Dynamic'
        },
        colors: {},
        environments: {},
    }
}

function visualsSetup(map: rm.V3Difficulty) {
    rm.environmentRemoval(map, [
        'Environment'
    ])
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
    const introScene = prefabs.intro.instantiate(map, TIMES.INTRO)
    
    bokeh(materials.introbokeh, map, TIMES.INTRO1, 10, 15)
    bokeh(materials.introbokeh, map, TIMES.INTRO2, 10, 15)

    introScene.destroyObject(TIMES.DROP)
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

    ambientScene.destroyObject(TIMES.BRIDGE)
}

function bridge(map: rm.V3Difficulty)
{
    const bridgeScene = prefabs.bridge.instantiate(map, TIMES.BRIDGE)

    bridgeScene.destroyObject(TIMES.DROP2_BUILDUP)
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
