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

    map.require('Vivify')
    map.require('Noodle Extensions')
    map.require('Chroma')

    rm.environmentRemoval(map, [
        'Environment'
    ])

    rm.setCameraProperty(map, {
        properties: {
            clearFlags: 'Skybox'
        }
    })

    rm.setRenderingSettings(map, {
        beat: TIMES.INTRO1,
        renderSettings: {
            skybox: materials.introskybox.path
        }
    })

    const intro1 = prefabs.intro_1.instantiate(map, TIMES.INTRO1)
    
    rm.animateTrack(map, {
        beat: TIMES.INTRO1,
        track: intro1.track.value,
        duration: TIMES.INTRO2 - TIMES.INTRO1,
        animation: {
            position: [
                [0, 0, 0, 0],
                [0, 0, -10, 1]
            ]
        }
    })
}

await Promise.all([
    doMap('ExpertPlusStandard')
])

// ----------- { OUTPUT } -----------

pipeline.export({
    outputDirectory: '../OutputMaps/Aether'
})
