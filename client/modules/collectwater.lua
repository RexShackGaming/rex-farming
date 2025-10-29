local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- target for collect water
---------------------------------------------
CreateThread(function()
    exports.ox_target:addModel(Config.WaterProps, {
        {
            name = 'waterobjects',
            icon = 'far fa-eye',
            label = locale('cl_lang_14'),
            onSelect = function()
                TriggerEvent('rex-farming:client:collectwater')
            end,
            distance = 3.0
        }
    })
end)

---------------------------------------------
-- collect water (optimized)
---------------------------------------------
local collectingWater = false

RegisterNetEvent('rex-farming:client:collectwater', function()
    if collectingWater then
        lib.notify({ title = locale('cl_lang_48'), type = 'error', duration = 3000 })
        return
    end

    -- Check for water bucket
    local hasItem = RSGCore.Functions.HasItem('water_bucket', 1)

    if not hasItem then
        lib.notify({ title = locale('cl_lang_15'), type = 'error', duration = 5000 })
        return
    end
    
    -- Check if bucket is empty (0 uses)
    local isEmpty = lib.callback.await('rex-farming:server:checkemptybucket', false)
    
    if not isEmpty then
        lib.notify({ title = locale('sv_lang_22'), type = 'error', duration = 5000 })
        return
    end

    collectingWater = true
    LocalPlayer.state:set("inv_busy", true, true)
    
    -- Get player ped and start animation
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)
    TaskStartScenarioInPlace(playerPed, joaat('WORLD_HUMAN_BUCKET_FILL'), 0, true)
    
    local success = lib.progressBar({
        duration = Config.CollectWaterTime or 10000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disableControl = true,
        disable = {
            move = true,
            mouse = true,
        },
        label = locale('cl_lang_16'),
    })
    
    -- Clear animation
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)
    
    LocalPlayer.state:set("inv_busy", false, true)
    collectingWater = false
    
    if success then
        TriggerServerEvent('rex-farming:server:refreshwaterbucket')
    end
end)
