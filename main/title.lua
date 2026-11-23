local MEASURE_SCALE = 0.5
local MINIMUM_SCALE_RATIO = 0.6
local SLOT_BLEED = 0.003
local PANEL_RED = 17
local PANEL_GREEN = 17
local PANEL_BLUE = 18

local titleSlot = nil
local activeTitleBlip = nil
local activeTitleScale = 0.0

function applyTitleTextStyle(textScale)
    SetTextFont(Config.TITLE_FONT)
    SetTextScale(textScale, textScale)
    SetTextColour(255, 255, 255, 255)
end

function getBlipNameWidth(blip, textScale)
    applyTitleTextStyle(textScale)
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringBlipName(blip)

    return EndTextCommandGetWidth(true)
end

function hasBlipName(blip)
    return getBlipNameWidth(blip, MEASURE_SCALE) > 0.0
end

function getTitleScale(blip)
    local unitCharacterHeight = GetRenderedCharacterHeight(1.0, Config.TITLE_FONT)

    if unitCharacterHeight <= 0.0 then
        return MEASURE_SCALE
    end

    local titleScale = titleSlot.height * Config.TITLE_HEIGHT_RATIO / unitCharacterHeight
    local nameWidth = getBlipNameWidth(blip, titleScale)

    if nameWidth > titleSlot.width then
        return math.max(titleScale * titleSlot.width / nameWidth, titleScale * MINIMUM_SCALE_RATIO)
    end

    return titleScale
end

function setTitleSlot(slotData)
    if type(slotData) ~= 'table' or type(slotData.pointId) ~= 'string' then
        return false
    end

    local slotX = tonumber(slotData.x)
    local slotY = tonumber(slotData.y)
    local slotWidth = tonumber(slotData.width)
    local slotHeight = tonumber(slotData.height)

    if not slotX or not slotY or not slotWidth or not slotHeight or slotWidth <= 0.0 or slotHeight <= 0.0 then
        return false
    end

    titleSlot = { pointId = slotData.pointId, x = slotX, y = slotY, width = slotWidth, height = slotHeight }
    activeTitleBlip = nil

    return true
end

function resetTitleSlot()
    titleSlot = nil
    activeTitleBlip = nil
end

function drawBlipTitle(point)
    if not titleSlot or titleSlot.pointId ~= point.id or not DoesBlipExist(point.blip) then
        return false
    end

    if activeTitleBlip ~= point.blip then
        activeTitleBlip = point.blip
        activeTitleScale = getTitleScale(point.blip)
    end

    local characterHeight = GetRenderedCharacterHeight(activeTitleScale, Config.TITLE_FONT)
    local textY = titleSlot.y + (titleSlot.height - characterHeight) / 2 + Config.TITLE_OFFSET_Y

    DrawRect(titleSlot.x + titleSlot.width / 2, titleSlot.y + titleSlot.height / 2, titleSlot.width + SLOT_BLEED, titleSlot.height + SLOT_BLEED, PANEL_RED, PANEL_GREEN, PANEL_BLUE, 255)

    applyTitleTextStyle(activeTitleScale)
    SetTextWrap(titleSlot.x, titleSlot.x + titleSlot.width)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringBlipName(point.blip)
    EndTextCommandDisplayText(titleSlot.x, textY)

    return true
end

RegisterNUICallback('titleSlot', function(slotData, sendResponse)
    setTitleSlot(slotData)
    sendResponse({})
end)
