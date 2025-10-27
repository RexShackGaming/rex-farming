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
local collectingFertilizer = false

RegisterNetEvent('rex-farming:client:collectfertilizer', function()
	-- Prevent spam collection
	if collectingFertilizer then
		lib.notify({ title = locale('cl_lang_46'), type = 'error', duration = 3000 })
		return
	end

	local fertilizerObject = nil
	local coords = nil
	local pos = GetEntityCoords(cache.ped or PlayerPedId())
	
	-- Find nearest fertilizer object
	for i = 1, #Config.FertilizerProps do
		local obj = Config.FertilizerProps[i]
		local fertilizer = GetClosestObjectOfType(pos, 2.5, obj, false, false, false)

		if fertilizer and fertilizer ~= 0 then
			fertilizerObject = fertilizer
			coords = GetEntityCoords(fertilizerObject)
			break
		end
	end

	if not coords then 
		lib.notify({ title = locale('cl_lang_47'), type = 'error', duration = 3000 })
		return 
	end
	
	-- Check if already collected BEFORE progress bar
	RSGCore.Functions.TriggerCallback('rex-farming:server:checkcollectedfertilizer', function(exists)
		if exists then
			lib.notify({ title = locale('cl_lang_19'), type = 'error', duration = 5000 })
			return
		end
		
		collectingFertilizer = true
		
		-- Progress bar
		LocalPlayer.state:set('inv_busy', true, true)
		local success = lib.progressBar({
			duration = Config.CollectFertilizerTime,
			position = 'bottom',
			useWhileDead = false,
			canCancel = true,
			disableControl = true,
			disable = {
				move = true,
				mouse = false,
			},
			label = locale('cl_lang_18'),
		})
		
		LocalPlayer.state:set('inv_busy', false, true)
		collectingFertilizer = false
		
		if success then
			-- Mark as collected and give item
			TriggerServerEvent('rex-farming:server:collectedfertilizer', coords)
			if DoesEntityExist(fertilizerObject) then
				DeleteEntity(fertilizerObject)
				SetObjectAsNoLongerNeeded(fertilizerObject)
			end
		end
	end, coords)
end)
