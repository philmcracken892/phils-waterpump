local RSGCore = exports['rsg-core']:GetCoreObject()
local placedPumps = {}
local isPlacing = false
local previewObject = nil


local function LoadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end


local function CreatePreviewObject()
    local hash = LoadModel(Config.PumpModel)
    local coords = GetEntityCoords(PlayerPedId())
    
    previewObject = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(previewObject, 150, false)
    SetEntityCollision(previewObject, false, false)
    SetEntityInvincible(previewObject, true)
    
    return previewObject
end


local function UpdatePreviewPosition()
    if not previewObject then return nil, nil, nil, false end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local x = coords.x + forward.x * Config.PlacementDistance
    local y = coords.y + forward.y * Config.PlacementDistance
    local z = coords.z
    
    
    local retval, groundZ = GetGroundZFor_3dCoord(x, y, z + 10.0, false)
    if retval then
        z = groundZ
    end
    
    SetEntityCoords(previewObject, x, y, z, false, false, false, false)
    SetEntityHeading(previewObject, GetEntityHeading(playerPed))
    
   
    local canPlace = IsPositionValid(x, y, z)
    if canPlace then
        SetEntityAlpha(previewObject, 200, false)
    else
        SetEntityAlpha(previewObject, 100, false)
    end
    
    return x, y, z, canPlace
end


function IsPositionValid(x, y, z)
    for _, pump in pairs(placedPumps) do
        if pump and pump.object and DoesEntityExist(pump.object) then
            local pumpCoords = GetEntityCoords(pump.object)
            if #(vector3(x, y, z) - pumpCoords) < 2.0 then
                return false
            end
        end
    end
    
    local retval, _ = GetGroundZFor_3dCoord(x, y, z + 10.0, false)
    return retval
end


RegisterNetEvent('rsg-waterpump:client:startPlacement', function()
    if isPlacing then return end
    PlaceWaterPump()
end)


function PlaceWaterPump()
    isPlacing = true
    CreatePreviewObject()
    
    lib.showTextUI('[E] Place Pump | [BACKSPACE] Cancel', {
        position = 'top-center'
    })
    
    CreateThread(function()
        while isPlacing do
            Wait(0)
            local x, y, z, canPlace = UpdatePreviewPosition()
            
            if x == nil then
                isPlacing = false
                break
            end
            
           
            if IsControlJustPressed(0, 0xCEFD9220) then
                if canPlace then
                    isPlacing = false
                    
                    if previewObject and DoesEntityExist(previewObject) then
                        DeleteObject(previewObject)
                        previewObject = nil
                    end
                    
                    lib.hideTextUI()
                    
                    local heading = GetEntityHeading(PlayerPedId())
                    
                    
                    TriggerServerEvent('rsg-waterpump:server:placePump', {
                        x = x,
                        y = y,
                        z = z,
                        heading = heading
                    })
                    
                    lib.notify({
                        title = 'Water Pump',
                        description = 'Pump placed successfully',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Water Pump',
                        description = 'Cannot place pump here',
                        type = 'error'
                    })
                end
            end
  
            if IsControlJustPressed(0, 0x156F7119) then
                isPlacing = false
                
                if previewObject and DoesEntityExist(previewObject) then
                    DeleteObject(previewObject)
                    previewObject = nil
                end
                
                lib.hideTextUI()
                
                lib.notify({
                    title = 'Water Pump',
                    description = 'Placement cancelled',
                    type = 'info'
                })
            end
        end
    end)
end


function AddPumpTarget(pumpObject, pumpId)
    exports.ox_target:addLocalEntity(pumpObject, {
        
        {
            name = 'pickup_pump_' .. pumpId,
            label = 'Pick Up Pump',
            icon = 'fas fa-hand-rock',
            distance = Config.InteractionDistance,
            onSelect = function()
                PickupPump(pumpId)
            end
        }
    })
end


function UsePump(pumpId)
    local pump = placedPumps[pumpId]
    if not pump then return end
    
    local playerPed = PlayerPedId()
    local pumpCoords = GetEntityCoords(pump.object)
    local playerCoords = GetEntityCoords(playerPed)
    
    local heading = GetHeadingFromVector_2d(pumpCoords.x - playerCoords.x, pumpCoords.y - playerCoords.y)
    SetEntityHeading(playerPed, heading)
    
    local success = lib.progressBar({
        duration = 5000,
        label = 'Using water pump...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            sprint = true
        }
    })
    
    if success then
        TriggerServerEvent('rsg-waterpump:server:usePump', pumpId)
    else
        lib.notify({
            title = 'Water Pump',
            description = 'Cancelled',
            type = 'error'
        })
    end
end


function PickupPump(pumpId)
    local pump = placedPumps[pumpId]
    if not pump then return end
    
    local playerPed = PlayerPedId()
    local pumpCoords = GetEntityCoords(pump.object)
    local playerCoords = GetEntityCoords(playerPed)
    
    local heading = GetHeadingFromVector_2d(pumpCoords.x - playerCoords.x, pumpCoords.y - playerCoords.y)
    SetEntityHeading(playerPed, heading)
    
    local success = lib.progressBar({
        duration = 3000,
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
    
    if success then
        TriggerServerEvent('rsg-waterpump:server:pickupPump', pumpId)
    else
        lib.notify({
            title = 'Water Pump',
            description = 'Cancelled',
            type = 'error'
        })
    end
end


CreateThread(function()
    Wait(2000)
    TriggerServerEvent('rsg-waterpump:server:requestPumps')
end)


RegisterNetEvent('rsg-waterpump:client:loadPumps', function(pumps)
    for id, pump in pairs(placedPumps) do
        if pump and pump.object and DoesEntityExist(pump.object) then
            exports.ox_target:removeLocalEntity(pump.object)
            DeleteObject(pump.object)
        end
    end
    placedPumps = {}
    
    if pumps then
        for id, pump in pairs(pumps) do
            local hash = LoadModel(Config.PumpModel)
            local pumpObject = CreateObject(hash, pump.x, pump.y, pump.z, false, false, false)
            PlaceObjectOnGroundProperly(pumpObject)
            SetEntityHeading(pumpObject, pump.heading or 0.0)
            FreezeEntityPosition(pumpObject, true)
            
            placedPumps[id] = {
                object = pumpObject,
                coords = vector3(pump.x, pump.y, pump.z)
            }
            
            AddPumpTarget(pumpObject, id)
        end
    end
end)


RegisterNetEvent('rsg-waterpump:client:syncNewPump', function(pumpId, pumpData)
    if placedPumps[pumpId] then return end
    
    local hash = LoadModel(Config.PumpModel)
    local pumpObject = CreateObject(hash, pumpData.x, pumpData.y, pumpData.z, false, false, false)
    PlaceObjectOnGroundProperly(pumpObject)
    SetEntityHeading(pumpObject, pumpData.heading or 0.0)
    FreezeEntityPosition(pumpObject, true)
    
    placedPumps[pumpId] = {
        object = pumpObject,
        coords = vector3(pumpData.x, pumpData.y, pumpData.z)
    }
    
    AddPumpTarget(pumpObject, pumpId)
end)


RegisterNetEvent('rsg-waterpump:client:removePump', function(pumpId)
    if placedPumps[pumpId] then
        if DoesEntityExist(placedPumps[pumpId].object) then
            exports.ox_target:removeLocalEntity(placedPumps[pumpId].object)
            DeleteObject(placedPumps[pumpId].object)
        end
        placedPumps[pumpId] = nil
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isPlacing then
            lib.hideTextUI()
        end
        
        for _, pump in pairs(placedPumps) do
            if pump and pump.object and DoesEntityExist(pump.object) then
                DeleteObject(pump.object)
            end
        end
        
        if previewObject and DoesEntityExist(previewObject) then
            DeleteObject(previewObject)
        end
    end
end)