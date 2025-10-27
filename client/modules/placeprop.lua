local RSGCore = exports['rsg-core']:GetCoreObject()

math.randomseed(GetGameTimer())
local CancelPrompt
local SetPrompt
local RotateLeftPrompt
local RotateRightPrompt
local active = false
local Props = {}

local PromptPlacerGroup = GetRandomIntInRange(0, 0xffffff)

-- Optimized prompt initialization - run once instead of multiple threads
local function InitializePrompts()
    -- Cancel Prompt
    local str = CreateVarString(10, 'LITERAL_STRING', Config.PromptCancelName)
    CancelPrompt = PromptRegisterBegin()
    PromptSetControlAction(CancelPrompt, 0xF84FA74F)
    PromptSetText(CancelPrompt, str)
    PromptSetEnabled(CancelPrompt, true)
    PromptSetVisible(CancelPrompt, true)
    PromptSetHoldMode(CancelPrompt, true)
    PromptSetGroup(CancelPrompt, PromptPlacerGroup)
    PromptRegisterEnd(CancelPrompt)
    
    -- Place Prompt
    str = CreateVarString(10, 'LITERAL_STRING', Config.PromptPlaceName)
    SetPrompt = PromptRegisterBegin()
    PromptSetControlAction(SetPrompt, 0xC7B5340A)
    PromptSetText(SetPrompt, str)
    PromptSetEnabled(SetPrompt, true)
    PromptSetVisible(SetPrompt, true)
    PromptSetHoldMode(SetPrompt, true)
    PromptSetGroup(SetPrompt, PromptPlacerGroup)
    PromptRegisterEnd(SetPrompt)
    
    -- Rotate Left Prompt
    str = CreateVarString(10, 'LITERAL_STRING', Config.PromptRotateLeft)
    RotateLeftPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4)
    PromptSetText(RotateLeftPrompt, str)
    PromptSetEnabled(RotateLeftPrompt, true)
    PromptSetVisible(RotateLeftPrompt, true)
    PromptSetStandardMode(RotateLeftPrompt, true)
    PromptSetGroup(RotateLeftPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RotateLeftPrompt)
    
    -- Rotate Right Prompt
    str = CreateVarString(10, 'LITERAL_STRING', Config.PromptRotateRight)
    RotateRightPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateRightPrompt, 0xDEB34313)
    PromptSetText(RotateRightPrompt, str)
    PromptSetEnabled(RotateRightPrompt, true)
    PromptSetVisible(RotateRightPrompt, true)
    PromptSetStandardMode(RotateRightPrompt, true)
    PromptSetGroup(RotateRightPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RotateRightPrompt)
end

CreateThread(function()
    InitializePrompts()
end)

-- Optimized model request
local function RequestAndLoadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 10 do
            Wait(500)
            timeout = timeout + 1
        end
        if not HasModelLoaded(model) then
            return false
        end
    end
    return true
end

function PropPlacer(outputitem, prophash1, prophash2, prophash3, inputitem)
    local myPed = cache.ped or PlayerPedId()
    local pos = GetEntityCoords(myPed)
    local PropHash = prophash1
    local forward = GetEntityForwardVector(myPed)
    local targetPos = pos - forward * -Config.ForwardDistance
    local ox = targetPos.x - pos.x
    local oy = targetPos.y - pos.y
    local propheading = 0.0

    SetCurrentPedWeapon(myPed, `WEAPON_UNARMED`, true)
    
    -- Request model with timeout
    if not RequestAndLoadModel(PropHash) then
        lib.notify({ title = locale('cl_lang_49'), type = 'error', duration = 5000 })
        return
    end
    local tempObj = CreateObject(PropHash, pos.x, pos.y, pos.z, false, false, false)
    local tempObj2 = CreateObject(PropHash, pos.x, pos.y, pos.z, false, false, false)
    AttachEntityToEntity(tempObj2, myPed, 0, ox, oy, 0.5, 0.0, 0.0, 0, true, false, false, false, false)
    SetEntityAlpha(tempObj, 180)
    SetEntityAlpha(tempObj2, 0)

    while true do
        Wait(5)
        local PropPlacerGroupName  = CreateVarString(10, 'LITERAL_STRING', Config.PromptGroupName)
        PromptSetActiveGroupThisFrame(PromptPlacerGroup, PropPlacerGroupName)

        AttachEntityToEntity(tempObj, myPed, 0, ox, oy, -0.8, 0.0, 0.0, propheading, true, false, false, false, false)
        if IsControlPressed( 1, 0xA65EBAB4) then
            propheading = propheading - 1
        end
        if IsControlPressed( 1, 0xDEB34313) then
            propheading = propheading + 1
        end

        local propcoords = GetEntityCoords(tempObj2)

        if PromptHasHoldModeCompleted(SetPrompt) then
            FreezeEntityPosition(PlayerPedId() , true)
            TriggerEvent('rex-farming:client:plantnewseed', outputitem, inputitem, prophash1, prophash2, prophash3, propcoords, propheading)
            DeleteEntity(tempObj2)
            DeleteEntity(tempObj)
            FreezeEntityPosition(PlayerPedId() , false)
            break
        end

        if PromptHasHoldModeCompleted(CancelPrompt) then
            DeleteEntity(tempObj2)
            DeleteEntity(tempObj)
            SetModelAsNoLongerNeeded(PropHash)
            break
        end
    end
end

RegisterNetEvent('rex-farming:client:preplantseed', function(outputitem, prophash1, prophash2, prophash3, inputitem)
    PropPlacer(outputitem, prophash1, prophash2, prophash3, inputitem)
end)
