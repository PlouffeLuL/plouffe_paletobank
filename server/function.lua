local hackingState = {
    office = false,
    security = false
}
local maxMoney = 500000
local currentMoney = GetResourceKvpInt(("currentMoney")) or 0

function Plb.Init()
    Server.ready = true
    GlobalState.PaletoBankRobbery = "Starting"

    Wait(Plb.Utils.readyDelay)

    GlobalState.PaletoBankRobbery = "Ready"
    local sleepTimer = 1000 * 60 * 15

    while true do
        local addition = math.random(3000, 6000)

        currentMoney = currentMoney + addition <= maxMoney and currentMoney + addition or maxMoney

        SetResourceKvpInt("currentMoney", currentMoney)

        Wait(sleepTimer)
    end
end

function Plb:GetData()
    local retval = {}

    for k,v in pairs(self) do
        if type(v) ~= "function" then
            retval[k] = v
        end
    end

    return retval
end

function Plb:PlayerUnlockedDoor(playerId, doorIndex, succes)
    if not succes then
        return Utils:ReduceDurability(playerId, "advancedlockpick", 60 * 60 * 24)
    end

    if not Utils:ReduceDurability(playerId, "advancedlockpick", 60 * 60 * 6) then
        return
    end

    exports.plouffe_doorlock:UpdateDoorState(doorIndex, false)
end

function Plb:PlayerHackFinished(playerId, succes, zone)
    if GlobalState.PaletoBankRobbery ~= "Ready" or not self:CanRob() then
        return
    end

    local ped = GetPlayerPed(playerId)
    local pedCoords = GetEntityCoords(ped)
    local coords = self.Zones[("paleto_bank_hack_%s"):format(zone)].coords
    local dstCheck = #(coords - pedCoords)
    
    if dstCheck > 1.0 then
        return
    end

    if not succes then
        return Utils:ReduceDurability(playerId, "laptop", 60 * 60 * 24)
    end

    if not Utils:ReduceDurability(playerId, "laptop", 60 * 60 * 24) or not Utils:ReduceDurability(playerId, "usb_red", 60 * 60 * 72) then
        return
    end

    self:WaitForNextHack(playerId,zone)
end

function Plb:WaitForNextHack(playerId,zone)
    hackingState[zone] = true

    if self.waitingForNextHack then
        return
    end

    self.waitingForNextHack = true

    CreateThread(function()
        Wait(self.Utils.hackingDelay)

        for k,v in pairs(hackingState) do
            if not v then
                return self:ResetHackingState()
            end
        end

        self.waitingForNextHack = false

        self:StartRobbery(playerId)
    end)
end

function Plb:ResetHackingState()
    if GlobalState.PaletoBankRobbery ~= "Ready" then
        GlobalState.PaletoBankRobbery = "Ready"
    end

    for k,v in pairs(hackingState) do
        v = false
    end
end

function Plb:StartRobbery(playerId)
    GlobalState.PaletoBankRobbery = "Started"

    TriggerClientEvent("plouffe_paletobank:start_robbery",playerId)

    Utils:Notify(playerId, "Hacking reussi, veuillez attendre")

    CreateThread(function()
        Wait(self.Utils.doorDelay)
        self:CreateTrolley()
        exports.plouffe_doorlock:UpdateDoorState("paleto_bank_vault", false)
    end)
end

function Plb:CreateTrolley()
    local model = ""
    
    if currentMoney >= 400000 then
        model = "diamond"    
    elseif currentMoney >= 300000 then
        model = "gold"
    else
        model = "cash"
    end

    model = joaat(self.Trolley[model].trolley)

    local value = math.ceil(currentMoney / 4)

    for k,v in pairs(self.TrolleySpawns) do
        local entity = CreateObject(model, v.coords.x, v.coords.y, v.coords.z, true, true, false)
        local init = os.time()

        while not DoesEntityExist(entity) and os.time() - init < 2 do
            Wait(0)
        end

        if DoesEntityExist(entity) then
            local netId = NetworkGetNetworkIdFromEntity(entity) 
            
            SetEntityRotation(entity, v.rotation.x, v.rotation.y, v.rotation.z, 2, true)

            v.value = value
            v.netId = netId
            v.model = model
        end
    end
end

function Plb:DeleteAllTrolley()
    for k,v in pairs(self.TrolleySpawns) do
        local entity = NetworkGetEntityFromNetworkId(v.netId)
        DeleteEntity(entity)
        v.netId = nil
    end
end

function Plb:IsAnyLootsLeft()
    for k,v in pairs(self.TrolleySpawns) do
        if v.netId then
            return true
        end
    end

    return false
end

function Plb:RequestLoots(playerId,netId)
    if GlobalState.PaletoBankRobbery ~= "Started" then
        return
    end

    for k,v in pairs(self.TrolleySpawns) do
        if netId == v.netId then
            if exports.ox_inventory:CanCarryItem(playerId, "money_bag", 1, {weight = math.ceil(0.1 * v.value), description = ("Contiens pour %s $ de billets marquer"):format(v.value), value = v.value}) then
                local entity = NetworkGetEntityFromNetworkId(v.netId)

                DeleteEntity(entity)
                v.netId = nil

                currentMoney = currentMoney - v.value
                SetResourceKvpInt("currentMoney", currentMoney)

                exports.ox_inventory:AddItem(playerId, "money_bag", 1, {weight = math.ceil(0.1 * v.value), description = ("Contiens pour %s $ de billets marquer"):format(v.value), value = v.value})
                break
            else
                TriggerClientEvent("plouffe_lib:notify", playerId, {type = "inform", txt = ("Vous ne pouvez pas porter ce sac d'argent"), length = 5000})
                break
            end
        end
    end

    if not self:IsAnyLootsLeft() then
        GlobalState.PaletoBankRobbery = "Finished"
    end
end

function Plb:CanRob()
    if GlobalState.PaletoBankRobbery ~= "Ready" then
        return false
    end

    local cops = exports.plouffe_society:GetPlayersPerJob("police")

    if not cops or Utils:TableLen(cops) < 5 then
        return false, ("Il n'y a pas asser de policier en service présentement")
    end

    return true
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == "plouffe_paletobank" then
        Plb:DeleteAllTrolley()
    end
end)

Callback:RegisterServerCallback("plouffe_paletobank:canRob", function(source, cb, authkey)
    local _source = source
    if Auth:Validate(_source,authkey) and Auth:Events(_source,"plouffe_paletobank:canRob") then
        cb(Plb:CanRob())
    end
end)