local POINT_STATE_VISIBLE = 0
local POINT_STATE_EDGE_LEFT = 1
local POINT_STATE_EDGE_RIGHT = 2
local POINT_STATE_HIDDEN = 3

local EDGE_LEFT_POSITION = 0.014
local EDGE_RIGHT_POSITION = 0.986
local EDGE_VERTICAL_SPACING = 0.055
local EDGE_MARGIN = 0.035
local MAX_CAMERA_PITCH = 80.0
local DESTINATION_TOLERANCE = 5.0
local CLOSE_GUARD_TIME = 250
local CONTROL_RELEASE_TIMEOUT = 2000
local MAP_OPEN_DELAY = 100
local PAUSE_MENU_HASH = GetHashKey('FE_MENU_VERSION_MP_PAUSE')

local horizonActive = false
local blurWanted = false
local blurApplied = false
local blurSyncRunning = false
local horizonToken = 0
local trackedPoints = {}
local destinationPointId = nil
local destinationCoords = nil

function isHorizonActive()
    return horizonActive
end

function canOpenHorizon()
    if IsPauseMenuActive() or IsNuiFocused() then
        return false
    end

    return Config.CAN_OPEN() ~= false
end

function getActiveDestinationId()
    if not destinationPointId then
        return nil
    end

    local waypointBlip = GetFirstBlipInfoId(GetWaypointBlipEnumId())

    if not IsWaypointActive() or not DoesBlipExist(waypointBlip) then
        destinationPointId = nil
        destinationCoords = nil

        return nil
    end

    local waypointCoords = GetBlipInfoIdCoord(waypointBlip)

    if #(vector2(waypointCoords.x, waypointCoords.y) - vector2(destinationCoords.x, destinationCoords.y)) > DESTINATION_TOLERANCE then
        destinationPointId = nil
        destinationCoords = nil

        return nil
    end

    return destinationPointId
end

function refreshTrackedPoints()
    trackedPoints = collectPoints(GetEntityCoords(PlayerPedId()))

    local pointList = {}

    for index = 1, #trackedPoints do
        local point = trackedPoints[index]

        pointList[index] = {
            id = point.id,
            label = point.label,
            location = point.location,
            description = point.description,
            color = point.color,
            icon = point.icon,
            image = point.image,
            sprite = point.sprite or false,
        }
    end

    SendNUIMessage({ action = 'points', data = { list = pointList, destination = getActiveDestinationId() or false } })
end

function getPointScreenSide(cameraCoords, cameraHeading, pointCoords)
    local headingRadians = math.rad(cameraHeading)
    local forwardX = -math.sin(headingRadians)
    local forwardY = math.cos(headingRadians)
    local crossProduct = forwardX * (pointCoords.y - cameraCoords.y) - forwardY * (pointCoords.x - cameraCoords.x)

    if crossProduct > 0.0 then
        return POINT_STATE_EDGE_LEFT
    end

    return POINT_STATE_EDGE_RIGHT
end

function getPointScreenPosition(cameraCoords, cameraPitchTangent, pointCoords)
    local minimumY = Config.VERTICAL_LIMITS[1]
    local maximumY = Config.VERTICAL_LIMITS[2]
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(pointCoords.x, pointCoords.y, pointCoords.z)

    if onScreen then
        return true, screenX, math.min(math.max(screenY, minimumY), maximumY)
    end

    local horizontalDistance = #(vector2(pointCoords.x, pointCoords.y) - vector2(cameraCoords.x, cameraCoords.y))
    local sightHeight = cameraCoords.z + horizontalDistance * cameraPitchTangent

    onScreen, screenX = GetScreenCoordFromWorldCoord(pointCoords.x, pointCoords.y, sightHeight)

    if not onScreen then
        return false, 0.0, 0.0
    end

    if pointCoords.z > sightHeight then
        return true, screenX, minimumY
    end

    return true, screenX, maximumY
end

function isScreenPositionFree(acceptedPositions, screenX, screenY, aspectRatio)
    local screenSpacing = Config.SCREEN_SPACING

    if screenSpacing <= 0.0 then
        return true
    end

    for index = 1, #acceptedPositions do
        local acceptedPosition = acceptedPositions[index]

        if math.abs(acceptedPosition.x - screenX) * aspectRatio < screenSpacing and math.abs(acceptedPosition.y - screenY) < screenSpacing then
            return false
        end
    end

    return true
end

function getEdgeSlotPosition(edgeSlot)
    return 0.5 + (edgeSlot - (Config.EDGE_MAX_PER_SIDE + 1) / 2) * EDGE_VERTICAL_SPACING
end

function updateHorizonFrame()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local cameraCoords = GetFinalRenderedCamCoord()
    local cameraRotation = GetFinalRenderedCamRot(2)
    local cameraPitch = math.min(math.max(cameraRotation.x, -MAX_CAMERA_PITCH), MAX_CAMERA_PITCH)
    local cameraPitchTangent = math.tan(math.rad(cameraPitch))
    local aspectRatio = GetAspectRatio(false)
    local focusRadius = Config.FOCUS_RADIUS
    local framePoints = {}
    local acceptedPositions = {}
    local edgeCounts = { [POINT_STATE_EDGE_LEFT] = 0, [POINT_STATE_EDGE_RIGHT] = 0 }
    local focusedPoint = nil
    local focusedDistance = focusRadius

    for index = 1, #trackedPoints do
        local point = trackedPoints[index]
        local pointState = POINT_STATE_HIDDEN
        local onScreen, screenX, screenY = getPointScreenPosition(cameraCoords, cameraPitchTangent, point.coords)

        if onScreen and (screenX < EDGE_MARGIN or screenX > 1.0 - EDGE_MARGIN) then
            onScreen = false
        end

        if onScreen then
            if isScreenPositionFree(acceptedPositions, screenX, screenY, aspectRatio) then
                pointState = POINT_STATE_VISIBLE
                acceptedPositions[#acceptedPositions + 1] = { x = screenX, y = screenY }

                local centerOffsetX = (screenX - 0.5) * aspectRatio
                local centerOffsetY = screenY - 0.5
                local centerDistance = math.sqrt(centerOffsetX * centerOffsetX + centerOffsetY * centerOffsetY)

                if centerDistance <= focusedDistance then
                    focusedDistance = centerDistance
                    focusedPoint = point
                end
            end
        elseif Config.EDGE_INDICATORS then
            local edgeState = getPointScreenSide(cameraCoords, cameraRotation.z, point.coords)

            if edgeCounts[edgeState] < Config.EDGE_MAX_PER_SIDE then
                edgeCounts[edgeState] = edgeCounts[edgeState] + 1
                pointState = edgeState
                screenX = edgeState == POINT_STATE_EDGE_LEFT and EDGE_LEFT_POSITION or EDGE_RIGHT_POSITION
                screenY = getEdgeSlotPosition(edgeCounts[edgeState])
            end
        end

        framePoints[index] = { point.id, screenX, screenY, math.floor(#(playerCoords - point.coords)), pointState }
    end

    SendNUIMessage({ action = 'frame', data = { focused = focusedPoint and focusedPoint.id or false, points = framePoints } })

    return focusedPoint
end

function drawHorizonVeil()
    if Config.DARKEN_OPACITY > 0 then
        DrawRect(0.5, 0.5, 1.0, 1.0, 5, 5, 7, Config.DARKEN_OPACITY)
    end
end

function disableHorizonControls()
    local disabledControls = Config.DISABLED_CONTROLS

    for index = 1, #disabledControls do
        DisableControlAction(0, disabledControls[index], true)
    end

    DisableControlAction(0, Config.CONTROLS.SET_DESTINATION.CONTROL, true)
    DisableControlAction(0, Config.CONTROLS.VIEW_ON_MAP.CONTROL, true)
end

function toggleDestination(point)
    if getActiveDestinationId() == point.id then
        SetWaypointOff()

        destinationPointId = nil
        destinationCoords = nil
    else
        SetNewWaypoint(point.coords.x, point.coords.y)

        destinationPointId = point.id
        destinationCoords = point.coords
    end

    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    SendNUIMessage({ action = 'destination', data = { id = destinationPointId or false } })
    TriggerEvent(resourceName .. ':destinationChanged', destinationPointId, point.coords)

    if destinationPointId and Config.CLOSE_ON_DESTINATION then
        closeHorizon()
    end
end

function waitControlRelease(control)
    local releaseTimeout = GetGameTimer() + CONTROL_RELEASE_TIMEOUT

    while GetGameTimer() < releaseTimeout and (IsControlPressed(0, control) or IsDisabledControlPressed(0, control)) do
        disableHorizonControls()
        Wait(0)
    end
end

function showPointOnMap(point)
    local pointCoords = point.coords

    closeHorizon()

    if point.blip and DoesBlipExist(point.blip) then
        SetBlipFlashes(point.blip, true)
        SetBlipFlashTimer(point.blip, Config.MAP_FLASH_TIME)
    end

    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    TriggerEvent(resourceName .. ':viewedOnMap', point.id, pointCoords)

    CreateThread(function()
        waitControlRelease(Config.CONTROLS.VIEW_ON_MAP.CONTROL)
        Wait(MAP_OPEN_DELAY)

        if horizonActive or IsPauseMenuActive() then
            return
        end

        ActivateFrontendMenu(PAUSE_MENU_HASH, false, -1)

        local centerUntil = GetGameTimer() + Config.MAP_CENTER_TIME

        while GetGameTimer() < centerUntil do
            SetFakePausemapPlayerPositionThisFrame(pointCoords.x, pointCoords.y)
            Wait(0)
        end
    end)
end

function handleFocusedPointControls(focusedPoint)
    if IsDisabledControlJustPressed(0, Config.CONTROLS.SET_DESTINATION.CONTROL) then
        toggleDestination(focusedPoint)

        return
    end

    if IsDisabledControlJustPressed(0, Config.CONTROLS.VIEW_ON_MAP.CONTROL) then
        showPointOnMap(focusedPoint)
    end
end

function startHorizonLoop(loopToken)
    CreateThread(function()
        local nextScanAt = 0

        while horizonActive and horizonToken == loopToken do
            local gameTimer = GetGameTimer()

            if IsPauseMenuActive() or IsNuiFocused() then
                closeHorizon()

                break
            end

            if gameTimer >= nextScanAt then
                if Config.CAN_OPEN() == false then
                    closeHorizon()

                    break
                end

                refreshTrackedPoints()
                nextScanAt = gameTimer + Config.SCAN_INTERVAL
            end

            disableHorizonControls()
            drawHorizonVeil()

            local focusedPoint = updateHorizonFrame()

            if focusedPoint then
                if focusedPoint.nativeName then
                    drawBlipTitle(focusedPoint)
                end

                handleFocusedPointControls(focusedPoint)
            end

            Wait(0)
        end
    end)
end

function applyHorizonBlur()
    while blurWanted ~= blurApplied do
        while IsScreenblurFadeRunning() do
            Wait(0)
        end

        if blurWanted ~= blurApplied then
            blurApplied = blurWanted

            if blurApplied then
                TriggerScreenblurFadeIn(Config.BLUR_TIME + 0.0)
            else
                TriggerScreenblurFadeOut(Config.BLUR_TIME + 0.0)
            end

            Wait(0)
        end
    end
end

function setHorizonBlur(enabled)
    if not Config.BLUR then
        return
    end

    blurWanted = enabled

    if blurSyncRunning then
        return
    end

    blurSyncRunning = true

    CreateThread(function()
        applyHorizonBlur()

        blurSyncRunning = false
    end)
end

function clearHorizonBlur()
    if not blurWanted and not blurApplied then
        return
    end

    blurWanted = false
    blurApplied = false

    DisableScreenblurFade()
end

function startCloseGuard()
    CreateThread(function()
        local guardUntil = GetGameTimer() + CLOSE_GUARD_TIME

        while GetGameTimer() < guardUntil and not horizonActive do
            disableHorizonControls()
            Wait(0)
        end
    end)
end

function openHorizon()
    if horizonActive or not canOpenHorizon() then
        return false
    end

    horizonActive = true
    horizonToken = horizonToken + 1

    SendNUIMessage({
        action = 'open',
        data = {
            theme = Config.THEME_COLOR,
            blipImages = Config.USE_BLIP_IMAGES,
            controls = {
                setDestination = Config.CONTROLS.SET_DESTINATION.LABEL,
                viewOnMap = Config.CONTROLS.VIEW_ON_MAP.LABEL,
            },
        },
    })

    setHorizonBlur(true)

    Config.ON_OPEN()
    TriggerEvent(resourceName .. ':opened')
    startHorizonLoop(horizonToken)

    return true
end

function closeHorizon()
    if not horizonActive then
        return false
    end

    horizonActive = false
    horizonToken = horizonToken + 1
    trackedPoints = {}

    resetTitleSlot()
    SendNUIMessage({ action = 'close', data = {} })

    setHorizonBlur(false)

    Config.ON_CLOSE()
    TriggerEvent(resourceName .. ':closed')
    startCloseGuard()

    return true
end

function toggleHorizon()
    if horizonActive then
        return closeHorizon()
    end

    return openHorizon()
end

RegisterCommand('+' .. Config.COMMAND, function()
    if Config.HOLD_TO_VIEW then
        openHorizon()

        return
    end

    toggleHorizon()
end, false)

RegisterCommand('-' .. Config.COMMAND, function()
    if Config.HOLD_TO_VIEW then
        closeHorizon()
    end
end, false)

RegisterKeyMapping('+' .. Config.COMMAND, 'Marcadores no horizonte', 'keyboard', Config.KEY)

RegisterNetEvent(resourceName .. ':registerPoint', function(pointId, pointData)
    registerPoint(pointId, pointData)
end)

RegisterNetEvent(resourceName .. ':removePoint', function(pointId)
    removePoint(pointId)
end)

AddEventHandler('onClientResourceStop', function(stoppedResource)
    if stoppedResource ~= resourceName then
        removePointsByOwner(stoppedResource)

        return
    end

    if horizonActive then
        closeHorizon()
    end

    clearHorizonBlur()
end)

exports('registerPoint', registerPoint)
exports('removePoint', removePoint)
exports('setBlipDetails', setBlipDetails)
exports('clearBlipDetails', clearBlipDetails)
exports('openHorizon', openHorizon)
exports('closeHorizon', closeHorizon)
exports('isHorizonActive', isHorizonActive)

registerConfigPoints()
