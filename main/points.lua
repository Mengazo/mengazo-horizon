local registeredPoints = {}
local blipDetails = {}
local hudColourCache = {}

function formatPointCoords(coords)
    local coordsType = type(coords)

    if coordsType == 'vector3' then
        return coords
    end

    if coordsType == 'vector4' then
        return vector3(coords.x, coords.y, coords.z)
    end

    if coordsType == 'table' and tonumber(coords.x) and tonumber(coords.y) then
        return vector3(tonumber(coords.x) + 0.0, tonumber(coords.y) + 0.0, (tonumber(coords.z) or 0.0) + 0.0)
    end

    return nil
end

function formatPointText(value, fallback)
    if type(value) == 'string' and value ~= '' then
        return value
    end

    return fallback
end

function formatPointDetails(details)
    return {
        label = formatPointText(details.label, nil),
        description = formatPointText(details.description, nil),
        color = formatPointText(details.color, nil),
        icon = formatPointText(details.icon, nil),
        image = formatPointText(details.image, nil),
        priority = tonumber(details.priority) or 0,
        hidden = details.hidden == true,
    }
end

function registerPoint(pointId, pointData)
    local pointIdType = type(pointId)

    if (pointIdType ~= 'string' and pointIdType ~= 'number') or type(pointData) ~= 'table' then
        return false
    end

    local pointCoords = formatPointCoords(pointData.coords)

    if not pointCoords then
        return false
    end

    local pointKey = tostring(pointId)
    local pointDetails = formatPointDetails(pointData)

    registeredPoints[pointKey] = {
        id = 'point:' .. pointKey,
        coords = pointCoords,
        label = pointDetails.label or Config.DEFAULT_LABEL,
        description = pointDetails.description or '',
        color = pointDetails.color or Config.THEME_COLOR,
        icon = pointDetails.icon or Config.DEFAULT_ICON,
        image = pointDetails.image or '',
        priority = pointDetails.priority,
        owner = GetInvokingResource() or resourceName,
    }

    return true
end

function removePoint(pointId)
    local pointKey = tostring(pointId)

    if not registeredPoints[pointKey] then
        return false
    end

    registeredPoints[pointKey] = nil

    return true
end

function setBlipDetails(blip, details)
    if type(blip) ~= 'number' or type(details) ~= 'table' or not DoesBlipExist(blip) then
        return false
    end

    local formattedDetails = formatPointDetails(details)

    formattedDetails.owner = GetInvokingResource() or resourceName
    blipDetails[blip] = formattedDetails

    return true
end

function clearBlipDetails(blip)
    if not blipDetails[blip] then
        return false
    end

    blipDetails[blip] = nil

    return true
end

function removePointsByOwner(ownerResource)
    for pointKey, point in pairs(registeredPoints) do
        if point.owner == ownerResource then
            registeredPoints[pointKey] = nil
        end
    end

    for blip, details in pairs(blipDetails) do
        if details.owner == ownerResource then
            blipDetails[blip] = nil
        end
    end
end

function registerConfigPoints()
    for index = 1, #Config.CUSTOM_POINTS do
        local customPoint = Config.CUSTOM_POINTS[index]

        registerPoint(customPoint.ID or ('config' .. index), {
            coords = customPoint.COORDS,
            label = customPoint.LABEL,
            description = customPoint.DESCRIPTION,
            color = customPoint.COLOR,
            icon = customPoint.ICON,
            image = customPoint.IMAGE,
            priority = customPoint.PRIORITY,
        })
    end
end

function getBlipColor(blip)
    local hudColourIndex = GetBlipHudColour(blip)

    if not hudColourCache[hudColourIndex] then
        local red, green, blue = GetHudColour(hudColourIndex)

        hudColourCache[hudColourIndex] = ('#%02x%02x%02x'):format(red, green, blue)
    end

    return hudColourCache[hudColourIndex]
end

function getLocationLabel(coords)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = streetHash ~= 0 and GetStreetNameFromHashKey(streetHash) or ''
    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

    if not zoneName or zoneName == 'NULL' then
        zoneName = ''
    end

    if streetName ~= '' and zoneName ~= '' then
        return streetName .. ' · ' .. zoneName
    end

    return streetName ~= '' and streetName or zoneName
end

function getGameBlipCandidate(blip, sprite, originCoords)
    local details = blipDetails[blip]

    if details and details.hidden then
        return nil
    end

    if not Config.BLIP_TYPES[GetBlipInfoIdType(blip)] then
        return nil
    end

    if GetBlipInfoIdDisplay(blip) == 0 or GetBlipAlpha(blip) == 0 then
        return nil
    end

    local blipCoords = GetBlipInfoIdCoord(blip)
    local distance = #(originCoords - blipCoords)

    if distance < Config.MIN_DISTANCE or distance > Config.MAX_DISTANCE then
        return nil
    end

    return {
        id = 'blip:' .. blip,
        blip = blip,
        sprite = sprite,
        coords = blipCoords,
        distance = distance,
        priority = (details and details.priority) or 0,
        details = details,
    }
end

function getGameBlipLabel(candidate)
    local details = candidate.details

    if details and details.label then
        return details.label, false
    end

    if hasBlipName(candidate.blip) then
        return false, true
    end

    local spriteLabel = 'BLIP_' .. candidate.sprite

    if DoesTextLabelExist(spriteLabel) then
        return GetLabelText(spriteLabel), false
    end

    return Config.DEFAULT_LABEL, false
end

function formatGameBlipPoint(candidate)
    local details = candidate.details
    local label, nativeName = getGameBlipLabel(candidate)
    local usesCustomIcon = details ~= nil and details.icon ~= nil

    return {
        id = candidate.id,
        blip = candidate.blip,
        sprite = not usesCustomIcon and candidate.sprite or nil,
        coords = candidate.coords,
        distance = candidate.distance,
        priority = candidate.priority,
        label = label,
        nativeName = nativeName,
        location = getLocationLabel(candidate.coords),
        description = (details and details.description) or '',
        color = (details and details.color) or getBlipColor(candidate.blip),
        icon = (details and details.icon) or Config.DEFAULT_ICON,
        image = (details and details.image) or '',
    }
end

function formatRegisteredPoint(candidate)
    local registeredPoint = candidate.registeredPoint

    return {
        id = candidate.id,
        coords = candidate.coords,
        distance = candidate.distance,
        priority = candidate.priority,
        label = registeredPoint.label,
        nativeName = false,
        location = getLocationLabel(candidate.coords),
        description = registeredPoint.description,
        color = registeredPoint.color,
        icon = registeredPoint.icon,
        image = registeredPoint.image,
    }
end

function collectGameBlipCandidates(originCoords, candidates)
    for sprite = 0, Config.MAX_SPRITE_ID do
        if not Config.IGNORED_SPRITES[sprite] then
            local blip = GetFirstBlipInfoId(sprite)

            while DoesBlipExist(blip) do
                local candidate = getGameBlipCandidate(blip, sprite, originCoords)

                if candidate then
                    candidates[#candidates + 1] = candidate
                end

                blip = GetNextBlipInfoId(sprite)
            end
        end
    end

    for blip in pairs(blipDetails) do
        if not DoesBlipExist(blip) then
            blipDetails[blip] = nil
        end
    end
end

function collectRegisteredCandidates(originCoords, candidates)
    for _, registeredPoint in pairs(registeredPoints) do
        local distance = #(originCoords - registeredPoint.coords)

        if distance >= Config.MIN_DISTANCE and distance <= Config.MAX_DISTANCE then
            candidates[#candidates + 1] = {
                id = registeredPoint.id,
                coords = registeredPoint.coords,
                distance = distance,
                priority = registeredPoint.priority,
                registeredPoint = registeredPoint,
            }
        end
    end
end

function collectPoints(originCoords)
    local candidates = {}
    local points = {}

    collectRegisteredCandidates(originCoords, candidates)

    if Config.SCAN_GAME_BLIPS then
        collectGameBlipCandidates(originCoords, candidates)
    end

    table.sort(candidates, function(firstCandidate, secondCandidate)
        if firstCandidate.priority ~= secondCandidate.priority then
            return firstCandidate.priority > secondCandidate.priority
        end

        return firstCandidate.distance < secondCandidate.distance
    end)

    for index = 1, math.min(#candidates, Config.MAX_MARKERS) do
        local candidate = candidates[index]

        points[index] = candidate.blip and formatGameBlipPoint(candidate) or formatRegisteredPoint(candidate)
    end

    return points
end
