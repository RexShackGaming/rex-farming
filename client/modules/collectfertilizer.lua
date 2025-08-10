local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- target for collect fertilizer
---------------------------------------------
CreateThread(function()
    exports.ox_target:addModel(Config.FertilizerProps, {
        {
            name = 'fertilizerobjects',
            icon = 'far fa-eye',
            label = locale('cl_lang_17'),
            onSelect = function()
                TriggerEvent('rex-farming:client:collectfertilizer')
            end,
            distance = 2.0
        }
    })
end)

---------------------------------------------
-- collect fertilizer
---------------------------------------------
RegisterNetEvent('rex-farming:client:collectfertilizer', function()

	for i = 1, #Config.FertilizerProps do
		local obj = Config.FertilizerProps[i]
		local pos = GetEntityCoords(PlayerPedId())
		local fertilizer = GetClosestObjectOfType(pos, 2.5, obj, false, false, false)

		if fertilizer and fertilizer ~= 0 then
			fertilizerObject = fertilizer
			coords = GetEntityCoords(fertilizerObject)
			if coords then break end
		end
	end

	-- progress bar
	LocalPlayer.state:set('inv_busy', true, true)
	lib.progressBar({
		duration = Config.CollectFertilizerTime,
		position = 'bottom',
		useWhileDead = false,
		canCancel = false,
		disableControl = true,
		disable = {
			move = true,
			mouse = false,
		},
		label = locale('cl_lang_18'),
	})
	LocalPlayer.state:set('inv_busy', false, true)

	if coords then
		RSGCore.Functions.TriggerCallback('rex-farming:server:checkcollectedfertilizer', function(exists)
			if not exists then
				DeleteEntity(fertilizerObject)
				SetObjectAsNoLongerNeeded(fertilizerObject)
				TriggerServerEvent('rex-farming:server:collectedfertilizer', coords)
				TriggerServerEvent('rex-farming:server:giveitem', 'fertilizer', 1)
			else
				DeleteEntity(fertilizerObject)
				SetObjectAsNoLongerNeeded(fertilizerObject)
				lib.notify({ title = locale('cl_lang_19'), type = 'error', duration = 7000 })
			end
		end, coords)
	end

end)