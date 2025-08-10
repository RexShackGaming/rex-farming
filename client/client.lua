local RSGCore = exports['rsg-core']:GetCoreObject()
local isBusy = false
local SpawnedPlants = {}
local HarvestedPlants = {}
local canHarvest = true
local Zones = {}
local inFarmZone = false
local inplantmenu = false
lib.locale()

---------------------------------------------
-- farm field blips
---------------------------------------------
CreateThread(function()
    for _,v in pairs(Config.FarmingZone) do
        if v.showblip then
            local FarmFieldBlip = BlipAddForCoords(1664425300, v.fieldcoords)
            SetBlipSprite(FarmFieldBlip, joaat('blip_event_riggs_camp'), true)
            SetBlipScale(FarmFieldBlip, 0.2)
            SetBlipName(FarmFieldBlip, locale('cl_lang_1'))
        end
    end
end)

---------------------------------------------
-- can plant here function
---------------------------------------------
local function CanPlantSeedHere(propcoords)
    local canPlant = true

    if Config.RestrictTownPlanting then
        local ZoneTypeId = 1
        local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
        local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, ZoneTypeId)
        if town ~= false then
            canPlant = false
        end
    end

    for i = 1, #Config.FarmPlants do
        if GetDistanceBetweenCoords(propcoords.x, propcoords.y, propcoords.z, Config.FarmPlants[i].x, Config.FarmPlants[i].y, Config.FarmPlants[i].z, true) < 1.3 then
            canPlant = false
        end
    end
    return canPlant
end

---------------------------------------------
-- check if player is in farming zone
---------------------------------------------
CreateThread(function()
    for k=1, #Config.FarmingZone do
        Zones[k] = PolyZone:Create(Config.FarmingZone[k].zones, {
            name = Config.FarmingZone[k].name,
            minZ = Config.FarmingZone[k].minz,
            maxZ = Config.FarmingZone[k].maxz,
            debugPoly = false,
        })
        Zones[k]:onPlayerInOut(function(isPointInside)
            if not isPointInside then
                inFarmZone = false
                return
            end
            inFarmZone = true
        end)
    end
end)

---------------------------------------------
-- spawn plants and setup target
---------------------------------------------
CreateThread(function()
    while true do
        Wait(150)

        local pos = GetEntityCoords(cache.ped)
        local InRange = false

        for i = 1, #Config.FarmPlants do
            local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.FarmPlants[i].x, Config.FarmPlants[i].y, Config.FarmPlants[i].z, true)

            if dist >= 50.0 then goto continue end

            local hasSpawned = false
            InRange = true

            for z = 1, #SpawnedPlants do
                local p = SpawnedPlants[z]

                if p.id == Config.FarmPlants[i].id then
                    hasSpawned = true
                end

                if SpawnedPlants[z].stage ~= Config.FarmPlants[i].stage then
                    hasSpawned = false
                end

            end

            if hasSpawned then goto continue end
            
            if Config.FarmPlants[i].stage == 1 then
                stageplanthash = Config.FarmPlants[i].hash1
            end
            
            if Config.FarmPlants[i].stage == 2 then
                stageplanthash = Config.FarmPlants[i].hash2
            end
            
            if Config.FarmPlants[i].stage == 3 then
                stageplanthash = Config.FarmPlants[i].hash3
            end

            local planthash = stageplanthash
            local phash = GetHashKey(planthash)
            local data = {}

            while not HasModelLoaded(phash) do
                Wait(10)
                RequestModel(phash)
            end

            RequestModel(phash)
            data.id = Config.FarmPlants[i].id
            data.stage = Config.FarmPlants[i].stage
            data.obj = CreateObject(phash, Config.FarmPlants[i].x, Config.FarmPlants[i].y, Config.FarmPlants[i].z, false, false, false)
            SetEntityHeading(data.obj, Config.FarmPlants[i].h)
            SetEntityAsMissionEntity(data.obj, true)
            PlaceObjectOnGroundProperly(data.obj)
            Wait(1000)
            FreezeEntityPosition(data.obj, true)
            SetModelAsNoLongerNeeded(data.obj)
            SpawnedPlants[#SpawnedPlants + 1] = data
            hasSpawned = false

            -- create target for the entity
            exports.ox_target:addLocalEntity(data.obj, {
                {
                    name = 'farmplants',
                    icon = 'fa-solid fa-seedling',
                    label = 'Farmer Menu',
                    onSelect = function()
                        TriggerEvent('rex-farming:client:plantmenu', data.id)
                    end,
                    distance = 3.0
                }
            })

            ::continue::

        end

        if not InRange then
            Wait(5000)
        end
    end
end)

---------------------------------------------
-- drawtext for plant info
---------------------------------------------
local DrawTxt = function(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
    local string = CreateVarString(10, "LITERAL_STRING", str)

    SetTextScale(w, h)
    SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
    SetTextCentre(centre)

    if enableShadow then
        SetTextDropshadow(1, 0, 0, 0, 255)
    end

    DisplayText(string, x, y)
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local t = 1000
        for i = 1, #Config.FarmPlants do
            local plant = Config.FarmPlants[i]
            local plantcoords = vec3(plant.x, plant.y, plant.z)
            local distance = #(playerCoords - plantcoords)
            if distance < 1.0 and not inplantmenu then
                t = 4
                DrawTxt(RSGCore.Shared.Items[plant.planttype].label..locale('cl_lang_2'), 0.50, 0.85, 0.4, 0.4, true, 249, 250, 195, 200, true)
                if IsControlJustPressed(2, RSGCore.Shared.Keybinds['J']) then
                    TriggerEvent('rex-farming:client:plantmenu', plant.id)
                end
            end
        end
        Wait(t)
    end
end)

---------------------------------------------
-- plant menu
---------------------------------------------
RegisterNetEvent('rex-farming:client:plantmenu', function(id)

    RSGCore.Functions.TriggerCallback('rex-farming:server:getplantdata', function(result)
        
        local plantdata = json.decode(result[1].properties)
        local PlayerData = RSGCore.Functions.GetPlayerData()
        local playerJobType = PlayerData.job.type

        -- thirst colorScheme
        if plantdata.thirst > Config.StartDegrade then thirstColorScheme = 'green' end
        if plantdata.thirst <= Config.StartDegrade and plantdata.thirst > 10 then thirstColorScheme = 'yellow' end
        if plantdata.thirst <= 10 then thirstColorScheme = 'red' end
        if plantdata.thirst < 0 then plantdata.thirst = 0 end
        if plantdata.thirst > 100 then plantdata.thirst = 100 end

        -- hunger colorScheme
        if plantdata.hunger > Config.StartDegrade then hungerColorScheme = 'green' end
        if plantdata.hunger <= Config.StartDegrade and plantdata.hunger > 10 then thirstColorScheme = 'yellow' end
        if plantdata.hunger <= 10 then hungerColorScheme = 'red' end
        if plantdata.hunger < 0 then plantdata.hunger = 0 end
        if plantdata.hunger > 100 then plantdata.hunger = 100 end

        -- quality colorScheme
        if plantdata.quality > 50 then qualityColorScheme = 'green' end
        if plantdata.quality <= 50 and plantdata.quality > 10 then qualityColorScheme = 'yellow' end
        if plantdata.quality <= 10 then qualityColorScheme = 'red' end
        if plantdata.quality < 0 then plantdata.quality = 0 end
        if plantdata.quality > 100 then plantdata.quality = 100 end

        inplantmenu = true

        if playerJobType == 'leo' and plantdata.planttype == 'weed' then
            lib.registerContext({
                id = 'plant_menu',
                title = RSGCore.Shared.Items[plantdata.planttype].label..locale('cl_lang_3'),
                onExit = function()
                    inplantmenu = false
                end,
                options = {
                    {
                        title = 'Destroy Plant',
                        icon = 'fa-solid fa-fire',
                        iconColor = 'orange',
                        serverEvent = 'rex-farming:server:destroyplant',
                        args = { plantid = plantdata.id },
                        arrow = true
                    },
                }
            })
            lib.showContext('plant_menu')
        else
            lib.registerContext({
                id = 'plant_menu',
                title = RSGCore.Shared.Items[plantdata.planttype].label..locale('cl_lang_3'),
                onExit = function()
                    inplantmenu = false
                end,
                options = {
                    {
                        title = locale('cl_lang_4')..plantdata.growth,
                        progress = plantdata.growth,
                        colorScheme = 'green',
                        icon = 'fa-solid fa-hashtag',
                    },
                    {
                        title = locale('cl_lang_5')..plantdata.quality,
                        progress = plantdata.quality,
                        colorScheme = qualityColorScheme,
                        icon = 'fa-solid fa-hashtag',
                    },
                    {
                        title = locale('cl_lang_6')..plantdata.thirst,
                        progress = plantdata.thirst,
                        colorScheme = thirstColorScheme,
                        icon = 'fa-solid fa-hashtag',
                    },
                    {
                        title = locale('cl_lang_20')..plantdata.hunger,
                        progress = plantdata.hunger,
                        colorScheme = hungerColorScheme,
                        icon = 'fa-solid fa-hashtag',
                    },
                    {
                        title = locale('cl_lang_7'),
                        icon = 'fa-solid fa-droplet',
                        iconColor = '#74C0FC',
                        event = 'rex-farming:client:waterplant',
                        args = { plantid = plantdata.id },
                        arrow = true
                    },
                    {
                        title = locale('cl_lang_21'),
                        icon = 'fa-solid fa-poop',
                        iconColor = '#BA8C22',
                        event = 'rex-farming:client:feedplant',
                        args = { plantid = plantdata.id },
                        arrow = true
                    },
                    {
                        title = locale('cl_lang_8'),
                        icon = 'fa-solid fa-seedling',
                        iconColor = 'green',
                        event = 'rex-farming:client:harvestplant',
                        args = { plantid = plantdata.id, growth = plantdata.growth },
                        arrow = true
                    },
                }
            })
            lib.showContext('plant_menu')
        end
    end, id)

end)

---------------------------------------------
-- water plant
---------------------------------------------
RegisterNetEvent('rex-farming:client:waterplant', function(data)

    local hasItem1 = RSGCore.Functions.HasItem('waterbucket5', 1)
    local hasItem2 = RSGCore.Functions.HasItem('waterbucket4', 1)
    local hasItem3 = RSGCore.Functions.HasItem('waterbucket3', 1)
    local hasItem4 = RSGCore.Functions.HasItem('waterbucket2', 1)
    local hasItem5 = RSGCore.Functions.HasItem('waterbucket1', 1)

    if hasItem1 or hasItem2 or hasItem3 or hasItem4 or hasItem5 and not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        FreezeEntityPosition(cache.ped, true)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_BUCKET_POUR_LOW`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-farming:server:waterPlant', data.plantid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
    else
        lib.notify({ title = locale('cl_lang_9'), type = 'error', duration = 7000 })
    end

    inplantmenu = false

end)

---------------------------------------------
-- feed plant
---------------------------------------------
RegisterNetEvent('rex-farming:client:feedplant', function(data)

    local hasItem = RSGCore.Functions.HasItem('fertilizer', 1)

    if hasItem and not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        FreezeEntityPosition(cache.ped, true)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_FEED_PIGS`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-farming:server:feedPlant', data.plantid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
    else
        lib.notify({ title = locale('cl_lang_22'), type = 'error', duration = 7000 })
    end

    inplantmenu = false

end)

---------------------------------------------
-- havest plants
---------------------------------------------
RegisterNetEvent('rex-farming:client:harvestplant', function(data)

    if data.growth < 100 then
        lib.notify({ title = locale('cl_lang_10'), type = 'error', duration = 7000 })
        inplantmenu = false
        return
    end

    if not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        table.insert(HarvestedPlants, data.plantid)
        TriggerServerEvent('rex-farming:server:plantHasBeenHarvested', data.plantid)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('rex-farming:server:harvestPlant', data.plantid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
        canHarvest = true
    end

    inplantmenu = false

end)

---------------------------------------------
-- destroy plant
---------------------------------------------
RegisterNetEvent('rex-farming:client:destroyplant', function(data)
    if not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        print('destroying this plant')
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
    end
    inplantmenu = false
end)

---------------------------------------------
-- update plant data
---------------------------------------------
RegisterNetEvent('rex-farming:client:updatePlantData')
AddEventHandler('rex-farming:client:updatePlantData', function(data)
    Config.FarmPlants = data
end)

---------------------------------------------
-- plant seeds
---------------------------------------------
RegisterNetEvent('rex-farming:client:plantnewseed')
AddEventHandler('rex-farming:client:plantnewseed', function(outputitem, inputitem, prophash1, prophash2, prophash3, propcoords, propheading)

    local PlayerData = RSGCore.Functions.GetPlayerData()
    local playerJobType = PlayerData.job.type

    if playerJobType == 'leo' and outputitem == 'weed' then
        lib.notify({ title = 'Law not able to plant this!', type = 'error', duration = 7000 })
        return
    end

    if not inFarmZone and not Config.GrowAnywhere then
        lib.notify({ title = locale('cl_lang_11'), type = 'error', duration = 7000 })
        return 
    end

    if not CanPlantSeedHere(propcoords) then
        lib.notify({ title = locale('cl_lang_12'), type = 'error', duration = 7000 })
        return 
    end

    if isBusy then
        lib.notify({ title = locale('cl_lang_13'), type = 'error', duration = 7000 })
        return
    end

    isBusy = true
    LocalPlayer.state:set("inv_busy", true, true)
    FreezeEntityPosition(cache.ped, true)
    TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
    Wait(10000)
    ClearPedTasks(cache.ped)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(cache.ped, false)
    TriggerServerEvent('rex-farming:server:plantnewseed', outputitem, inputitem, prophash1, prophash2, prophash3, propcoords, propheading)
    LocalPlayer.state:set("inv_busy", false, true)
    isBusy = false

end)

---------------------------------------------
-- remove plant object
---------------------------------------------
RegisterNetEvent('rex-farming:client:removePlantObject')
AddEventHandler('rex-farming:client:removePlantObject', function(plant)
    for i = 1, #SpawnedPlants do
        local o = SpawnedPlants[i]

        if o.id == plant then
            SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)
        end
    end
end)

---------------------------------------------
-- cleanup
---------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #SpawnedPlants do
        local plants = SpawnedPlants[i].obj
        SetEntityAsMissionEntity(plants, false)
        FreezeEntityPosition(plants, false)
        DeleteObject(plants)
    end
end)
