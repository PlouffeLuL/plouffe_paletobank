local Utils = exports.plouffe_lib:Get("Utils")
local Callback = exports.plouffe_lib:Get("Callback")
local Interface = exports.plouffe_lib:Get("Interface")
local Lang = exports.plouffe_lib:Get("Lang")
local Animation = {
    ComputerHack = {dict = "missheist_jewel@hacking"},
    Trolley = {dict = "anim@heists@ornate_bank@grab_cash", cash_appear = joaat("CASH_APPEAR"), cash_destroyed = joaat("RELEASE_CASH_DESTROY")}
}

local Wait = Wait
local GetEntityCoords = GetEntityCoords
local GetEntityRotation = GetEntityRotation
local PlayerPedId = PlayerPedId

local GetPedBoneIndex = GetPedBoneIndex
local DoesEntityExist = DoesEntityExist
local SetEntityCoords = SetEntityCoords
local AttachEntityToEntity = AttachEntityToEntity
local DeleteEntity = DeleteEntity
local GetClosestObjectOfType = GetClosestObjectOfType
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityNoCollisionEntity = SetEntityNoCollisionEntity
local SetEntityVisible = SetEntityVisible
local SetEntityRotation = SetEntityRotation
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local SetEntityAsNoLongerNeeded = SetEntityAsNoLongerNeeded
local RemoveAnimDict = RemoveAnimDict

local GetGameTimer = GetGameTimer
local DisableControlAction = DisableControlAction
local HasAnimEventFired = HasAnimEventFired
local IsEntityVisible = IsEntityVisible

local NetworkCreateSynchronisedScene = NetworkCreateSynchronisedScene
local NetworkAddPedToSynchronisedScene = NetworkAddPedToSynchronisedScene
local NetworkAddEntityToSynchronisedScene = NetworkAddEntityToSynchronisedScene
local NetworkStartSynchronisedScene = NetworkStartSynchronisedScene

local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity

function Plb:Start()
    self:ExportAllZones()
    self:RegisterEvents()

    if GetConvar("plouffe_paletobank:qtarget", "") == "true" then
        if GetResourceState("qtarget") ~= "missing" then
            local breakCount = 0
            while GetResourceState("qtarget") ~= "started" and breakCount < 30 do
                breakCount += 1
                Wait(1000)
            end

            if GetResourceState("qtarget") ~= "started" then
                return
            end

            local data = {}
            for k,v in pairs(self.Trolley) do
                table.insert(data, joaat(v.trolley))
            end

            exports.qtarget:AddTargetModel(data,{
                distance = 1.5,
                options = {
                    {
                        icon = 'fas fa-info',
                        label = Lang.bank_tryLoot,
                        action = Plb.TryLoot
                    },
                    {
                        icon = 'fas fa-viruses',
                        label = Lang.bank_tryDestroy,
                        action = Plb.DestroyLoot
                    }
                }
            })
        end
    end
end

function Plb:ExportAllZones()
    for k,v in pairs(self.Zones) do
        local registered, reason = exports.plouffe_lib:Register(v)
    end
end

function Plb:RegisterEvents()
    Utils:RegisterNetEvent("plouffe_paletobank:start_robbery", function()
        self:StartRobbery()
    end)

    AddEventHandler("plouffe_paletobank:onZone", function(params)
        if self[params.fnc] then
            self[params.fnc](self, params)
        end
    end)

    AddEventHandler("trolley:TryLoot", self.TryLoot)
    AddEventHandler("trolley:destroy", self.DestroyLoot)

    AddEventHandler("plouffe_paletobank:inZone", self.InZone)
    AddEventHandler("plouffe_paletobank:exitZone", self.ExitZone)
end

function Plb.InZone()
    Plb.isInZone = true
end

function Plb.ExitZone()
    Plb.isInZone = nil
end

function Plb:GetClosestDoor()
    for k,v in pairs(self.Doords) do
        if exports.plouffe_lib:IsInZone(("%s_1"):format(v)) then
            return v
        end
    end

    return false
end

function Plb:GetClosestTrolley(coords)
    local entity = nil

    for k,v in pairs(self.Trolley) do
        entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.5, v.trolley, false, false, false)
        if entity ~= 0 then
            return entity, v, k
        end
    end
end

function Plb.TryLockpick()
    for k,v in pairs(Plb.lockpick_items) do
        if Utils:GetItemCount(k) < v then
            return Interface.Notifications.Show({
                style = "error",
                header = "Paleto bank",
                message = Lang.missing_something
            })
        end
    end

    local door = Plb:GetClosestDoor()

    if not door then
        return
    end

    Utils:PlayAnim(nil, "mp_arresting", "a_uncuff" , 49, 3.0, 2.0, 5000, true, true, true)

    local succes = Interface.Lockpick.New({
        amount = 10,
        range = 35,
        maxKeys = 6
    })

    Utils:StopAnim()

    TriggerServerEvent("plouffe_paletobank:lockpickedDoor", door, succes, Plb.Utils.MyAuthKey)
end
exports("TryLockpick", Plb.TryLockpick)

function Plb:TryHack(parrams)
    for k,v in pairs(Plb.hack_items) do
        if Utils:GetItemCount(k) < v then
            return Interface.Notifications.Show({
                style = "error",
                header = "Paleto bank",
                message = Lang.missing_something
            })
        end
    end

    local canRob, reason = Callback:Sync("plouffe_paletobank:canRob", Plb.Utils.MyAuthKey)

    if not canRob then
        return Interface.Notifications.Show({
            style = "error",
            header = "Paleto bank",
            message = reason
        })
    end

    local Hack = Animation.ComputerHack:Start()

    local success = Interface.MovingSquare.New({
        time = 20,
        amount = 8,
        errors = 0,
        delay = 6
    })

    Hack:Exit()

    TriggerServerEvent("plouffe_paletobank:hack_succes", success, parrams.zone, Plb.Utils.MyAuthKey)
end

function Plb.TryLoot()
    if GlobalState.PaletoBankRobbery ~= "Started" then
        return
    end

    local Trolley = Animation.Trolley:Start()

    if not Trolley then
        return
    end

    while not Trolley.looted do
        Wait(0)
    end

    TriggerServerEvent("plouffe_paletobank:requestLoots", NetworkGetNetworkIdFromEntity(Trolley.trolleyEntity), Plb.Utils.MyAuthKey)

    local init = GetGameTimer()

    while DoesEntityExist(Trolley.trolleyEntity) and GetGameTimer() - init < 5000 do
        Wait(0)
    end

    Trolley:Exit()
end
exports("TryLoot", Plb.TryLoot)

function Plb.DestroyLoot()
    if GlobalState.PaletoBankRobbery ~= "Started" then
        return
    end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local trolleyEntity, data, key = Plb:GetClosestTrolley(pedCoords)

    if not trolleyEntity then
        return
    end

    TriggerServerEvent("plouffe_paletobank:TryDestroyLoots", NetworkGetNetworkIdFromEntity(trolleyEntity), Plb.Utils.MyAuthKey)
end
exports("TryDestroyLoot", Plb.DestroyLoot)

function Plb:StartRobbery()
    Interface.Notifications.Show({message = Lang.bank_timeUntilDoorOpens:format(math.ceil((self.doorDelay / 60) / 1000))})
    if GetResourceState("plouffe_dispatch") == "started" then
        exports.plouffe_dispatch:SendAlert("10-90 B")
    end
end

function Animation.Trolley:Prepare()
    Utils:AssureAnim(self.dict, true)

    local trolleyData

    self.looted = false

    self.ped = PlayerPedId()
    self.pedCoords = GetEntityCoords(self.ped)
    self.boneIndex = GetPedBoneIndex(self.ped, 60309)

    self.trolleyEntity, trolleyData = Plb:GetClosestTrolley(self.pedCoords)

    Utils:AssureEntityControl(self.trolleyEntity)

    if not self.trolleyEntity then
        return false
    end

    self.trolleyRotation = GetEntityRotation(self.trolleyEntity)
    self.trolleyCoords = GetEntityCoords(self.trolleyEntity)

    self.bagEntity =  Utils:CreateProp("hei_p_m_bag_var22_arm_s",  {x = self.pedCoords.x, y = self.pedCoords.y, z = self.pedCoords.z - 5.0}, nil, true, true)
    self.emptyTrolley = Utils:CreateProp(trolleyData.empty,{x = self.pedCoords.x, y = self.pedCoords.y, z = self.pedCoords.z - 8.0}, nil, true, true)
    self.lootEntity = Utils:CreateProp(trolleyData.prop,{x = self.pedCoords.x, y = self.pedCoords.y, z = self.pedCoords.z - 10.0}, nil, true, true)

    SetEntityRotation(self.emptyTrolley, self.trolleyRotation.x, self.trolleyRotation.y, self.trolleyRotation.z)
    FreezeEntityPosition(self.emptyTrolley, true)

    FreezeEntityPosition(self.lootEntity, true)

    SetEntityNoCollisionEntity(self.lootEntity, self.ped)
    SetEntityVisible(self.lootEntity, false, false)
    AttachEntityToEntity(self.lootEntity, self.ped, self.boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)

    return true
end

function Animation.Trolley:Start()
    if not self:Prepare() then
        return false
    end

    self.state = "Start"

    local scene = NetworkCreateSynchronisedScene(self.trolleyCoords.x, self.trolleyCoords.y, self.trolleyCoords.z, self.trolleyRotation.x, self.trolleyRotation.y, self.trolleyRotation.z, 2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(self.ped, scene, self.dict, "intro", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(self.bagEntity, scene, self.dict, "bag_intro", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(scene)

    CreateThread(function()
        self:Loop()
    end)

    return self
end

function Animation.Trolley:Loop()
    self.state = "Loop"

    CreateThread(function()
        local scene = NetworkCreateSynchronisedScene(self.trolleyCoords.x, self.trolleyCoords.y, self.trolleyCoords.z, self.trolleyRotation.x, self.trolleyRotation.y, self.trolleyRotation.z, 2, false, false, 1065353216, 0, 1.3)
        NetworkAddPedToSynchronisedScene(self.ped, scene, self.dict, "grab", 1.5, -4.0, 1, 16, 1148846080, 0)
        NetworkAddEntityToSynchronisedScene(self.bagEntity, scene, self.dict, "bag_grab", 4.0, -8.0, 1)
        NetworkAddEntityToSynchronisedScene(self.trolleyEntity, scene, self.dict, "cart_cash_dissapear", 4.0, -8.0, 1)
        NetworkStartSynchronisedScene(scene)
    end)

    self:LootsEvent()

    return self
end

function Animation.Trolley:LootsEvent()
    local init = GetGameTimer()
    local timeout = 37 * 1000

    while GetGameTimer() - init < timeout do
        Wait(0)

        DisableControlAction(0, 73, true)
        if HasAnimEventFired(self.ped, self.cash_appear) then
            if not IsEntityVisible(self.lootEntity) then
                SetEntityVisible(self.lootEntity, true, false)
            end
        end
        if HasAnimEventFired(self.ped, self.cash_destroyed) then
            if IsEntityVisible(self.lootEntity) then
                SetEntityVisible(self.lootEntity, false, false)
            end
        end
    end

    self.looted = true
    DeleteEntity(self.lootEntity)
end

function Animation.Trolley:Exit()
    self.state = "Exit"

    if not DoesEntityExist(self.trolleyEntity) then
        SetEntityCoords(self.emptyTrolley, self.trolleyCoords.x, self.trolleyCoords.y, self.trolleyCoords.z)
        PlaceObjectOnGroundProperly(self.emptyTrolley)
        SetEntityAsNoLongerNeeded(self.emptyTrolley)
    else
        DeleteEntity(self.emptyTrolley)
    end

    local scene = NetworkCreateSynchronisedScene(self.trolleyCoords.x, self.trolleyCoords.y, self.trolleyCoords.z, self.trolleyRotation.x, self.trolleyRotation.y, self.trolleyRotation.z, 2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(self.ped, scene, self.dict, "exit", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(self.bagEntity, scene, self.dict, "bag_exit", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(scene)

    Wait(1800)

    self:Finished()
end

function Animation.Trolley:Finished(restart)
    if restart then
        DeleteEntity(self.emptyTrolley)
    end

    RemoveAnimDict(self.dict)
    DeleteEntity(self.bagEntity)
    DeleteEntity(self.lootEntity)
    DeleteEntity(self.trolleyEntity)
end

function Animation.ComputerHack:Prepare()
    self.state = "Prepare"

    Utils:AssureAnim(self.dict, true)

    self.ped = PlayerPedId()
    self.pedCoords = GetEntityCoords(self.ped)
    self.pedRotation = GetEntityRotation(self.ped)

    self.offset = GetOffsetFromEntityInWorldCoords(self.ped, 0.0, 0.0, 0.0)

    return true
end

function Animation.ComputerHack:Start()
    if not self:Prepare() then
        return
    end

    self.state = "Start"

    local scene = NetworkCreateSynchronisedScene(self.offset.x, self.offset.y, self.offset.z, self.pedRotation.x, self.pedRotation.y, self.pedRotation.z, 2, true, false, 1.0, 0, 1.0)
    NetworkAddPedToSynchronisedScene(self.ped, scene, self.dict, "hack_intro", 1.5, -2.0, 3341, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)

    Wait(500)

    CreateThread(function()
        self:Loop()
    end)

    return self
end

function Animation.ComputerHack:Loop()
    self.state = "Loop"

    local scene = NetworkCreateSynchronisedScene(self.offset.x, self.offset.y, self.offset.z, self.pedRotation.x, self.pedRotation.y, self.pedRotation.z, 2, false, true, 1.0, 0, 1.0)
    NetworkAddPedToSynchronisedScene(self.ped, scene, self.dict, "hack_loop", 1.5, -2.0, 3341, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)

    CreateThread(function()
        local i = 0

        while self.state == "Loop" and i <= 950 do
            Wait(0)
            i = i + 1
        end

        if i >= 950 then
            self:Loop()
        end
    end)
end

function Animation.ComputerHack:Exit()
    self.state = "Exit"

    local scene = NetworkCreateSynchronisedScene(self.offset.x, self.offset.y, self.offset.z, self.pedRotation.x, self.pedRotation.y, self.pedRotation.z, 2, false, false, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(self.ped, scene, self.dict, "hack_outro", 1.5, -2.0, 1148846080, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)

    self:Finished()
end

function Animation.ComputerHack:Finished()
    self.state = "Finished"

    RemoveAnimDict(self.dict)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == "plouffe_paletobank" then
        Animation.Trolley:Finished(true)
    end
end)