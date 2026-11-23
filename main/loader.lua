resourceName = GetCurrentResourceName()

local function loadFile(path)
    local source = LoadResourceFile(resourceName, path)

    if not source then
        error(('%s: file %s not found'):format(resourceName, path))
    end

    local chunk, loadError = load(source, ('@@%s/%s'):format(resourceName, path))

    if not chunk then
        error(loadError)
    end

    return chunk()
end

local function loadLang(language)
    local languages = loadFile('config/lang.lua')
    local texts = languages[language]

    if not texts then
        print(('^3[%s] LANGUAGE "%s" not found in config/lang.lua, using "en"^0'):format(resourceName, tostring(language)))
        texts = languages['en']
    end

    return texts
end

Config = loadFile('config/config.lua')
Lang = loadLang(Config.LANGUAGE or 'en')
