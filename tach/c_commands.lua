RegisterCommand('tyres', function(source, args)
    for i, cp in ipairs(race.checkpoints) do
        spawnTyre(cp.left)
        spawnTyre(cp.right)
        --spawnTyre(cp.midpoint)
        print("cp.midpoint"..cp.midpoint)
    end
end)

RegisterCommand('tpr', function(source, args)
    local lastCP = race.checkpoints[#race.checkpoints]
    SetPedCoordsKeepVehicle(PlayerPedId(), lastCP.midpoint.x, lastCP.midpoint.y, lastCP.midpoint.z)
end)

RegisterCommand('setmp', function(source, args)
    cpToUpdate = tonumber(args[1])
    race.checkpoints[cpToUpdate].midpoint = GetEntityCoords(GetPlayerPed(-1), false)
end)

-- store race.checkpoints in database
RegisterCommand('scp', function(source, args)
    storeCheckpointsToDB(args[1] and args[1] or -1)
end)

-- retrieve race.checkpoints from database
RegisterCommand('getcp', function(source, args)
    getCheckPointsFromDB(args[1] and args[1] or 1)
end)

-- Reset race.checkpoints
RegisterCommand('rcp', function(source, args)
    resetCheckpoints()
end)

-- Delete race.checkpoints
RegisterCommand("dcp", function(source, args)
    removeBlipsFromCheckpoints()
    race.checkpoints = {}
    resetCheckpoints()
end)

RegisterCommand("pos", function(source)
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
    outputString = "X: " .. x .." Y: " .. y .." Z: " .. z
    TriggerEvent("chatMessage", "[GPS]", {0,255,0}, outputString)
end)

RegisterCommand('edit', function(source, args)
    if args[1] == "on" then
        editCP.active = true
    else
        editCP.active = false
    end
end)

--------------------------------------
-- test db function
RegisterCommand('testDB', function(source, args)
    local cpTimeObj = {
        checkpointID = 2,
        raceID = 3,
        driverID = 4,
        eventID = 5,
        time = 16.234
    }
    storeCheckpointTimeToDB(cpTimeObj)
end)