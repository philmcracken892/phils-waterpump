local RSGCore = exports['rsg-core']:GetCoreObject()
local placedPumps = {}
local isPlacing = false
local isFilling = false
local spawnDistance = Config.SpawnDistance or 100.0

-- Placement Prompts
local CancelPrompt
local SetPrompt
local RotateLeftPrompt
local RotateRightPrompt
local PitchUpPrompt
local PitchDownPrompt
local RollLeftPrompt
local RollRightPrompt
local confirmed
local heading
local pitch
local roll
local PromptPlacerGroup = GetRandomIntInRange(0, 0xffffff)

-- Pump Interaction Prompts
local PumpPromptGroup = GetRandomIntInRange(0, 0xffffff)
local FillBottlePrompt
local PickupPumpPrompt
local currentPumpId = nil

-- ==========================================
-- PROMPT INITIALIZATION
-- ==========================================

CreateThread(function()
    InitializePlacerPrompts()
    InitializePumpPrompts()
end)

function InitializePlacerPrompts()
    -- Cancel Prompt
    local cancelStr = Config.PromptCancelName or "Cancel"
    CancelPrompt = PromptRegisterBegin()
    PromptSetControlAction(CancelPrompt, 0xF84FA74F) -- B key
    cancelStr = CreateVarString(10, 'LITERAL_STRING', cancelStr)
    PromptSetText(CancelPrompt, cancelStr)
    PromptSetEnabled(CancelPrompt, true)
    PromptSetVisible(CancelPrompt, true)
    PromptSetHoldMode(CancelPrompt, true)
    PromptSetGroup(CancelPrompt, PromptPlacerGroup)
    PromptRegisterEnd(CancelPrompt)

    -- Place/Set Prompt
    local setStr = Config.PromptPlaceName or "Place Pump"
    SetPrompt = PromptRegisterBegin()
    PromptSetControlAction(SetPrompt, 0xC7B5340A) -- Enter key
    setStr = CreateVarString(10, 'LITERAL_STRING', setStr)
    PromptSetText(SetPrompt, setStr)
    PromptSetEnabled(SetPrompt, true)
    PromptSetVisible(SetPrompt, true)
    PromptSetHoldMode(SetPrompt, true)
    PromptSetGroup(SetPrompt, PromptPlacerGroup)
    PromptRegisterEnd(SetPrompt)

    -- Rotate Left Prompt
    local rotLeftStr = Config.PromptRotateLeft or "Rotate Left"
    RotateLeftPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4) -- Left Arrow
    rotLeftStr = CreateVarString(10, 'LITERAL_STRING', rotLeftStr)
    PromptSetText(RotateLeftPrompt, rotLeftStr)
    PromptSetEnabled(RotateLeftPrompt, true)
    PromptSetVisible(RotateLeftPrompt, true)
    PromptSetHoldMode(RotateLeftPrompt, true)
    PromptSetGroup(RotateLeftPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RotateLeftPrompt)

    -- Rotate Right Prompt
    local rotRightStr = Config.PromptRotateRight or "Rotate Right"
    RotateRightPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateRightPrompt, 0xDEB34313) -- Right Arrow
    rotRightStr = CreateVarString(10, 'LITERAL_STRING', rotRightStr)
    PromptSetText(RotateRightPrompt, rotRightStr)
    PromptSetEnabled(RotateRightPrompt, true)
    PromptSetVisible(RotateRightPrompt, true)
    PromptSetHoldMode(RotateRightPrompt, true)
    PromptSetGroup(RotateRightPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RotateRightPrompt)

    -- Pitch Up Prompt
    local pitchUpStr = Config.PromptPitchUp or "Pitch Up"
    PitchUpPrompt = PromptRegisterBegin()
    PromptSetControlAction(PitchUpPrompt, 0x6319DB71) -- Up Arrow
    pitchUpStr = CreateVarString(10, 'LITERAL_STRING', pitchUpStr)
    PromptSetText(PitchUpPrompt, pitchUpStr)
    PromptSetEnabled(PitchUpPrompt, true)
    PromptSetVisible(PitchUpPrompt, true)
    PromptSetHoldMode(PitchUpPrompt, true)
    PromptSetGroup(PitchUpPrompt, PromptPlacerGroup)
    PromptRegisterEnd(PitchUpPrompt)

    -- Pitch Down Prompt
    local pitchDownStr = Config.PromptPitchDown or "Pitch Down"
    PitchDownPrompt = PromptRegisterBegin()
    PromptSetControlAction(PitchDownPrompt, 0x8CF8F910) -- Down Arrow
    pitchDownStr = CreateVarString(10, 'LITERAL_STRING', pitchDownStr)
    PromptSetText(PitchDownPrompt, pitchDownStr)
    PromptSetEnabled(PitchDownPrompt, true)
    PromptSetVisible(PitchDownPrompt, true)
    PromptSetHoldMode(PitchDownPrompt, true)
    PromptSetGroup(PitchDownPrompt, PromptPlacerGroup)
    PromptRegisterEnd(PitchDownPrompt)

    -- Roll Left Prompt
    local rollLeftStr = Config.PromptRollLeft or "Roll Left"
    RollLeftPrompt = PromptRegisterBegin()
    PromptSetControlAction(RollLeftPrompt, 0xF1E9A8D7) -- Q key
    rollLeftStr = CreateVarString(10, 'LITERAL_STRING', rollLeftStr)
    PromptSetText(RollLeftPrompt, rollLeftStr)
    PromptSetEnabled(RollLeftPrompt, true)
    PromptSetVisible(RollLeftPrompt, true)
    PromptSetHoldMode(RollLeftPrompt, true)
    PromptSetGroup(RollLeftPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RollLeftPrompt)

    -- Roll Right Prompt
    local rollRightStr = Config.PromptRollRight or "Roll Right"
    RollRightPrompt = PromptRegisterBegin()
    PromptSetControlAction(RollRightPrompt, 0xE764D794) -- E key
    rollRightStr = CreateVarString(10, 'LITERAL_STRING', rollRightStr)
    PromptSetText(RollRightPrompt, rollRightStr)
    PromptSetEnabled(RollRightPrompt, true)
    PromptSetVisible(RollRightPrompt, true)
    PromptSetHoldMode(RollRightPrompt, true)
    PromptSetGroup(RollRightPrompt, PromptPlacerGroup)
    PromptRegisterEnd(RollRightPrompt)
end

function InitializePumpPrompts()
    -- Fill Bottle Prompt
    local fillStr = Config.PromptFillBottle or "Fill Bottle"
    FillBottlePrompt = PromptRegisterBegin()
    PromptSetControlAction(FillBottlePrompt, 0xCEFD9220) -- E key
    fillStr = CreateVarString(10, 'LITERAL_STRING', fillStr)
    PromptSetText(FillBottlePrompt, fillStr)
    PromptSetEnabled(FillBottlePrompt, true)
    PromptSetVisible(FillBottlePrompt, true)
    PromptSetHoldMode(FillBottlePrompt, true)
    PromptSetGroup(FillBottlePrompt, PumpPromptGroup)
    PromptRegisterEnd(FillBottlePrompt)

    -- Pickup Pump Prompt
    local pickupStr = Config.PromptPickupPump or "Pick Up Pump"
    PickupPumpPrompt = PromptRegisterBegin()
    PromptSetControlAction(PickupPumpPrompt, 0xF84FA74F) -- B key
    pickupStr = CreateVarString(10, 'LITERAL_STRING', pickupStr)
    PromptSetText(PickupPumpPrompt, pickupStr)
    PromptSetEnabled(PickupPumpPrompt, true)
    PromptSetVisible(PickupPumpPrompt, true)
    PromptSetHoldMode(PickupPumpPrompt, true)
    PromptSetGroup(PickupPumpPrompt, PumpPromptGroup)
    PromptRegisterEnd(PickupPumpPrompt)
end



function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local rayHandle = StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, 1 + 2 + 4 + 8 + 16, PlayerPedId(), 0)
    local _, hit, coords, surfaceNormal, entity = GetShapeTestResult(rayHandle)
    return hit, coords, surfaceNormal, entity
end

function GetSurfaceType(surfaceNormal)
    if surfaceNormal.z > 0.7 then
        return "floor"
    elseif surfaceNormal.z < -0.7 then
        return "ceiling"
    else
        return "wall"
    end
end

function AlignPropToSurface(prop, surfaceNormal, coords, entity)
    local propThickness = 0.01
    local offsetDistance = propThickness
    
    if DoesEntityExist(entity) and entity ~= 0 then
        local entityType = GetEntityType(entity)
        if entityType == 2 or entityType == 3 then
            local forward, right, up, _ = GetEntityMatrix(entity)
            surfaceNormal = up
        end
    end
    
    local offsetCoords = vector3(
        coords.x + (surfaceNormal.x * offsetDistance),
        coords.y + (surfaceNormal.y * offsetDistance),
        coords.z + (surfaceNormal.z * offsetDistance)
    )
    
    SetEntityCoordsNoOffset(prop, offsetCoords.x, offsetCoords.y, offsetCoords.z, false, false, false, true)
    SetEntityRotation(prop, pitch, roll, heading, 2, false)
end

function SnapPropToSurface(prop, coords, surfaceNormal, entity)
    local propPos = GetEntityCoords(prop)
    local rayStart = vector3(propPos.x, propPos.y, propPos.z + 0.1)
    local rayEnd = vector3(
        propPos.x - (surfaceNormal.x * 1.5),
        propPos.y - (surfaceNormal.y * 1.5),
        propPos.z - (surfaceNormal.z * 1.5)
    )
    
    local rayHandle = StartShapeTestRay(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, 1 + 2 + 4 + 8 + 16, prop, 0)
    local _, hit, snapCoords, snapNormal, hitEntity = GetShapeTestResult(rayHandle)
    
    if hit then
        local propThickness = 0.01
        
        if DoesEntityExist(hitEntity) and hitEntity ~= 0 then
            local entityType = GetEntityType(hitEntity)
            if entityType == 2 or entityType == 3 then
                local forward, right, up, _ = GetEntityMatrix(hitEntity)
                snapNormal = up
            end
        end
        
        local finalCoords
        if math.abs(snapNormal.z) > 0.95 then
            if snapNormal.z > 0 then
                finalCoords = vector3(snapCoords.x, snapCoords.y, snapCoords.z + propThickness)
            else
                finalCoords = vector3(snapCoords.x, snapCoords.y, snapCoords.z - propThickness)
            end
        else
            finalCoords = vector3(
                snapCoords.x + (snapNormal.x * propThickness),
                snapCoords.y + (snapNormal.y * propThickness),
                snapCoords.z + (snapNormal.z * propThickness)
            )
        end
        
        SetEntityCoordsNoOffset(prop, finalCoords.x, finalCoords.y, finalCoords.z, false, false, false, true)
        return true
    end
    
    return false
end

function DrawPropAxes(prop)
    local propForward, propRight, propUp, propCoords = GetEntityMatrix(prop)
    local propXAxisEnd = propCoords + propRight * 0.20
    local propYAxisEnd = propCoords + propForward * 0.20
    local propZAxisEnd = propCoords + propUp * 0.20
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propXAxisEnd.x, propXAxisEnd.y, propXAxisEnd.z, 255, 0, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propYAxisEnd.x, propYAxisEnd.y, propYAxisEnd.z, 0, 255, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propZAxisEnd.x, propZAxisEnd.y, propZAxisEnd.z, 0, 0, 255, 255)
end

function DrawSurfaceNormal(coords, surfaceNormal)
    local normalEnd = vector3(
        coords.x + (surfaceNormal.x * 0.5),
        coords.y + (surfaceNormal.y * 0.5),
        coords.z + (surfaceNormal.z * 0.5)
    )
    DrawLine(coords.x, coords.y, coords.z, normalEnd.x, normalEnd.y, normalEnd.z, 255, 255, 255, 255)
end

local function LoadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 10000 then
            return nil
        end
    end
    return hash
end

local function LoadAnimDict(dict)
    if not DoesAnimDictExist(dict) then
        
        return false
    end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            
            return false
        end
    end
    return true
end



function PlayAnimWithProp(animDict, animName, duration, propModel, propBone, propOffset, propRotation)
    local playerPed = PlayerPedId()
    local prop = nil
    
   
    if not LoadAnimDict(animDict) then
        return false, nil
    end
    
    
    if propModel and Config.UsePropDuringAnim then
        local propHash = LoadModel(propModel)
        if propHash then
            local coords = GetEntityCoords(playerPed)
            prop = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, true)
            
            if DoesEntityExist(prop) then
                local boneIndex = GetEntityBoneIndexByName(playerPed, propBone or "SKEL_R_Hand")
                AttachEntityToEntity(
                    prop,
                    playerPed,
                    boneIndex,
                    propOffset and propOffset.x or 0.0,
                    propOffset and propOffset.y or 0.0,
                    propOffset and propOffset.z or 0.0,
                    propRotation and propRotation.x or 0.0,
                    propRotation and propRotation.y or 0.0,
                    propRotation and propRotation.z or 0.0,
                    true, true, false, true, 1, true
                )
            end
        end
    end
    
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, duration, 1, 0, false, false, false)
    
    return true, prop
end

function CleanupAnimProp(prop)
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    end
end

function PlayPlacingAnimation(callback)
    local playerPed = PlayerPedId()
    local animDict = Config.Anim.placingDict
    local animName = Config.Anim.placingName
    local duration = Config.Anim.placingDuration
    
    if not LoadAnimDict(animDict) then
        if callback then callback(true) end
        return
    end
    
    
    FreezeEntityPosition(playerPed, true)
    
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, duration, 1, 0, false, false, false)
    
    
    Wait(duration)
    
    
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)
    
    if callback then callback(true) end
end

function PlayFillBottleAnimation(pumpCoords, callback)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local animDict = Config.Anim.dict
    local animName = Config.Anim.name
    local duration = Config.Anim.duration
    
    
    local headingToPump = GetHeadingFromVector_2d(pumpCoords.x - playerCoords.x, pumpCoords.y - playerCoords.y)
    SetEntityHeading(playerPed, headingToPump)
    Wait(100)
    
    if not LoadAnimDict(animDict) then
        if callback then callback(false) end
        return
    end
    
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    
    local success = lib.progressBar({
        duration = duration,
        label = 'Filling with water...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            sprint = true
        }
    })
    
    
    ClearPedTasks(playerPed)
    
    if callback then callback(success) end
end

function PlayPickupAnimation(pumpCoords, callback)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local animDict = Config.Anim.dict
    local animName = Config.Anim.name
    local duration = Config.Anim.duration
    
    
    local headingToPump = GetHeadingFromVector_2d(pumpCoords.x - playerCoords.x, pumpCoords.y - playerCoords.y)
    SetEntityHeading(playerPed, headingToPump)
    Wait(100)
    
    if not LoadAnimDict(animDict) then
        if callback then callback(false) end
        return
    end
    
   
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    
    local success = lib.progressBar({
        duration = duration,
        label = 'Picking up pump...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            sprint = true
        }
    })
    
    
    ClearPedTasks(playerPed)
    
    if callback then callback(success) end
end



RegisterNetEvent('rsg-waterpump:client:startPlacement', function()
    if isPlacing then return end
    PlaceWaterPump()
end)

function PlaceWaterPump()
    isPlacing = true
    
    local pumpModel = GetHashKey(Config.PumpModel)
    RequestModel(pumpModel)
    
    local timeout = 0
    while not HasModelLoaded(pumpModel) do 
        Wait(100) 
        timeout = timeout + 100
        if timeout > 10000 then
            lib.notify({type = 'error', description = 'Failed to load pump model'})
            isPlacing = false
            return
        end
    end

    
    SetCurrentPedWeapon(PlayerPedId(), -1569615261, true)

    heading = 0.0
    pitch = 0.0
    roll = 0.0
    confirmed = false

    local hit, coords, surfaceNormal, entity

   
    while not hit do
        hit, coords, surfaceNormal, entity = RayCastGamePlayCamera(1000.0)
        Wait(0)
    end

    
    local tempObject = CreateObject(pumpModel, coords.x, coords.y, coords.z, true, false, true)
    
    if not DoesEntityExist(tempObject) then
        lib.notify({type = 'error', description = 'Failed to create pump object'})
        isPlacing = false
        return
    end

    
    if EagleEyeSetCustomEntityTint then
        EagleEyeSetCustomEntityTint(tempObject, 255, 255, 0)
    end

    CreateThread(function()
        while not confirmed and isPlacing do
            hit, coords, surfaceNormal, entity = RayCastGamePlayCamera(1000.0)

            if hit then
                AlignPropToSurface(tempObject, surfaceNormal, coords, entity)
                SnapPropToSurface(tempObject, coords, surfaceNormal, entity)
                
                FreezeEntityPosition(tempObject, true)
                SetEntityCollision(tempObject, false, false)
                SetEntityAlpha(tempObject, 150, false)
                
                
                DrawPropAxes(tempObject)
                DrawSurfaceNormal(coords, surfaceNormal)
                
                
                local rotationInfo = string.format("Yaw: %.1f° Pitch: %.1f° Roll: %.1f°", heading, pitch, roll)
                SetTextScale(0.3, 0.3)
                SetTextColor(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropshadow(1, 0, 0, 0, 255)
                DisplayText(CreateVarString(10, "LITERAL_STRING", rotationInfo), 0.5, 0.08)
                
                
                local surfaceType = GetSurfaceType(surfaceNormal)
                SetTextScale(0.35, 0.35)
                SetTextColor(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropshadow(1, 0, 0, 0, 255)
                DisplayText(CreateVarString(10, "LITERAL_STRING", "Surface: " .. surfaceType), 0.5, 0.05)
            end
            
            Wait(0)

           
            local PropPlacerGroupName = CreateVarString(10, 'LITERAL_STRING', Config.PromptGroupName or "Water Pump Placement")
            PromptSetActiveGroupThisFrame(PromptPlacerGroup, PropPlacerGroupName)

            local rotationSpeed = 2.0
            
            
            if IsControlPressed(1, 0xA65EBAB4) then -- Left arrow
                heading = heading + rotationSpeed
            elseif IsControlPressed(1, 0xDEB34313) then -- Right arrow
                heading = heading - rotationSpeed
            end
            
            if IsControlPressed(1, 0x6319DB71) then -- Arrow Up
                pitch = pitch + rotationSpeed
            elseif IsControlPressed(1, 0x8CF8F910) then -- Arrow Down
                pitch = pitch - rotationSpeed
            end
            
            if IsControlPressed(1, 0xF1E9A8D7) then -- Q key
                roll = roll + rotationSpeed
            elseif IsControlPressed(1, 0xE764D794) then -- E key
                roll = roll - rotationSpeed
            end

            
            if heading > 360.0 then heading = heading - 360.0 end
            if heading < 0.0 then heading = heading + 360.0 end
            if pitch > 360.0 then pitch = pitch - 360.0 end
            if pitch < 0.0 then pitch = pitch + 360.0 end
            if roll > 360.0 then roll = roll - 360.0 end
            if roll < 0.0 then roll = roll + 360.0 end

            
            if PromptHasHoldModeCompleted(SetPrompt) then
                confirmed = true
                isPlacing = false
                
                local finalCoords = GetEntityCoords(tempObject)
                local finalHeading = heading
                local finalPitch = pitch
                local finalRoll = roll
                
                
                if DoesEntityExist(tempObject) then
                    SetEntityAsMissionEntity(tempObject, false, false)
                    DeleteEntity(tempObject)
                end
                SetModelAsNoLongerNeeded(pumpModel)
                
              
                PlayPlacingAnimation(function(success)
                    if success then
                        
                        TriggerServerEvent('rsg-waterpump:server:placePump', {
                            x = finalCoords.x,
                            y = finalCoords.y,
                            z = finalCoords.z,
                            heading = finalHeading,
                            pitch = finalPitch,
                            roll = finalRoll
                        })
                        
                        lib.notify({type = 'success', description = 'Water pump placed successfully!'})
                    end
                end)
                
                break
            end

            
            if PromptHasHoldModeCompleted(CancelPrompt) then
                isPlacing = false
                confirmed = true
                
                if DoesEntityExist(tempObject) then
                    SetEntityAsMissionEntity(tempObject, false, false)
                    DeleteEntity(tempObject)
                end
                SetModelAsNoLongerNeeded(pumpModel)
                
                lib.notify({type = 'error', description = 'Placement cancelled'})
                break
            end
        end
    end)
end


CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearPump = false
        local nearestPumpId = nil
        local nearestDistance = Config.InteractionDistance

        for pumpId, pump in pairs(placedPumps) do
            if pump and pump.object and DoesEntityExist(pump.object) then
                local pumpCoords = GetEntityCoords(pump.object)
                local dist = #(playerCoords - pumpCoords)

                if dist < nearestDistance then
                    nearPump = true
                    nearestPumpId = pumpId
                    nearestDistance = dist
                end
            end
        end

        if nearPump and nearestPumpId and not isPlacing and not isFilling then
            currentPumpId = nearestPumpId
            
           
            local PumpGroupName = CreateVarString(10, 'LITERAL_STRING', "Water Pump")
            PromptSetActiveGroupThisFrame(PumpPromptGroup, PumpGroupName)

            
            if PromptHasHoldModeCompleted(FillBottlePrompt) then
                PromptSetEnabled(FillBottlePrompt, false)
                FillBottle(currentPumpId)
                Wait(500)
                PromptSetEnabled(FillBottlePrompt, true)
            end

            
            if PromptHasHoldModeCompleted(PickupPumpPrompt) then
                PromptSetEnabled(PickupPumpPrompt, false)
                PickupPump(currentPumpId)
                Wait(500)
                PromptSetEnabled(PickupPumpPrompt, true)
            end
        else
            currentPumpId = nil
        end

        Wait(0)
    end
end)



function FillBottle(pumpId)
    local pump = placedPumps[pumpId]
    if not pump then return end
    
   
    if isFilling then
        return
    end
    
    
    isFilling = true
    
    RSGCore.Functions.TriggerCallback('rsg-waterpump:server:hasEmptyBottle', function(hasBottle, amount)
        if not hasBottle then
            
            isFilling = false
            lib.notify({
                title = 'Water Pump',
                description = 'You need an empty bottle',
                type = 'error'
            })
            return
        end
        
        local pumpCoords = GetEntityCoords(pump.object)
        
        PlayFillBottleAnimation(pumpCoords, function(success)
           
            isFilling = false
            
            if success then
                TriggerServerEvent('rsg-waterpump:server:fillBottle', pumpId)
            else
                lib.notify({
                    title = 'Water Pump',
                    description = 'Cancelled',
                    type = 'error'
                })
            end
        end)
    end)
end

function PickupPump(pumpId)
    local pump = placedPumps[pumpId]
    if not pump then return end
    
   
    if isFilling then return end
    
    
    isFilling = true
    
    local pumpCoords = GetEntityCoords(pump.object)
    
    PlayPickupAnimation(pumpCoords, function(success)
        
        isFilling = false
        
        if success then
            TriggerServerEvent('rsg-waterpump:server:pickupPump', pumpId)
        else
            lib.notify({
                title = 'Water Pump',
                description = 'Cancelled',
                type = 'error'
            })
        end
    end)
end


CreateThread(function()
    Wait(2000)
    TriggerServerEvent('rsg-waterpump:server:requestPumps')
end)

RegisterNetEvent('rsg-waterpump:client:loadPumps', function(pumps)
   
    for id, pump in pairs(placedPumps) do
        if pump and pump.object and DoesEntityExist(pump.object) then
            DeleteObject(pump.object)
        end
    end
    placedPumps = {}
    
    if pumps then
        for id, pump in pairs(pumps) do
            SpawnPump(id, pump)
        end
    end
end)

function SpawnPump(pumpId, pumpData)
    local hash = LoadModel(Config.PumpModel)
    if not hash then return end
    
    local pumpObject = CreateObject(hash, pumpData.x, pumpData.y, pumpData.z, false, false, false)
    
    
    local pumpHeading = pumpData.heading or 0.0
    local pumpPitch = pumpData.pitch or 0.0
    local pumpRoll = pumpData.roll or 0.0
    
    if pumpPitch ~= 0 or pumpRoll ~= 0 then
        SetEntityRotation(pumpObject, pumpPitch, pumpRoll, pumpHeading, 2, false)
    else
        PlaceObjectOnGroundProperly(pumpObject)
        SetEntityHeading(pumpObject, pumpHeading)
    end
    
    FreezeEntityPosition(pumpObject, true)
    
    placedPumps[pumpId] = {
        object = pumpObject,
        coords = vector3(pumpData.x, pumpData.y, pumpData.z)
    }
end

RegisterNetEvent('rsg-waterpump:client:syncNewPump', function(pumpId, pumpData)
    if placedPumps[pumpId] then return end
    SpawnPump(pumpId, pumpData)
end)

RegisterNetEvent('rsg-waterpump:client:removePump', function(pumpId)
    if placedPumps[pumpId] then
        if DoesEntityExist(placedPumps[pumpId].object) then
            DeleteObject(placedPumps[pumpId].object)
        end
        placedPumps[pumpId] = nil
    end
end)



AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        isPlacing = false
        isFilling = false
        
        for _, pump in pairs(placedPumps) do
            if pump and pump.object and DoesEntityExist(pump.object) then
                DeleteObject(pump.object)
            end
        end
        
        placedPumps = {}
    end
end)