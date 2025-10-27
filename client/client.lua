local RSGCore = exports['rsg-core']:GetCoreObject()
local isBusy = false
local SpawnedPlants = {}
local HarvestedPlants = {}
local canHarvest = true
local Zones = {}
local inFarmZone = false
local inplantmenu = false
local plantStatsCache = {} -- Cache for plant stats to prevent flickering
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
-- Cache spawned plants by ID for faster lookups
local SpawnedPlantsById = {}

-- Helper function to get stage hash
local function GetPlantStageHash(plant)
    if plant.stage == 1 then return plant.hash1
    elseif plant.stage == 2 then return plant.hash2
    elseif plant.stage == 3 then return plant.hash3
    end
    return plant.hash1
end

CreateThread(function()
    while true do
        Wait(500) -- Reduced frequency for better performance

        local pos = GetEntityCoords(cache.ped)
        local InRange = false

        for i = 1, #Config.FarmPlants do
            local plant = Config.FarmPlants[i]
            local dist = #(pos - vector3(plant.x, plant.y, plant.z)) -- Optimized distance calc

            if dist < 50.0 then
                InRange = true
                
                -- Check if already spawned with correct stage
                local spawned = SpawnedPlantsById[plant.id]
                if spawned and spawned.stage == plant.stage then
                    goto continue
                end
                
                -- Remove old version if stage changed
                if spawned and spawned.stage ~= plant.stage then
                    if DoesEntityExist(spawned.obj) then
                        DeleteObject(spawned.obj)
                    end
                    SpawnedPlantsById[plant.id] = nil
                    for j = #SpawnedPlants, 1, -1 do
                        if SpawnedPlants[j].id == plant.id then
                            table.remove(SpawnedPlants, j)
                            break
                        end
                    end
                end

                -- Spawn plant
                local planthash = GetPlantStageHash(plant)
                local phash = joaat(planthash)
                
                if not lib.requestModel(phash, 5000) then
                    goto continue
                end
                
                local data = {
                    id = plant.id,
                    stage = plant.stage,
                    obj = CreateObject(phash, plant.x, plant.y, plant.z, false, false, false)
                }
                
                SetEntityHeading(data.obj, plant.h)
                SetEntityAsMissionEntity(data.obj, true)
                PlaceObjectOnGroundProperly(data.obj)
                FreezeEntityPosition(data.obj, true)
                SetModelAsNoLongerNeeded(phash)
                
                SpawnedPlants[#SpawnedPlants + 1] = data
                SpawnedPlantsById[plant.id] = data

                -- Create target for the entity
                exports.ox_target:addLocalEntity(data.obj, {
                    {
                        name = 'farmplants',
                        icon = 'fa-solid fa-seedling',
                        label = locale('cl_lang_23'),
                        onSelect = function()
                            TriggerEvent('rex-farming:client:plantmenu', data.id)
                        end,
                        distance = 3.0,
                        canInteract = function(entity)
                            return not inplantmenu
                        end
                    }
                })
            end

            ::continue::
        end

        if not InRange then
            Wait(2000) -- Longer wait when not near plants
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

-- Thread to update plant stats cache
CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        
        -- Update cache for nearby plants
        for i = 1, #Config.FarmPlants do
            local plant = Config.FarmPlants[i]
            local distance = #(playerCoords - vector3(plant.x, plant.y, plant.z))
            
            if distance < 2.0 then
                RSGCore.Functions.TriggerCallback('rex-farming:server:getplantdata', function(result)
                    if result and result[1] then
                        local plantdata = json.decode(result[1].properties)
                        plantStatsCache[plant.id] = {
                            growth = math.floor(plantdata.growth),
                            thirst = math.floor(plantdata.thirst),
                            hunger = math.floor(plantdata.hunger)
                        }
                    end
                end, plant.id)
            end
        end
        
        Wait(1000) -- Update cache every second
    end
end)

-- Optimized plant interaction check
CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local nearestPlant = nil
        local nearestDist = 1.0
        
        -- Find nearest plant within range
        for i = 1, #Config.FarmPlants do
            local plant = Config.FarmPlants[i]
            local distance = #(playerCoords - vector3(plant.x, plant.y, plant.z))
            
            if distance < nearestDist then
                nearestPlant = plant
                nearestDist = distance
            end
        end
        
        -- Show interaction only for nearest plant
        if nearestPlant and not inplantmenu then
            -- Plant title
            local plantLabel = RSGCore.Shared.Items[nearestPlant.planttype].label
            DrawTxt(plantLabel..locale('cl_lang_2'), 0.50, 0.80, 0.45, 0.45, true, 249, 250, 195, 255, true)
            
            -- Add stats if cached
            if plantStatsCache[nearestPlant.id] then
                local stats = plantStatsCache[nearestPlant.id]
                
                -- Determine colors based on values
                local growthColor = stats.growth >= 100 and {100, 255, 100} or stats.growth >= 50 and {255, 200, 100} or {255, 255, 150}
                local thirstColor = stats.thirst > Config.StartDegrade and {100, 200, 255} or stats.thirst > 10 and {255, 200, 100} or {255, 100, 100}
                local hungerColor = stats.hunger > Config.StartDegrade and {150, 255, 150} or stats.hunger > 10 and {255, 200, 100} or {255, 100, 100}
                
                -- Growth bar
                local yOffset = 0.835
                DrawTxt(locale('cl_lang_43')..stats.growth..'%', 0.50, yOffset, 0.35, 0.35, true, growthColor[1], growthColor[2], growthColor[3], 255, true)
                
                -- Thirst and Hunger on same line
                yOffset = yOffset + 0.025
                DrawTxt(locale('cl_lang_44')..stats.thirst..'%', 0.46, yOffset, 0.32, 0.32, true, thirstColor[1], thirstColor[2], thirstColor[3], 255, true)
                DrawTxt(locale('cl_lang_45')..stats.hunger..'%', 0.54, yOffset, 0.32, 0.32, true, hungerColor[1], hungerColor[2], hungerColor[3], 255, true)
            end
            
            if IsControlJustPressed(2, RSGCore.Shared.Keybinds['J']) then
                TriggerEvent('rex-farming:client:plantmenu', nearestPlant.id)
            end
            Wait(4)
        else
            Wait(500)
        end
    end
end)

---------------------------------------------
-- plant menu
---------------------------------------------
RegisterNetEvent('rex-farming:client:plantmenu', function(id)

    RSGCore.Functions.TriggerCallback('rex-farming:server:getplantdata', function(result)
        if not result or not result[1] then
            lib.notify({ title = locale('cl_lang_24'), type = 'error', duration = 3000 })
            return
        end
        
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
                title = '🌿 '..RSGCore.Shared.Items[plantdata.planttype].label..locale('cl_lang_3'),
                menu = 'main_menu',
                onExit = function()
                    inplantmenu = false
                end,
                options = {
                    {
                        title = locale('cl_lang_25'),
                        description = locale('cl_lang_26'),
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
            -- Helper to get growth stage description
            local function getGrowthStage(growth)
                if growth < 33 then return locale('cl_lang_27')
                elseif growth < 66 then return locale('cl_lang_28')
                elseif growth < 100 then return locale('cl_lang_29')
                else return locale('cl_lang_30') end
            end

            local function getQualityLabel(quality)
                if quality > 75 then return locale('cl_lang_31')
                elseif quality > 50 then return locale('cl_lang_32')
                elseif quality > 25 then return locale('cl_lang_33')
                else return locale('cl_lang_34') end
            end

            local menuOptions = {
                {
                    title = locale('cl_lang_4')..plantdata.growth..'% ('..getGrowthStage(plantdata.growth)..')',
                    progress = plantdata.growth,
                    colorScheme = 'green',
                    icon = 'fa-solid fa-chart-line',
                },
                {
                    title = locale('cl_lang_5')..plantdata.quality..'% ('..getQualityLabel(plantdata.quality)..')',
                    progress = plantdata.quality,
                    colorScheme = qualityColorScheme,
                    icon = 'fa-solid fa-star',
                },
                {
                    title = locale('cl_lang_6')..plantdata.thirst..'%',
                    description = plantdata.thirst < Config.StartDegrade and locale('cl_lang_35') or locale('cl_lang_36'),
                    progress = plantdata.thirst,
                    colorScheme = thirstColorScheme,
                    icon = 'fa-solid fa-droplet',
                },
                {
                    title = locale('cl_lang_20')..plantdata.hunger..'%',
                    description = plantdata.hunger < Config.StartDegrade and locale('cl_lang_37') or locale('cl_lang_38'),
                    progress = plantdata.hunger,
                    colorScheme = hungerColorScheme,
                    icon = 'fa-solid fa-flask',
                },
            }

            -- Only show water/feed options if plant is not fully grown
            if plantdata.growth < 100 then
                table.insert(menuOptions, {
                    title = locale('cl_lang_7'),
                    description = locale('cl_lang_39'),
                    icon = 'fa-solid fa-droplet',
                    iconColor = '#74C0FC',
                    event = 'rex-farming:client:waterplant',
                    args = { plantid = plantdata.id },
                    arrow = true,
                    disabled = plantdata.thirst >= 100
                })
                table.insert(menuOptions, {
                    title = locale('cl_lang_21'),
                    description = locale('cl_lang_40'),
                    icon = 'fa-solid fa-poop',
                    iconColor = '#BA8C22',
                    event = 'rex-farming:client:feedplant',
                    args = { plantid = plantdata.id },
                    arrow = true,
                    disabled = plantdata.hunger >= 100
                })
            end

            -- Only show harvest option if plant is fully grown
            if plantdata.growth >= 100 then
                table.insert(menuOptions, {
                    title = locale('cl_lang_8'),
                    description = locale('cl_lang_41'),
                    icon = 'fa-solid fa-seedling',
                    iconColor = 'green',
                    event = 'rex-farming:client:harvestplant',
                    args = { plantid = plantdata.id, growth = plantdata.growth },
                    arrow = true
                })
            end

            lib.registerContext({
                id = 'plant_menu',
                title = RSGCore.Shared.Items[plantdata.planttype].label..locale('cl_lang_3'),
                onExit = function()
                    inplantmenu = false
                end,
                options = menuOptions
            })
            lib.showContext('plant_menu')
        end
    end, id)

end)

---------------------------------------------
-- water plant
---------------------------------------------
RegisterNetEvent('rex-farming:client:waterplant', function(data)
    if isBusy then
        lib.notify({ title = locale('cl_lang_42'), type = 'error', duration = 3000 })
        return
    end

    -- Check for water bucket with uses > 0
    local hasWaterBucket = RSGCore.Functions.HasItem('water_bucket', 1)

    if not hasWaterBucket then
        lib.notify({ title = locale('cl_lang_9'), type = 'error', duration = 5000 })
        inplantmenu = false
        return
    end

    isBusy = true
    LocalPlayer.state:set("inv_busy", true, true)
    FreezeEntityPosition(cache.ped, true)
    TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_BUCKET_POUR_LOW`, 0, true)
    Wait(10000)
    ClearPedTasksImmediately(cache.ped)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(cache.ped, false)
    TriggerServerEvent('rex-farming:server:waterPlant', data.plantid)
    LocalPlayer.state:set("inv_busy", false, true)
    isBusy = false
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
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_FEED_CHICKEN`, 0, true)
        Wait(10000)
        ClearPedTasksImmediately(cache.ped)
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

    -- NOTE: Growth validation moved to server-side for security

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

    -- NOTE: Job validation moved to server-side for security
    -- NOTE: Location validation moved to server-side for security

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
-- remove plant object (optimized with lookup cache)
---------------------------------------------
RegisterNetEvent('rex-farming:client:removePlantObject')
AddEventHandler('rex-farming:client:removePlantObject', function(plantId)
    -- Use cached lookup first
    local spawned = SpawnedPlantsById[plantId]
    if spawned and DoesEntityExist(spawned.obj) then
        SetEntityAsMissionEntity(spawned.obj, false)
        FreezeEntityPosition(spawned.obj, false)
        DeleteObject(spawned.obj)
        SpawnedPlantsById[plantId] = nil
    end
    
    -- Clean up from array
    for i = #SpawnedPlants, 1, -1 do
        if SpawnedPlants[i].id == plantId then
            table.remove(SpawnedPlants, i)
            break
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
