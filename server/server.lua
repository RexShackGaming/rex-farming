local RSGCore = exports['rsg-core']:GetCoreObject()
local PlantsLoaded = false
local CollectedFertilizer = {}
local HarvestCooldowns = {} -- Anti-spam protection
local WaterCooldowns = {} -- Water anti-spam
local FeedCooldowns = {} -- Feed anti-spam
lib.locale()

---------------------------------------------
-- weedseed
---------------------------------------------
RSGCore.Functions.CreateUseableItem('weedseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'weed', 'prop_weed_02', 'prop_weed_02', 'prop_weed_01', 'weedseed')
end)

---------------------------------------------
-- cornseed
---------------------------------------------
RSGCore.Functions.CreateUseableItem('cornseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'corn', 'CRP_CORNSTALKS_CB_SIM', 'CRP_CORNSTALKS_CA_SIM', 'CRP_CORNSTALKS_AB_SIM', 'cornseed')
end)

---------------------------------------------
-- sugarcane
---------------------------------------------
RSGCore.Functions.CreateUseableItem('sugarcaneseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'sugarcane', 'CRP_SUGARCANE_AA_SIM', 'CRP_SUGARCANE_AB_SIM', 'CRP_SUGARCANE_AC_SIM', 'sugarcaneseed')
end)

---------------------------------------------
-- cotton
---------------------------------------------
RSGCore.Functions.CreateUseableItem('cottonseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'cotton', 'CRP_COTTON_BC_SIM', 'CRP_COTTON_BA_SIM', 'CRP_COTTON_BB_SIM', 'cottonseed')
end)

---------------------------------------------
-- carrotseed
---------------------------------------------
RSGCore.Functions.CreateUseableItem('carrotseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'carrot', 'CRP_CARROTS_SAP_BA_SIM', 'CRP_CARROTS_SAP_BA_SIM', 'CRP_CARROTS_BA_SIM', 'carrotseed')
end)

---------------------------------------------
-- potatoseed
---------------------------------------------
RSGCore.Functions.CreateUseableItem('potatoseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'potato', 'crp_potato_aa_sim', 'crp_potato_aa_sim', 'crp_potato_sap_aa_sim', 'potatoseed')
end)

---------------------------------------------
-- wheatseed
---------------------------------------------
RSGCore.Functions.CreateUseableItem('wheatseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'wheat', 'crp_wheat_dry_aa_sim', 'crp_wheat_sap_long_ab_sim', 'crp_wheat_stk_ab_sim', 'wheatseed')
end)

---------------------------------------------
-- tomatoseed
---------------------------------------------
RSGCore.Functions.CreateUseableItem('tomatoseed', function(source)
    local src = source
    TriggerClientEvent('rex-farming:client:preplantseed', src, 'tomato', 'crp_tomatoes_aa_sim', 'crp_tomatoes_har_aa_sim', 'crp_tomatoes_sap_aa_sim', 'tomatoseed')
end)

---------------------------------------------
-- create plant id (cryptographically secure)
---------------------------------------------
local function CreatePlantId()
    local UniqueFound = false
    local plantid = nil
    while not UniqueFound do
        -- Use more secure random generation
        plantid = math.random(100000, 999999) .. '-' .. os.time() .. '-' .. math.random(1000, 9999)
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_farming WHERE plantid = ?", { plantid })
        if result == 0 then
            UniqueFound = true
        end
    end
    return plantid
end

---------------------------------------------
-- get plant data (optimized with async/await)
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-farming:server:getplantdata', function(source, cb, plantid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not plantid then 
        cb(nil)
        return
    end
    
    local result = MySQL.query.await('SELECT * FROM rex_farming WHERE plantid = ?', { plantid })
    
    if result and result[1] then
        cb(result)
    else
        cb(nil)
    end
end)

-----------------------------------------------------------------------

---Removes an item from the player's inventory.
---@param item string the name of the item to remove.
---@param amount number the number of items to remove.
RegisterNetEvent('rex-farming:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not item or not amount then return end

    if Player.Functions.RemoveItem(item, amount) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
    end
end)

---Adds an item from the player's inventory.
---@param item string the name of the item to add.
---@param amount number the number of items to add.
RegisterNetEvent('rex-farming:server:giveitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not item or not amount then return end

    if Player.Functions.AddItem(item, amount) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', amount)
    end
end)

-----------------------------------------------------------------------

-- update plant data
CreateThread(function()
    while true do
        Wait(5000)
        if PlantsLoaded then
            TriggerClientEvent('rex-farming:client:updatePlantData', -1, Config.FarmPlants)
        end
    end
end)

CreateThread(function()
    TriggerEvent('rex-farming:server:getPlants')
    PlantsLoaded = true
end)

RegisterServerEvent('rex-farming:server:savePlant')
AddEventHandler('rex-farming:server:savePlant', function(data, plantId, citizenid)
    if not data or not plantId or not citizenid then 
        print('[rex-farming] Error: Invalid data in savePlant')
        return 
    end
    
    local datas = json.encode(data)

    MySQL.insert.await('INSERT INTO rex_farming (properties, plantid, citizenid) VALUES (?, ?, ?)',
        { datas, plantId, citizenid }
    )
end)

---------------------------------------------
-- validate planting location server-side
---------------------------------------------
local function ValidatePlantingLocation(coords, citizenid)
    -- Check if too close to other plants
    for i = 1, #Config.FarmPlants do
        local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(Config.FarmPlants[i].x, Config.FarmPlants[i].y, Config.FarmPlants[i].z))
        if dist < 1.3 then
            return false, 'too_close'
        end
    end
    
    -- Validate coordinates are reasonable (not floating in air, underground, etc)
    if coords.z < -100.0 or coords.z > 1000.0 then
        return false, 'invalid_coords'
    end
    
    -- If GrowAnywhere is disabled, check zone validity
    if not Config.GrowAnywhere then
        local inZone = false
        for k, zone in pairs(Config.FarmingZone) do
            -- Basic zone check (you may need more sophisticated poly check)
            local dist = #(vector3(coords.x, coords.y, coords.z) - zone.fieldcoords)
            if dist < 100.0 then -- Reasonable distance from zone center
                inZone = true
                break
            end
        end
        if not inZone then
            return false, 'not_in_zone'
        end
    end
    
    return true, 'valid'
end

---------------------------------------------
-- plant seed
---------------------------------------------
RegisterServerEvent('rex-farming:server:plantnewseed')
AddEventHandler('rex-farming:server:plantnewseed', function(outputitem, inputitem, prophash1, prophash2, prophash3, propcoords, propheading)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local playerJobType = Player.PlayerData.job.type
    
    -- SERVER-SIDE job validation for weed
    if playerJobType == 'leo' and outputitem == 'weed' then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_10'), type = 'error', duration = 5000 })
        return
    end
    
    -- Validate planting location server-side
    local isValid, reason = ValidatePlantingLocation(propcoords, citizenid)
    if not isValid then
        if reason == 'too_close' then
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_11'), type = 'error', duration = 5000 })
        elseif reason == 'invalid_coords' then
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_12'), type = 'error', duration = 5000 })
        elseif reason == 'not_in_zone' then
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_13'), type = 'error', duration = 5000 })
        end
        return
    end
    
    local plantId = CreatePlantId()

    local SeedData =
    {
        id = plantId,
        planttype = outputitem,
        x = propcoords.x,
        y = propcoords.y,
        z = propcoords.z,
        h = propheading,
        thirst = Config.StartingThirst,
        hunger = Config.StartingHunger,
        growth = 0.0,
        quality = 100.0,
        grace = true,
        stage = 1,
        hash1 = prophash1,
        hash2 = prophash2,
        hash3 = prophash3,
        beingHarvested = false,
        planter = Player.PlayerData.citizenid,
        planttime = os.time()
    }

    local PlantCount = 0

    for _, v in pairs(Config.FarmPlants) do
        if v.planter == Player.PlayerData.citizenid then
            PlantCount = PlantCount + 1
        end
    end

    if PlantCount >= Config.MaxPlantCount then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_1'), type = 'inform', duration = 3000 })
    else
        table.insert(Config.FarmPlants, SeedData)
        TriggerEvent('rex-farming:server:savePlant', SeedData, plantId, citizenid)
        TriggerEvent('rex-farming:server:updatePlants')
        Player.Functions.RemoveItem(inputitem, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[inputitem], 'remove', 1)
    end
end)

---------------------------------------------
-- check plant (with mutex lock) - DEPRECATED, using cooldown system instead
---------------------------------------------
RegisterServerEvent('rex-farming:server:plantHasBeenHarvested')
AddEventHandler('rex-farming:server:plantHasBeenHarvested', function(plantId)
    -- No longer needed - cooldown system in harvestPlant handles anti-spam
end)

---------------------------------------------
-- distory plant (law)
---------------------------------------------
RegisterServerEvent('rex-farming:server:destroyplant')
AddEventHandler('rex-farming:server:destroyplant', function(data)
    local src = source
    for k, v in pairs(Config.FarmPlants) do
        if v.id == data.plantid then
            table.remove(Config.FarmPlants, k)
        end
    end
    TriggerClientEvent('rex-farming:client:removePlantObject', -1, data.plantid)
    TriggerEvent('rex-farming:server:PlantRemoved', data.plantid)
    TriggerEvent('rex-farming:server:updatePlants')
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_2'), type = 'success', duration = 3000 })
end)

---------------------------------------------
-- distory dead plant
---------------------------------------------
RegisterServerEvent('rex-farming:server:destroydeadplant')
AddEventHandler('rex-farming:server:destroydeadplant', function(deadid)
    for k, v in pairs(Config.FarmPlants) do
        if v.id == deadid then
            table.remove(Config.FarmPlants, k)
        end
    end
    TriggerClientEvent('rex-farming:client:removePlantObject', -1, deadid)
    TriggerEvent('rex-farming:server:PlantRemoved', deadid)
    TriggerEvent('rex-farming:server:updatePlants')
end)

---------------------------------------------
-- harvest plant and give reward
---------------------------------------------
RegisterServerEvent('rex-farming:server:harvestPlant')
AddEventHandler('rex-farming:server:harvestPlant', function(plantId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Anti-spam check
    if HarvestCooldowns[citizenid] and (os.time() - HarvestCooldowns[citizenid]) < 3 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_14'), type = 'error', duration = 3000 })
        return
    end
    
    local poorAmount = 0
    local goodAmount = 0
    local exellentAmount = 0
    local poorQuality = false
    local goodQuality = false
    local exellentQuality = false
    local hasFound = false
    local label = nil
    local item = nil
    local plantData = nil
    local plantKey = nil

    -- Find and validate plant
    for k, v in pairs(Config.FarmPlants) do
        if v.id == plantId then
            plantData = v
            plantKey = k
            break
        end
    end
    
    if not plantData then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_15'), type = 'error', duration = 3000 })
        return
    end
    
    -- SERVER-SIDE growth validation (don't trust client)
    if plantData.growth < 100 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_16'), type = 'error', duration = 3000 })
        return
    end
    
    -- Owner check before harvest
    if Config.OwnerHarvestOnly then
        if plantData.planter ~= citizenid then
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_9'), type = 'error', duration = 7000 })
            return
        end
    end
    
    -- Get reward data
    for y = 1, #Config.FarmItems do
        if plantData.planttype == Config.FarmItems[y].planttype then
            label = Config.FarmItems[y].label
            item = Config.FarmItems[y].item
            poorAmount = math.random(Config.FarmItems[y].poorRewardMin, Config.FarmItems[y].poorRewardMax)
            goodAmount = math.random(Config.FarmItems[y].goodRewardMin, Config.FarmItems[y].goodRewardMax)
            exellentAmount = math.random(Config.FarmItems[y].exellentRewardMin, Config.FarmItems[y].exellentRewardMax)
            local quality = math.ceil(plantData.quality)
            hasFound = true

            if quality > 0 and quality <= 25 then -- poor
                poorQuality = true
            elseif quality >= 25 and quality <= 75 then -- good
                goodQuality = true
            elseif quality >= 75 then -- excellent
                exellentQuality = true
            end
            break
        end
    end

    if not hasFound then return end
    
    -- Set cooldown
    HarvestCooldowns[citizenid] = os.time()
    
    -- Remove plant from table
    table.remove(Config.FarmPlants, plantKey)

    -- Give rewards
    if poorQuality then
        Player.Functions.AddItem(item, poorAmount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', poorAmount)
    elseif goodQuality then
        Player.Functions.AddItem(item, goodAmount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', goodAmount)
    elseif exellentQuality then
        Player.Functions.AddItem(item, exellentAmount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', exellentAmount)
    else
        print(locale('sv_lang_3'))
    end

    TriggerClientEvent('rex-farming:client:removePlantObject', -1, plantId)
    TriggerEvent('rex-farming:server:PlantRemoved', plantId)
    TriggerEvent('rex-farming:server:updatePlants')
end)

---------------------------------------------
-- update plants
---------------------------------------------
RegisterServerEvent('rex-farming:server:updatePlants')
AddEventHandler('rex-farming:server:updatePlants', function()
    TriggerClientEvent('rex-farming:client:updatePlantData', -1, Config.FarmPlants)
end)

---------------------------------------------
-- water plant (optimized bucket system with metadata)
---------------------------------------------
RegisterServerEvent('rex-farming:server:waterPlant')
AddEventHandler('rex-farming:server:waterPlant', function(plantid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not plantid then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Anti-spam check
    if WaterCooldowns[citizenid] and (os.time() - WaterCooldowns[citizenid]) < 2 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_17'), type = 'error', duration = 3000 })
        return
    end

    -- Find water bucket and decrease uses
    local item = Player.Functions.GetItemByName('water_bucket')
    if not item then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_18'), type = 'error', duration = 3000 })
        return
    end
    
    -- Get current uses, default to 0 if no metadata
    local currentUses = (item.info and item.info.uses) or 0
    
    if currentUses <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_19'), type = 'error', duration = 3000 })
        return
    end
    Player.Functions.RemoveItem('water_bucket', 1, item.slot)
    
    local newUses = currentUses - 1
    local newDescription = newUses > 0 and ('Water Bucket - ' .. newUses .. ' use' .. (newUses > 1 and 's' or '') .. ' left') or 'Empty Water Bucket'
    Player.Functions.AddItem('water_bucket', 1, nil, {uses = newUses, description = newDescription})
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['water_bucket'], 'remove', 1)
    
    -- Set cooldown
    WaterCooldowns[citizenid] = os.time()

    -- Update database of new thirst value
    local result = MySQL.query.await('SELECT properties FROM rex_farming WHERE plantid = ?', { plantid })
    if not result or not result[1] then 
        print('[rex-farming] Error: Plant not found - ' .. plantid)
        return 
    end
    
    local plantData = json.decode(result[1].properties)
    plantData.thirst = math.min((plantData.thirst or 0) + Config.ThirstIncrease, 100)
    -- Remove runtime-only flags
    plantData.beingHarvested = nil
    
    MySQL.update.await('UPDATE rex_farming SET properties = ? WHERE plantid = ?', 
        { json.encode(plantData), plantid }
    )
    
    TriggerEvent('rex-farming:server:updatePlants')
end)

---------------------------------------------
-- feed plant (optimized)
---------------------------------------------
RegisterServerEvent('rex-farming:server:feedPlant')
AddEventHandler('rex-farming:server:feedPlant', function(plantid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not plantid then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Anti-spam check
    if FeedCooldowns[citizenid] and (os.time() - FeedCooldowns[citizenid]) < 2 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_20'), type = 'error', duration = 3000 })
        return
    end
    
    local hasItem = RSGCore.Functions.HasItem(src, 'fertilizer', 1)

    if not hasItem then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_21'), type = 'error', duration = 3000 })
        return
    end

    -- Set cooldown
    FeedCooldowns[citizenid] = os.time()
    
    -- Update database of new hunger value
    local result = MySQL.query.await('SELECT properties FROM rex_farming WHERE plantid = ?', { plantid })
    if not result or not result[1] then 
        print('[rex-farming] Error: Plant not found - ' .. plantid)
        return 
    end
    
    local plantData = json.decode(result[1].properties)
    plantData.hunger = math.min((plantData.hunger or 0) + Config.HungerIncrease, 100)
    -- Remove runtime-only flags
    plantData.beingHarvested = nil
    
    MySQL.update.await('UPDATE rex_farming SET properties = ? WHERE plantid = ?', 
        { json.encode(plantData), plantid }
    )
    
    TriggerEvent('rex-farming:server:updatePlants')
    Player.Functions.RemoveItem('fertilizer', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['fertilizer'], 'remove', 1)
end)

---------------------------------------------
-- update plant (optimized)
---------------------------------------------
RegisterServerEvent('rex-farming:server:updateFarmPlants')
AddEventHandler('rex-farming:server:updateFarmPlants', function(id, data)
    if not id or not data then 
        print('[rex-farming] Error: Invalid parameters in updateFarmPlants')
        return 
    end

    -- Remove runtime-only flags before saving to database
    local dataToSave = data
    if dataToSave.beingHarvested ~= nil then
        dataToSave = {}
        for k, v in pairs(data) do
            if k ~= 'beingHarvested' then
                dataToSave[k] = v
            end
        end
    end

    local newData = json.encode(dataToSave)
    local affectedRows = MySQL.update.await('UPDATE rex_farming SET properties = ? WHERE plantid = ?', 
        { newData, id }
    )
    
    if affectedRows == 0 then
        print('[rex-farming] Warning: No plant found with ID ' .. id)
    end
end)

---------------------------------------------
-- remove plant (optimized - direct delete)
---------------------------------------------
RegisterServerEvent('rex-farming:server:PlantRemoved')
AddEventHandler('rex-farming:server:PlantRemoved', function(plantId)
    if not plantId then return end

    -- Direct delete by plantid instead of querying all plants
    MySQL.query.await('DELETE FROM rex_farming WHERE plantid = ?', { plantId })
    
    -- Remove from Config.FarmPlants cache
    for k = #Config.FarmPlants, 1, -1 do
        if Config.FarmPlants[k].id == plantId then
            table.remove(Config.FarmPlants, k)
            break
        end
    end
end)

---------------------------------------------
-- get plant
---------------------------------------------
RegisterServerEvent('rex-farming:server:getPlants')
AddEventHandler('rex-farming:server:getPlants', function()
    local result = MySQL.query.await('SELECT * FROM rex_farming')

    if not result[1] then return end

    for i = 1, #result do
        local plantData = json.decode(result[i].properties)
        -- Always reset beingHarvested flag on load (runtime-only flag)
        plantData.beingHarvested = false
        print(locale('sv_lang_4')..plantData.planttype..locale('sv_lang_5')..plantData.id)
        table.insert(Config.FarmPlants, plantData)
    end
end)

---------------------------------------------
-- refresh water bucket
---------------------------------------------
RegisterServerEvent('rex-farming:server:refreshwaterbucket')
AddEventHandler('rex-farming:server:refreshwaterbucket', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local item = Player.Functions.GetItemByName('water_bucket')
    
    if not item then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_6'), type = 'error', duration = 3000 })
        return
    end
    
    -- Get current uses, default to 0 if no metadata
    local currentUses = (item.info and item.info.uses) or 0
    
    -- Only fill if bucket is empty (0 uses)
    if currentUses == 0 then
        Player.Functions.RemoveItem('water_bucket', 1, item.slot)
        Player.Functions.AddItem('water_bucket', 1, nil, {uses = 5, description = 'Water Bucket - 5 uses left'})
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['water_bucket'], 'add', 1)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_22'), type = 'error', duration = 3000 })
    end
end)

---------------------------------------------
-- collected fertilizer
---------------------------------------------
RegisterNetEvent('rex-farming:server:collectedfertilizer')
AddEventHandler('rex-farming:server:collectedfertilizer', function(coords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local exists = false

    -- Check if already collected
    for i = 1, #CollectedFertilizer do
        local fertilizer = CollectedFertilizer[i]
        if fertilizer == coords then
            exists = true
            break
        end
    end

    if not exists then
        -- Mark as collected
        CollectedFertilizer[#CollectedFertilizer + 1] = coords
        
        -- Give item (moved from client event)
        Player.Functions.AddItem('fertilizer', 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['fertilizer'], 'add', 1)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_23'), type = 'error', duration = 3000 })
    end

end)

RSGCore.Functions.CreateCallback('rex-farming:server:checkcollectedfertilizer', function(source, cb, coords)
    local exists = false
    for i = 1, #CollectedFertilizer do
        local fertilizer = CollectedFertilizer[i]
        if fertilizer == coords then
            exists = true
            break
        end
    end
    cb(exists)
end)

---------------------------------------------
-- farming upkeep system
---------------------------------------------
lib.cron.new(Config.FarmingCronJob, function ()

    local weather = exports.weathersync:getWeather()
    local result = MySQL.query.await('SELECT * FROM rex_farming')

    if not result then goto continue end

    for i = 1, #result do

        local propData = json.decode(result[i].properties)
        local id = propData.id
        local thirst = propData.thirst
        local hunger = propData.hunger
        local growth = propData.growth
        local quality = propData.quality
        local stage = propData.stage
        local planttime = propData.planttime

        propData.thirst = thirst - Config.ThirstDecrease
        propData.hunger = hunger - Config.HungerDecrease

        if hunger > 0 then
            local growthboost = math.random(Config.GrowthBoostMin,Config.GrowthBoostMax)
            propData.growth = growth + Config.GrowthIncrease + growthboost
        else
            propData.growth = growth + Config.GrowthIncrease
        end
        
        -- Cap growth at 100% immediately
        if propData.growth > 100 then
            propData.growth = 100
        end

        -- wealther logic
        if weather == 'rain' then
            propData.thirst = thirst + Config.ThirstRaining + Config.ThirstDecrease
        end

        if weather == 'shower' then
            propData.thirst = thirst + Config.ThirstShower + Config.ThirstDecrease
        end

        if weather == 'drizzle' then
            propData.thirst = thirst + Config.ThirstDrizzle + Config.ThirstDecrease
        end

        if propData.thirst < 0 then
            propData.thirst = 0
        end

        if propData.thirst < Config.StartDegrade then
            propData.quality = quality - Config.QualityDegrade
        end

        -- Update stage based on capped growth value
        if propData.growth >= 25 and propData.growth < 100 then
            propData.stage = 2
        end

        if propData.growth >= 100 then
            propData.stage = 3
        end

        local untildead = planttime + Config.DeadPlantTime
        local currenttime = os.time()

        if currenttime > untildead then
            local deadid = id
            print(locale('sv_lang_7')..deadid)
            TriggerEvent('rex-farming:server:destroydeadplant', deadid)
        end

        if propData.quality <= 0 then
            local deadid = id
            print(locale('sv_lang_7')..deadid)
            TriggerEvent('rex-farming:server:destroydeadplant', deadid)
        end

        -- Remove runtime-only flags before saving
        propData.beingHarvested = nil

        MySQL.Async.execute('UPDATE rex_farming SET `properties` = ? WHERE `plantid`= ?', {json.encode(propData), id})
        
        -- Update Config.FarmPlants so clients see the stage change
        for j = 1, #Config.FarmPlants do
            if Config.FarmPlants[j].id == id then
                Config.FarmPlants[j].stage = propData.stage
                Config.FarmPlants[j].growth = propData.growth
                Config.FarmPlants[j].thirst = propData.thirst
                Config.FarmPlants[j].hunger = propData.hunger
                Config.FarmPlants[j].quality = propData.quality
                break
            end
        end

    end

    ::continue::

    if Config.EnableServerNotify then
        print(locale('sv_lang_8'))
    end
    
    TriggerEvent('rex-farming:server:updatePlants')

end)
