local RSGCore = exports['rsg-core']:GetCoreObject()
local PlantsLoaded = false
local CollectedFertilizer = {}
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
-- create plant id
---------------------------------------------
local function CreatePlantId()
    local UniqueFound = false
    local plantid = nil
    while not UniqueFound do
        plantid = math.random(111111, 999999)
        local query = "%" .. plantid .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_farming WHERE plantid LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return plantid
end

---------------------------------------------
-- get plant data
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-farming:server:getplantdata', function(source, cb, plantid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    MySQL.query('SELECT * FROM rex_farming WHERE plantid = ?', { plantid }, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
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
    local datas = json.encode(data)

    MySQL.Async.execute('INSERT INTO rex_farming (properties, plantid, citizenid) VALUES (@properties, @plantid, @citizenid)',
    {
        ['@properties'] = datas,
        ['@plantid'] = plantId,
        ['@citizenid'] = citizenid
    })
end)

---------------------------------------------
-- plant seed
---------------------------------------------
RegisterServerEvent('rex-farming:server:plantnewseed')
AddEventHandler('rex-farming:server:plantnewseed', function(outputitem, inputitem, prophash1, prophash2, prophash3, propcoords, propheading)
    local src = source
    local plantId = CreatePlantId()
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

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
-- check plant
---------------------------------------------
RegisterServerEvent('rex-farming:server:plantHasBeenHarvested')
AddEventHandler('rex-farming:server:plantHasBeenHarvested', function(plantId)
    for _, v in pairs(Config.FarmPlants) do
        if v.id == plantId then
            v.beingHarvested = true
        end
    end
    TriggerEvent('rex-farming:server:updatePlants')
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
    local poorAmount = 0
    local goodAmount = 0
    local exellentAmount = 0
    local poorQuality = false
    local goodQuality = false
    local exellentQuality = false
    local hasFound = false
    local label = nil
    local item = nil

    -- owner check before harvest
    if Config.OwnerHarvestOnly then
        for k, v in pairs(Config.FarmPlants) do
            if v.id == plantId and v.planter == Player.PlayerData.citizenid then
                for y = 1, #Config.FarmItems do
                    if v.planttype == Config.FarmItems[y].planttype then
                        label = Config.FarmItems[y].label
                        item = Config.FarmItems[y].item
                        poorAmount = math.random(Config.FarmItems[y].poorRewardMin, Config.FarmItems[y].poorRewardMax)
                        goodAmount = math.random(Config.FarmItems[y].goodRewardMin, Config.FarmItems[y].goodRewardMax)
                        exellentAmount = math.random(Config.FarmItems[y].exellentRewardMin, Config.FarmItems[y].exellentRewardMax)
                        local quality = math.ceil(v.quality)
                        hasFound = true

                        table.remove(Config.FarmPlants, k)

                        if quality > 0 and quality <= 25 then -- poor
                            poorQuality = true
                        elseif quality >= 25 and quality <= 75 then -- good
                            goodQuality = true
                        elseif quality >= 75 then -- excellent
                            exellentQuality = true
                        end
                    end
                end
            else
                TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_9'), type = 'error', duration = 7000 })
                return
            end
        end

        if not hasFound then return end

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
    else
        for k, v in pairs(Config.FarmPlants) do
            if v.id == plantId then
                for y = 1, #Config.FarmItems do
                    if v.planttype == Config.FarmItems[y].planttype then
                        label = Config.FarmItems[y].label
                        item = Config.FarmItems[y].item
                        poorAmount = math.random(Config.FarmItems[y].poorRewardMin, Config.FarmItems[y].poorRewardMax)
                        goodAmount = math.random(Config.FarmItems[y].goodRewardMin, Config.FarmItems[y].goodRewardMax)
                        exellentAmount = math.random(Config.FarmItems[y].exellentRewardMin, Config.FarmItems[y].exellentRewardMax)
                        local quality = math.ceil(v.quality)
                        hasFound = true

                        table.remove(Config.FarmPlants, k)

                        if quality > 0 and quality <= 25 then -- poor
                            poorQuality = true
                        elseif quality >= 25 and quality <= 75 then -- good
                            goodQuality = true
                        elseif quality >= 75 then -- excellent
                            exellentQuality = true
                        end
                    end
                end
            end
        end

        if not hasFound then return end

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
    end
end)

---------------------------------------------
-- update plants
---------------------------------------------
RegisterServerEvent('rex-farming:server:updatePlants')
AddEventHandler('rex-farming:server:updatePlants', function()
    TriggerClientEvent('rex-farming:client:updatePlantData', -1, Config.FarmPlants)
end)

---------------------------------------------
-- water plant
---------------------------------------------
RegisterServerEvent('rex-farming:server:waterPlant')
AddEventHandler('rex-farming:server:waterPlant', function(plantid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    local hasItem1 = RSGCore.Functions.HasItem(src, 'waterbucket5', 1)
    local hasItem2 = RSGCore.Functions.HasItem(src, 'waterbucket4', 1)
    local hasItem3 = RSGCore.Functions.HasItem(src, 'waterbucket3', 1)
    local hasItem4 = RSGCore.Functions.HasItem(src, 'waterbucket2', 1)
    local hasItem5 = RSGCore.Functions.HasItem(src, 'waterbucket1', 1)
    local hasItem6 = RSGCore.Functions.HasItem(src, 'waterbucket0', 1)

    if hasItem1 then
        Player.Functions.RemoveItem('waterbucket5', 1)
        Player.Functions.AddItem('waterbucket4', 1)
    end
    if hasItem2 then
        Player.Functions.RemoveItem('waterbucket4', 1)
        Player.Functions.AddItem('waterbucket3', 1)
    end
    if hasItem3 then
        Player.Functions.RemoveItem('waterbucket3', 1)
        Player.Functions.AddItem('waterbucket2', 1)
    end
    if hasItem4 then
        Player.Functions.RemoveItem('waterbucket2', 1)
        Player.Functions.AddItem('waterbucket1', 1)
    end
    if hasItem5 then
        Player.Functions.RemoveItem('waterbucket1', 1)
        Player.Functions.AddItem('waterbucket0', 1)
    end

    -- update database of new thirst value
    local result = MySQL.query.await('SELECT * FROM rex_farming WHERE plantid = @plantid', { ['@plantid'] = plantid })
    if not result[1] then return end
    for i = 1, #result do
        local plantData = json.decode(result[i].properties)
        local thirst = plantData.thirst
        plantData.thirst = thirst + Config.ThirstIncrease
        if plantData.thirst > 100 then
            plantData.thirst = 100
        end
        MySQL.Async.execute('UPDATE rex_farming SET `properties` = ? WHERE `plantid`= ?', {json.encode(plantData), plantid})
    end
    TriggerEvent('rex-farming:server:updatePlants')

end)

---------------------------------------------
-- feed plant
---------------------------------------------
RegisterServerEvent('rex-farming:server:feedPlant')
AddEventHandler('rex-farming:server:feedPlant', function(plantid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local hasItem = RSGCore.Functions.HasItem(src, 'fertilizer', 1)

    if hasItem then
        -- update database of new hunger value
        local result = MySQL.query.await('SELECT * FROM rex_farming WHERE plantid = @plantid', { ['@plantid'] = plantid })
        if not result[1] then return end
        for i = 1, #result do
            local plantData = json.decode(result[i].properties)
            local hunger = plantData.hunger
            plantData.hunger = hunger + Config.HungerIncrease
            if plantData.hunger > 100 then
                plantData.hunger = 100
            end
            MySQL.Async.execute('UPDATE rex_farming SET `properties` = ? WHERE `plantid`= ?', {json.encode(plantData), plantid})
        end
        TriggerEvent('rex-farming:server:updatePlants')
        Player.Functions.RemoveItem('fertilizer', 1)
    end
end)

---------------------------------------------
-- update plant
---------------------------------------------
RegisterServerEvent('rex-farming:server:updateFarmPlants')
AddEventHandler('rex-farming:server:updateFarmPlants', function(id, data)
    local result = MySQL.query.await('SELECT * FROM rex_farming WHERE plantid = @plantid', { ['@plantid'] = id })

    if not result[1] then return end

    local newData = json.encode(data)
    MySQL.Async.execute('UPDATE rex_farming SET properties = @properties WHERE plantid = @id', { ['@properties'] = newData, ['@id'] = id })
end)

---------------------------------------------
-- remove plant
---------------------------------------------
RegisterServerEvent('rex-farming:server:PlantRemoved')
AddEventHandler('rex-farming:server:PlantRemoved', function(plantId)
    local result = MySQL.query.await('SELECT * FROM rex_farming')

    if not result then return end

    for i = 1, #result do
        local plantData = json.decode(result[i].properties)

        if plantData.id == plantId then
            MySQL.Async.execute('DELETE FROM rex_farming WHERE id = @id', { ['@id'] = result[i].id })
            for k, v in pairs(Config.FarmPlants) do
                if v.id == plantId then
                    table.remove(Config.FarmPlants, k)
                end
            end
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
    local hasItem = RSGCore.Functions.HasItem(src, 'waterbucket0', 1)
    if hasItem then
        Player.Functions.RemoveItem('waterbucket0', 1)
        Player.Functions.AddItem('waterbucket5', 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['waterbucket5'], 'add', 1)
    else
        TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_6'), type = 'success', duration = 3000 })
    end
end)

---------------------------------------------
-- collected fertilizer
---------------------------------------------
RegisterNetEvent('rex-farming:server:collectedfertilizer')
AddEventHandler('rex-farming:server:collectedfertilizer', function(coords)
    local exists = false

    for i = 1, #CollectedFertilizer do
        local fertilizer = CollectedFertilizer[i]
        if fertilizer == coords then
            exists = true
            break
        end
    end

    if not exists then
        CollectedFertilizer[#CollectedFertilizer + 1] = coords
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

        if growth >= 100 then
            propData.growth = 100
        end

        if thirst < 0 then
            propData.thirst = 0
        end

        if thirst < Config.StartDegrade then
            propData.quality = quality - Config.QualityDegrade
        end

        if growth >= 25 and growth < 99 then
            propData.stage = 2
        end

        if growth >= 100 then
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

        MySQL.Async.execute('UPDATE rex_farming SET `properties` = ? WHERE `plantid`= ?', {json.encode(propData), id})

    end

    ::continue::

    if Config.EnableServerNotify then
        print(locale('sv_lang_8'))
    end
    
    TriggerEvent('rex-farming:server:updatePlants')

end)
