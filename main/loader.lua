resourceName = GetCurrentResourceName()

function loadConfig()
    local configPath = 'config/config.lua'
    local configSource = LoadResourceFile(resourceName, configPath)

    if not configSource then
        error(('%s: arquivo %s nao encontrado'):format(resourceName, configPath))
    end

    local configChunk, loadError = load(configSource, ('@@%s/%s'):format(resourceName, configPath))

    if not configChunk then
        error(loadError)
    end

    return configChunk()
end

Config = loadConfig()
