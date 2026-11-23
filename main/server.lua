local resourceName = GetCurrentResourceName()

function setPlayerPoint(playerSource, pointId, pointData)
    if type(playerSource) ~= 'number' or type(pointData) ~= 'table' then
        return false
    end

    TriggerClientEvent(resourceName .. ':registerPoint', playerSource, pointId, pointData)

    return true
end

function removePlayerPoint(playerSource, pointId)
    if type(playerSource) ~= 'number' then
        return false
    end

    TriggerClientEvent(resourceName .. ':removePoint', playerSource, pointId)

    return true
end

exports('setPlayerPoint', setPlayerPoint)
exports('removePlayerPoint', removePlayerPoint)
