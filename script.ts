import * as rm from "https://deno.land/x/remapper@4.0.0/src/mod.ts"
import * as bundleInfo from './bundleinfo.json' with { type: 'json' }

const pipeline = await rm.createPipeline({ bundleInfo })

const bundle = rm.loadBundle(bundleInfo)
const materials = bundle.materials
const prefabs = bundle.prefabs

const TIMES = {
    INTRO1: 5,
    INTRO2: 37,
    INTRO3: 64,
    FIRSTDROP_1: 69,
    FIRSTDROP_2: 77
} as const

// ----------- { SCRIPT } -----------

async function doMap(file: rm.DIFFICULTY_NAME) {
    const map = await rm.readDifficultyV3(pipeline, file)

    infoSetup(map)
    visualsSetup(map)
    
    intro(map)
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

function intro(map: rm.V3Difficulty) {
    rm.setRenderingSettings(map, {
        beat: TIMES.INTRO1,
        renderSettings: {
            skybox: materials.introskybox.path
        }
    })
    
    moveScene(map, prefabs.intro_1, TIMES.INTRO1, TIMES.INTRO2)
    moveScene(map, prefabs.intro_2, TIMES.INTRO2, TIMES.INTRO3)

    const tempScene = prefabs.intro_2.instantiate(map, TIMES.INTRO3)

    const vortexTexture1 = rm.createScreenTexture(map, {
        beat: TIMES.INTRO3,
        // xRatio: 4,
        // yRatio: 4,
        id: '_VortexTexture1'
    })

    const vortexTexture2 = rm.createScreenTexture(map, {
        beat: TIMES.INTRO3,
        id: '_VortexTexture2'
    })

    const vortexTexture3 = rm.createScreenTexture(map, {
        beat: TIMES.INTRO3,
        id: '_VortexTexture3'
    })

    const vortexDuration = 99999

    rm.blit(map, {
        beat: TIMES.INTRO3,
        asset: materials.vortexblit.path,
        destination: vortexTexture1.id,
        pass: 0,
        priority: 0,
        duration: vortexDuration
    })

    rm.blit(map, {
        beat: TIMES.INTRO3,
        asset: materials.vortexblit.path,
        destination: vortexTexture2.id,
        pass: 1,
        priority: 1,
        duration: vortexDuration
    })

    rm.blit(map, {
        beat: TIMES.INTRO3,
        asset: materials.vortexblit.path,
        destination: vortexTexture3.id,
        pass: 2,
        priority: 2,
        duration: vortexDuration
    })

    rm.blit(map, {
        beat: TIMES.INTRO3,
        asset: materials.vortexblit.path,
        pass: 3,
        priority: 0,
        duration: vortexDuration
    })
}

await Promise.all([
    doMap('ExpertPlusStandard')
])

// ----------- { OUTPUT } -----------

pipeline.export({
    outputDirectory: '../OutputMaps/Aether'
})
