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
-- collect water
---------------------------------------------
RegisterNetEvent('rex-farming:client:collectwater', function()

    local hasItem = RSGCore.Functions.HasItem('waterbucket0', 1)

    if not hasItem then
        lib.notify({ title = locale('cl_lang_15'), type = 'error', duration = 7000 })
        return
    end

    if hasItem then
        -- progress bar
        LocalPlayer.state:set("inv_busy", true, true)
        lib.progressBar({
            duration = 10000,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disableControl = true,
            disable = {
                move = true,
                mouse = true,
            },
            label = locale('cl_lang_16'),
        })
        LocalPlayer.state:set("inv_busy", false, true)
        TriggerServerEvent('rex-farming:server:refreshwaterbucket')
    end

end)
