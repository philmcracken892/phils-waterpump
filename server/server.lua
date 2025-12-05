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
                placed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
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
                heading = pump.heading
            }
        end
        
    else
        
    end
end


RegisterNetEvent('rsg-waterpump:server:requestPumps', function()
    local src = source
    TriggerClientEvent('rsg-waterpump:client:loadPumps', src, allPumps)
end)


RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    Wait(3000)
    TriggerClientEvent('rsg-waterpump:client:loadPumps', src, allPumps)
end)


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
    
    playerPumps[citizenid] = playerPumps[citizenid] + 1
    
    
    if Config.SavePumps then
        MySQL.insert('INSERT INTO waterpumps (owner, x, y, z, heading) VALUES (?, ?, ?, ?, ?)', {
            citizenid,
            coords.x,
            coords.y,
            coords.z,
            coords.heading
        }, function(id)
            if id then
                allPumps[id] = {
                    id = id,
                    owner = citizenid,
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = coords.heading
                }
                
                
                TriggerClientEvent('rsg-waterpump:client:syncNewPump', -1, id, allPumps[id])
                
               
            end
        end)
    end
end)


RegisterNetEvent('rsg-waterpump:server:usePump', function(pumpId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Water Pump',
        description = 'You used the water pump',
        type = 'success'
    })
end)


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
    
    
    Player.Functions.AddItem(Config.PumpItem, 1)
    
    
    if Config.SavePumps then
        MySQL.query('DELETE FROM waterpumps WHERE id = ?', {pumpId})
    end
    
    
    allPumps[pumpId] = nil
    
    
    if playerPumps[citizenid] and playerPumps[citizenid] > 0 then
        playerPumps[citizenid] = playerPumps[citizenid] - 1
    end
    
    
    TriggerClientEvent('rsg-waterpump:client:removePump', -1, pumpId)
    
    
end)


if Config.SavePumps and Config.PumpLifetime > 0 then
    CreateThread(function()
        while true do
            Wait(3600000)
            local deleted = MySQL.query.await('DELETE FROM waterpumps WHERE placed_at < DATE_SUB(NOW(), INTERVAL ? HOUR)', {
                Config.PumpLifetime
            })
            if deleted and deleted.affectedRows > 0 then
                
                allPumps = {}
                LoadPumpsFromDatabase()
                TriggerClientEvent('rsg-waterpump:client:loadPumps', -1, allPumps)
            end
        end
    end)
end