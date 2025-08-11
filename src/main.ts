import { rm } from './deps.ts'
import * as bundleInfo from '../bundleinfo.json' with { type: 'json' }
import { intro } from './sections/intro.ts';
import { drop } from './sections/drop.ts';
import { ambient } from './sections/ambient.ts';
import { bridge } from './sections/bridge.ts';
import { buildup } from './sections/buildup.ts';
import { outro } from './sections/outro.ts';

export const pipeline = await rm.createPipeline({ bundleInfo })

export const bundle = rm.loadBundle(bundleInfo)
export const materials = bundle.materials
export const prefabs = bundle.prefabs

// ----------- { SCRIPT } -----------

// contains timing guides!
export const lightShow = await rm.readDifficultyV3(pipeline, 'ExpertPlusLightshow')
delete pipeline.info.difficultyBeatmaps['ExpertPlusLightshow.dat']

async function doMap(file: rm.DIFFICULTY_NAME) {
    const map = await rm.readDifficultyV3(pipeline, file)

    infoSetup(map)
    visualsSetup(map)
    
    intro(map)
    drop(map)
    ambient(map)
    bridge(map)
    buildup(map)
    outro(map)
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

    map.allNotes.forEach(x => {
        if (!(x instanceof rm.Arc || x instanceof rm.Chain)) {
            x.spawnEffect = false
        }
    })

    rm.setCameraProperty(map, {
        properties: {
            depthTextureMode: ['Depth']
        }
    })

    rm.setRenderingSettings(map, {
        qualitySettings: {
            antiAliasing: rm.ANTI_ALIASING.None
        }
    })
}

await Promise.all([
    doMap('ExpertPlusLawless'),
    doMap('HardStandard')
])

// ----------- { OUTPUT } -----------

pipeline.export({
    outputDirectory: '../OutputMaps/Aether',
    zip: {
        name: 'Aether',
        includeBundles: true
    }
})
