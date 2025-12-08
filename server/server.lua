local RSGCore = exports['rsg-core']:GetCoreObject()
local playerPumps = {}
local allPumps = {}


CreateThread(function()
    if Config.SavePumps then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS waterpumps (
                id INT AUTO_INCREMENT PRIMARY KEY,
                owner VARCHAR(50),
                x FLOAT,
                y FLOAT,
                z FLOAT,
                heading FLOAT,
                pitch FLOAT DEFAULT 0,
                roll FLOAT DEFAULT 0,
                placed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]])
        
        
        MySQL.query([[
            ALTER TABLE waterpumps 
            ADD COLUMN IF NOT EXISTS pitch FLOAT DEFAULT 0,
            ADD COLUMN IF NOT EXISTS roll FLOAT DEFAULT 0
        ]])
        
        Wait(1000)
        LoadPumpsFromDatabase()
    end
end)

function LoadPumpsFromDatabase()
    local result = MySQL.query.await('SELECT * FROM waterpumps', {})
    if result and #result > 0 then
        for i = 1, #result do
            local pump = result[i]
            allPumps[pump.id] = {
                id = pump.id,
                owner = pump.owner,
                x = pump.x,
                y = pump.y,
                z = pump.z,
                heading = pump.heading,
                pitch = pump.pitch or 0,
                roll = pump.roll or 0
            }
        end
        
    end
end

-- Request pumps
RegisterNetEvent('rsg-waterpump:server:requestPumps', function()
    local src = source
    TriggerClientEvent('rsg-waterpump:client:loadPumps', src, allPumps)
end)

-- Player loaded
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    Wait(3000)
    TriggerClientEvent('rsg-waterpump:client:loadPumps', src, allPumps)
end)

-- Useable pump item
RSGCore.Functions.CreateUseableItem(Config.PumpItem, function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if not playerPumps[citizenid] then
        playerPumps[citizenid] = 0
    end
    
    if playerPumps[citizenid] >= Config.MaxPumpsPerPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'You have reached the maximum number of pumps (' .. Config.MaxPumpsPerPlayer .. ')',
            type = 'error'
        })
        return
    end
    
    TriggerClientEvent('rsg-waterpump:client:startPlacement', src)
end)

-- Place pump (with pitch and roll)
RegisterNetEvent('rsg-waterpump:server:placePump', function(coords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if not playerPumps[citizenid] then
        playerPumps[citizenid] = 0
    end
    
    if playerPumps[citizenid] >= Config.MaxPumpsPerPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'You have reached the maximum number of pumps',
            type = 'error'
        })
        return
    end
    
    if not Player.Functions.RemoveItem(Config.PumpItem, 1) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'You don\'t have a water pump',
            type = 'error'
        })
        return
    end
    
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.PumpItem], 'remove', 1)
    
    playerPumps[citizenid] = playerPumps[citizenid] + 1
    
    if Config.SavePumps then
        MySQL.insert('INSERT INTO waterpumps (owner, x, y, z, heading, pitch, roll) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            citizenid,
            coords.x,
            coords.y,
            coords.z,
            coords.heading,
            coords.pitch or 0,
            coords.roll or 0
        }, function(id)
            if id then
                allPumps[id] = {
                    id = id,
                    owner = citizenid,
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = coords.heading,
                    pitch = coords.pitch or 0,
                    roll = coords.roll or 0
                }
                
                TriggerClientEvent('rsg-waterpump:client:syncNewPump', -1, id, allPumps[id])
            end
        end)
    end
end)

-- Fill bottle with water
RegisterNetEvent('rsg-waterpump:server:fillBottle', function(pumpId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if not allPumps[pumpId] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'Pump not found',
            type = 'error'
        })
        return
    end
    
    if Config.RequireEmptyBottle then
        local hasBottle = Player.Functions.GetItemByName(Config.EmptyBottleItem)
        
        if not hasBottle or hasBottle.amount < 1 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Water Pump',
                description = 'You need an empty bottle',
                type = 'error'
            })
            return
        end
        
        if not Player.Functions.RemoveItem(Config.EmptyBottleItem, 1) then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Water Pump',
                description = 'Failed to remove empty bottle',
                type = 'error'
            })
            return
        end
        
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.EmptyBottleItem], 'remove', 1)
    end
    
    if Player.Functions.AddItem(Config.WaterItem, Config.WaterPerFill) then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.WaterItem], 'add', Config.WaterPerFill)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'You filled a bottle with water',
            type = 'success'
        })
    else
        if Config.RequireEmptyBottle then
            Player.Functions.AddItem(Config.EmptyBottleItem, 1)
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'Your inventory is full',
            type = 'error'
        })
    end
end)

-- Check if player has empty bottle
RSGCore.Functions.CreateCallback('rsg-waterpump:server:hasEmptyBottle', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then 
        cb(false, 0)
        return 
    end
    
    if not Config.RequireEmptyBottle then
        cb(true, 999)
        return
    end
    
    local hasBottle = Player.Functions.GetItemByName(Config.EmptyBottleItem)
    
    if hasBottle and hasBottle.amount > 0 then
        cb(true, hasBottle.amount)
    else
        cb(false, 0)
    end
end)



-- Pickup pump
RegisterNetEvent('rsg-waterpump:server:pickupPump', function(pumpId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    if not allPumps[pumpId] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'Pump not found',
            type = 'error'
        })
        return
    end
    
    if allPumps[pumpId].owner ~= citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'You do not own this pump',
            type = 'error'
        })
        return
    end
    
    if Player.Functions.AddItem(Config.PumpItem, 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.PumpItem], 'add', 1)
        
        if Config.SavePumps then
            MySQL.query('DELETE FROM waterpumps WHERE id = ?', {pumpId})
        end
        
        allPumps[pumpId] = nil
        
        if playerPumps[citizenid] and playerPumps[citizenid] > 0 then
            playerPumps[citizenid] = playerPumps[citizenid] - 1
        end
        
        TriggerClientEvent('rsg-waterpump:client:removePump', -1, pumpId)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'Pump picked up',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Water Pump',
            description = 'Inventory full',
            type = 'error'
        })
    end
end)

-- Cleanup old pumps
if Config.SavePumps and Config.PumpLifetime > 0 then
    CreateThread(function()
        while true do
            Wait(3600000)
            local deleted = MySQL.query.await('DELETE FROM waterpumps WHERE placed_at < DATE_SUB(NOW(), INTERVAL ? HOUR)', {
                Config.PumpLifetime
            })
            if deleted and deleted.affectedRows > 0 then
                print('[rsg-waterpump] Cleaned up ' .. deleted.affectedRows .. ' old pumps')
                allPumps = {}
                LoadPumpsFromDatabase()
                TriggerClientEvent('rsg-waterpump:client:loadPumps', -1, allPumps)
            end
        end
    end)
end