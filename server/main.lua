CreateThread(Plb.Init)

RegisterNetEvent("plouffe_paletobank:sendConfig",function()
    local playerId = source
    local registred, key = Auth:Register(playerId)

    while not Server.ready do
        Wait(100)
    end

    if registred then
        local cbArray = Plb:GetData()
        cbArray.Utils.MyAuthKey = key
        TriggerClientEvent("plouffe_paletobank:getConfig", playerId, cbArray)
    else
        TriggerClientEvent("plouffe_paletobank:getConfig", playerId, nil)
    end
end)

RegisterNetEvent("plouffe_paletobank:removeItem", function(item, amount, authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) and Auth:Events(playerId,"plouffe_paletobank:removeItem") then
        exports.ox_inventory:RemoveItem(playerId, item, amount)
    end
end)

RegisterNetEvent("plouffe_paletobank:lockpickedDoor", function(doorIndex, success, authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) and Auth:Events(playerId,"plouffe_paletobank:lockpickedDoor") then
        Plb:PlayerUnlockedDoor(playerId,doorIndex,success)
    end
end)

RegisterNetEvent("plouffe_paletobank:hack_succes", function(success, zone, authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) and Auth:Events(playerId,"plouffe_paletobank:hack_succes") then
        Plb:PlayerHackFinished(playerId,success,zone)
    end
end)

RegisterNetEvent("plouffe_paletobank:requestLoots", function(netId, authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) and Auth:Events(playerId,"plouffe_paletobank:requestLoots") then
        Plb:RequestLoots(playerId,netId)
    end
end)