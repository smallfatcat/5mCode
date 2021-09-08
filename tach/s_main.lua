RegisterServerEvent("storeCheckpoint")
RegisterServerEvent("getCheckpoints")
RegisterServerEvent("storeCheckpointTime")
RegisterServerEvent("storeLapTime")

AddEventHandler("getCheckpoints", function(raceID)
    print("source = "..source)
    local replyTo = source
    MySQL.ready(function ()
        MySQL.Async.fetchAll(
            "SELECT * FROM checkpoints WHERE raceID = @raceID ORDER BY checkpointOrder",     
            {["@raceID"] = raceID},
        function (result)
            TriggerClientEvent("rcvCheckpoints", replyTo, result)
        end)
    end)
end)

AddEventHandler("storeCheckpoint", function(checkpoint, order, raceID)
    --print(tostring(checkpoint))
    local replyTo = source
    MySQL.ready(function ()
        MySQL.Async.execute(
            "INSERT INTO checkpoints (raceID, checkpointOrder, leftX, leftY, leftZ, rightX, rightY, rightZ, mpX, mpY, mpZ)"..
            " VALUES(@raceID, @checkpointOrder, @leftX, @leftY, @leftZ, @rightX, @rightY, @rightZ, @mpX, @mpY, @mpZ)",     
            {["@raceID"] = raceID,
            ["@checkpointOrder"] = order,
            ["@leftX"] = checkpoint.left.x,
            ["@leftY"] = checkpoint.left.y,
            ["@leftZ"] = checkpoint.left.z,
            ["@rightX"] = checkpoint.right.x,
            ["@rightY"] = checkpoint.right.y,
            ["@rightZ"] = checkpoint.right.z,
            ["@mpX"] = checkpoint.midpoint.x,
            ["@mpY"] = checkpoint.midpoint.y,
            ["@mpZ"] = checkpoint.midpoint.z},
        function (result)
            print(result)
            --TriggerClientEvent("output", replyTo, result)
        end)
    end)
end)

AddEventHandler("storeCheckpointTime", function(cpTimeObj)
    --print(tostring(checkpoint))
    local replyTo = source
    MySQL.ready(function ()
        MySQL.Async.execute(
            "INSERT INTO cptimes (checkpointID, raceID, driverID, eventID, time, lap)"..
            " VALUES(@checkpointID, @raceID, @driverID, @eventID, @time, @lap)",     
            {
                ["@checkpointID"] = cpTimeObj.checkpointID,
                ["@raceID"] = cpTimeObj.raceID,
                ["@driverID"] = cpTimeObj.driverID,
                ["@eventID"] = cpTimeObj.eventID,
                ["@time"] = cpTimeObj.time,
                ["@lap"] = cpTimeObj.lap
            },
            function (result)
                print(result)
                TriggerClientEvent("cptStatus", replyTo, result)
        end)
    end)
end)

AddEventHandler("storeLapTime", function(lapTimeObj)
    --print(tostring(checkpoint))
    local replyTo = source
    MySQL.ready(function ()
        MySQL.Async.execute(
            "INSERT INTO laptimes (lapID, raceID, driverID, eventID, time)"..
            " VALUES(@lapID, @raceID, @driverID, @eventID, @time)",     
            {
                ["@lapID"] = lapTimeObj.lapID,
                ["@raceID"] = lapTimeObj.raceID,
                ["@driverID"] = lapTimeObj.driverID,
                ["@eventID"] = lapTimeObj.eventID,
                ["@time"] = lapTimeObj.time,
            },
            function (result)
                print(result)
                TriggerClientEvent("laptStatus", replyTo, result)
        end)
    end)
end)

RegisterCommand("save", function(source, args)
    print("save triggered by:"..source)
    MySQL.ready(function ()
        MySQL.Async.execute("INSERT INTO races (raceID, laps) VALUES(@raceID, @laps)",     
        {["@raceID"] = args[1], ["@laps"] = args[2]},
        function (result)
            print(result)
            --TriggerClientEvent("output", source, result)
        end)
    end)
end)


