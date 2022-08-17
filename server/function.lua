local Auth = exports.plouffe_lib:Get("Auth")
local Utils = exports.plouffe_lib:Get("Utils")
local Callback = exports.plouffe_lib:Get("Callback")
local Lang = exports.plouffe_lib:Get("Lang")
local Inventory = exports.plouffe_lib:Get("Inventory")
local doorsList

if GetConvar("plouffe_paletobank:gabzmap", "") == "true" then
    doorsList = {
        paleto_bank_office_door = {
            lock = true,
            lockOnly = true,
            interactCoords = {
                {coords = vector3(-104.25981140137, 6474.3994140625, 31.64568901062), maxDst = 0.8}
            },
            doors = {
                {model = -368548260, coords = vec3(-104.705734, 6473.917969, 31.787983)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        },

        paleto_bank_minidoor = {
            lock = true,
            interactCoords = {
                {coords = vec3(-112.570831, 6468.007813, 31.214144), maxDst = 0.8}
            },
            doors = {
                {model = 1784650867, coords = vec3(-112.570831, 6468.007813, 31.214144)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        },

        paleto_bank_behind_desk = {
            lock = true,
            interactCoords = {
                {coords = vector3(-111.65210723877, 6474.9985351563, 31.644969940186), maxDst = 0.8}
            },
            doors = {
                {model = -56652918, coords = vec3(-111.042694, 6475.328125, 31.787979)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        },

        paleto_bank_side_entry = {
            lock = true,
            interactCoords = {
                {coords = vector3(-115.99950408936, 6479.6494140625, 31.645626068115), maxDst = 0.8}
            },
            doors = {
                {model = 1248599813, coords = vec3(-116.512688, 6478.959961, 31.787979)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        },

        paleto_bank_rear_entry = {
            lock = true,
            interactCoords = {
                {coords = vector3(-96.176170349121, 6473.4663085938, 31.645683288574), maxDst = 0.8}
            },
            doors = {
                {model = 1248599813, coords = vec3(-96.708656, 6474.056641, 31.787979)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        },

        paleto_bank_security = {
            lock = true,
            interactCoords = {
                {coords = vector3(-92.559844970703, 6468.388671875, 31.645536422729), maxDst = 0.8}
            },
            doors = {
                {model = -147325430, coords = vec3(-92.232231, 6468.960449, 31.787979)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        },

        paleto_bank_to_rear_entry = {
            lock = true,
            interactCoords = {
                {coords = vector3(-99.706268310547, 6473.9609375, 31.645639419556), maxDst = 0.8}
            },
            doors = {
                {model = -147325430, coords = vec3(-100.112297, 6474.392090, 31.787979)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        },

        paleto_bank_vault = {
            lock = true,
            lockOnly = true,
            interactCoords = {
                {coords = vec3(-100.241867, 6464.549316, 31.884604), maxDst = 1.5}
            },
            doors = {
                {model = -2050208642, coords = vec3(-100.241867, 6464.549316, 31.884604)}
            },
            access = {
                groups = {
                    police = {rankSpecific = 7}
                }
            }
        }
    }
else
    doorsList = {

    }
end

local hackingState = {
    office = false,
    security = false
}

local currentMoney = GetResourceKvpInt(("currentMoney")) or 0

function Plb.Init()
    Plb.ValidateConfig()

    Utils:CreateDepencie("plouffe_doorlock", Plb.ExportsAllDoors)

    Server.ready = true

    GlobalState.PaletoBankRobbery = "Ready"

    while true do
        local addition = math.random(Plb.minMoneyAddition, Plb.maxMoneyAddition)

        currentMoney = currentMoney + addition <= Plb.maxBankMoney and currentMoney + addition or Plb.maxBankMoney

        SetResourceKvpInt("currentMoney", currentMoney)

        Wait(Plb.addMoneyIntervall)
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

function Plb.ExportsAllDoors()
    for k,v in pairs(doorsList) do
        exports.plouffe_doorlock:RegisterDoor(k,v, false)
    end
end

function Plb.ValidateConfig()
    Plb.MoneyItem = GetConvar("plouffe_paletobank:money_item", "")
    Plb.MoneyMeta = GetConvar("plouffe_paletobank:use_money_metadata", "false")
    Plb.MinCops = tonumber(GetConvar("plouffe_paletobank:min_cops", ""))
    Plb.PoliceGroups = json.decode(GetConvar("plouffe_paletobank:police_groups", ""))
    Plb.robIntervall = tonumber(GetConvar("plouffe_paletobank:rob_interval", ""))
    Plb.addMoneyIntervall = tonumber(GetConvar("plouffe_paletobank:add_money_interval", ""))
    Plb.minMoneyAddition = tonumber(GetConvar("plouffe_paletobank:min_money_addition", ""))
    Plb.maxMoneyAddition = tonumber(GetConvar("plouffe_paletobank:max_money_addition", ""))
    Plb.hackingDelay = tonumber(GetConvar("plouffe_paletobank:time_to_hack", ""))
    Plb.doorDelay = tonumber(GetConvar("plouffe_paletobank:time_until_door_opens", ""))
    Plb.maxBankMoney = tonumber(GetConvar("plouffe_paletobank:max_bank_money", ""))

    local data = json.decode(GetConvar("plouffe_paletobank:hack_item", ""))
    if data and type(data) == "table" then
        Plb.hack_items = {}

        for k,v in pairs(data) do
            local one, two = v:find(":")
            Plb.hack_items[v:sub(0,one - 1)] = tonumber(v:sub(one + 1,v:len()))
        end
        data = nil
    end

    data = json.decode(GetConvar("plouffe_paletobank:lockpick_item", ""))
    if data and type(data) == "table" then
        Plb.lockpick_items = {}

        for k,v in pairs(data) do
            local one, two = v:find(":")
            Plb.lockpick_items[v:sub(0,one - 1)] = tonumber(v:sub(one + 1,v:len()))
        end
    end

    if not Plb.hack_items or type(Plb.hack_items) ~= "table" then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'hack_item' convar. Refer to documentation")
        end
    elseif not Plb.lockpick_items or type(Plb.lockpick_items) ~= "table" then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'lockpick_item' convar. Refer to documentation")
        end
    elseif not Plb.MoneyItem or type(Plb.MoneyItem) ~= "string" or Plb.MoneyItem:len() < 1 then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'money_item' convar. Refer to documentation")
        end
    elseif not Plb.PoliceGroups or type(Plb.PoliceGroups) ~= "table" then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'police_groups' convar. Refer to documentation")
        end
    elseif not Plb.MinCops then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'min_cops' convar. Refer to documentation")
        end
    elseif not Plb.PoliceGroups then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'police_groups' convar. Refer to documentation")
        end
    elseif not Plb.robIntervall then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'robIntervall' convar. Refer to documentation")
        end
    elseif not Plb.addMoneyIntervall then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'add_money_interval' convar. Refer to documentation")
        end
    elseif not Plb.minMoneyAddition then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'min_money_addition' convar. Refer to documentation")
        end
    elseif not Plb.maxMoneyAddition then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'max_money_addition' convar. Refer to documentation")
        end
    elseif not Plb.maxBankMoney then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'max_bank_money' convar. Refer to documentation")
        end
    elseif not Plb.hackingDelay then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'time_to_hack' convar. Refer to documentation")
        end
    elseif not Plb.doorDelay then
        while true do
            Wait(1000)
            print("^1 [ERROR] ^0 Invalid configuration, missing 'time_until_door_opens' convar. Refer to documentation")
        end
    end

    Plb.hackingDelay = 1000 * Plb.hackingDelay
    Plb.doorDelay = 1000 * 60 * Plb.doorDelay

    Plb.robIntervall = Plb.robIntervall * (60 * 1000 * 60)
    Plb.addMoneyIntervall = Plb.addMoneyIntervall * (1000 * 60)

    return true
end

function Plb.LoadPlayer()
    local playerId = source
    local registred, key = Auth:Register(playerId)

    while not Server.ready do
        Wait(100)
    end

    if not registred then
        return TriggerClientEvent("plouffe_paletobank:getConfig", playerId, nil)
    end

    local data = Plb:GetData()
    data.Utils.MyAuthKey = key
    TriggerClientEvent("plouffe_paletobank:getConfig", playerId, data)
end

function Plb.RemoveItem(item, amount, authkey)
    local playerId = source
    if Auth:Validate(playerId,authkey) and Auth:Events(playerId,"plouffe_paletobank:removeItem") then
        Inventory.RemoveItem(playerId, item, amount)
    end
end

function Plb.PlayerUnlockedDoor(doorIndex, succes, authkey)
    local playerId = source

    if not Auth:Validate(playerId,authkey) or not Auth:Events(playerId,"plouffe_paletobank:lockpickedDoor") then
        return
    end

    for k,v in pairs(Plb.lockpick_items) do
        Inventory.ReduceDurability(playerId, k, 60 * 60 * 24)
    end

    if not succes then
        return
    end

    exports.plouffe_doorlock:UpdateDoorState(doorIndex, false)
end

function Plb.PlayerHackFinished(succes, zone, authkey)
    local playerId = source

    if not Auth:Validate(playerId,authkey) or not Auth:Events(playerId,"plouffe_paletobank:hack_succes") then
        return
    end

    if GlobalState.PaletoBankRobbery ~= "Ready" or not Plb:CanRob() then
        return
    end

    local ped = GetPlayerPed(playerId)
    local pedCoords = GetEntityCoords(ped)
    local coords = Plb.Zones[("paleto_bank_hack_%s"):format(zone)].coords
    local dstCheck = #(coords - pedCoords)

    if dstCheck > 1.0 then
        return
    end

    for k,v in pairs(Plb.hack_items) do
        if Utils:GetItemCount(k) < v then
            Utils:ReduceDurability(playerId, k, 60 * 60 * 24)
        end
    end

    if not succes then
        return
    end

    Plb:WaitForNextHack(playerId,zone)
end

function Plb:WaitForNextHack(playerId,zone)
    hackingState[zone] = true

    if self.waitingForNextHack then
        return
    end

    self.waitingForNextHack = true

    CreateThread(function()
        Wait(self.hackingDelay)

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

    Utils:Notify(playerId, Lang.paletobank_finishedHacking:format(self.doorDelay))

    CreateThread(function()
        Wait(self.doorDelay)
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

function Plb.RequestLoots(netId, authkey)
    local playerId = source

    if not Auth:Validate(playerId,authkey) or not Auth:Events(playerId,"plouffe_paletobank:requestLoots") then
        return
    end

    if GlobalState.PaletoBankRobbery ~= "Started" then
        return
    end

    for k,v in pairs(Plb.TrolleySpawns) do
        if netId == v.netId then
            local canCarry = (Plb.MoneyMeta == "false" and Inventory.CanCarryItem(playerId, Plb.MoneyItem, v.value)) or (Plb.MoneyMeta == "true" and Inventory.CanCarryItem(playerId, Plb.MoneyItem, 1, {weight = math.ceil(0.1 * v.value), description = Lang.bank_moneyItemMeta:format(v.value), value = v.value}))

            if canCarry then
                local entity = NetworkGetEntityFromNetworkId(v.netId)
                DeleteEntity(entity)
                v.netId = nil

                currentMoney = currentMoney - v.value
                SetResourceKvpInt("currentMoney", currentMoney)

                if Plb.MoneyMeta == "true" then
                    Inventory.AddItem(playerId, Plb.MoneyItem, 1, {weight = math.ceil(0.1 * v.value), description = Lang.bank_moneyItemMeta:format(v.value), value = v.value})
                else
                    Inventory.AddItem(playerId, Plb.MoneyItem, v.value)
                end

                break
            else
                TriggerClientEvent("plouffe_lib:notify", playerId, {type = "inform", txt = Lang.bank_cantCarryMoney, length = 5000})
                break
            end
        end
    end

    if not Plb:IsAnyLootsLeft() then
        GlobalState.PaletoBankRobbery = "Finished"
    end
end

function Plb.DestroyLoots(netId, authkey)
    local playerId = source

    if not Auth:Validate(playerId,authkey) or not Auth:Events(playerId,"plouffe_paletobank:destroyLoots") then
        return
    end

    for k,v in pairs(Plb.TrolleySpawns) do
        if netId == v.netId then
            local entity = NetworkGetEntityFromNetworkId(v.netId)
            DeleteEntity(entity)
            v.netId = nil
        end
    end

    if not self:IsAnyLootsLeft() then
        GlobalState.PaletoBankRobbery = "Finished"
    end
end

function Plb:CanRob()
    if GlobalState.PaletoBankRobbery ~= "Ready" then
        return false, Lang.bank_robbedLately
    end

    for k,v in pairs(Plb.PoliceGroups) do
        local cops = Groups:GetGroupPlayers(v)

        if cops.len < Plb.MinCops then
            return false, Lang.bank_notEnoughCop
        end
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