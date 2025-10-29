local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- fill bucket from water sources
---------------------------------------------
local fillingBucket = false
local showingPrompt = false

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Check if player is in water
        local isInWater = IsEntityInWater(playerPed)
        
        if isInWater and not fillingBucket then
            -- Check if player has a water bucket
            local hasBucket = RSGCore.Functions.HasItem('water_bucket', 1)
            
            if hasBucket then
                -- Check if bucket is empty synchronously by making the check blocking
                local isEmpty = lib.callback.await('rex-farming:server:checkemptybucket', false)
                
                if isEmpty then
                    sleep = 0 -- Check every frame
                    
                if not showingPrompt then
                    lib.showTextUI(locale('cl_lang_50'), {
                        position = "left-center",
                        icon = 'fas fa-hand-holding-water',
                    })
                    showingPrompt = true
                end
                    
                    if IsControlJustPressed(0, 0xCEFD9220) then -- E key
                        lib.hideTextUI()
                        showingPrompt = false
                        TriggerEvent('rex-farming:client:fillbucketfromwater')
                    end
                elseif showingPrompt then
                    lib.hideTextUI()
                    showingPrompt = false
                end
            elseif showingPrompt then
                lib.hideTextUI()
                showingPrompt = false
            end
        else
            if showingPrompt then
                lib.hideTextUI()
                showingPrompt = false
            end
        end
        
        Wait(sleep)
    end
end)

---------------------------------------------
-- fill bucket from water
---------------------------------------------
RegisterNetEvent('rex-farming:client:fillbucketfromwater', function()
    if fillingBucket then
        lib.notify({ title = locale('cl_lang_48'), type = 'error', duration = 3000 })
        return
    end

    -- Check for water bucket (empty or any)
    local hasItem = RSGCore.Functions.HasItem('water_bucket', 1)

    if not hasItem then
        lib.notify({ title = locale('cl_lang_15'), type = 'error', duration = 5000 })
        return
    end

    fillingBucket = true
    LocalPlayer.state:set("inv_busy", true, true)
    
    -- Get player ped and start animation
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)
    TaskStartScenarioInPlace(playerPed, joaat('WORLD_HUMAN_BUCKET_FILL'), 0, true)
    
    local success = lib.progressBar({
        duration = Config.CollectWaterTime or 5000,
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
    fillingBucket = false
    
    if success then
        TriggerServerEvent('rex-farming:server:refreshwaterbucket')
    end
end)
