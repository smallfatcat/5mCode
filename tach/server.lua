RegisterServerEvent("storeCheckpoint")
RegisterServerEvent("getCheckpoints")

AddEventHandler("storeCheckpoint", function(checkpoint, order)
    --print(tostring(checkpoint))
    MySQL.ready(function ()
        MySQL.Async.execute(
            "INSERT INTO checkpoints (raceID, checkpointOrder, leftX, leftY, leftZ, rightX, rightY, rightZ, mpX, mpY, mpZ)"..
            " VALUES(@raceID, @checkpointOrder, @leftX, @leftY, @leftZ, @rightX, @rightY, @rightZ, @mpX, @mpY, @mpZ)",     
            {["@raceID"] = 1,
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
            --TriggerClientEvent("output", source, result)
        end)
    end)
end)

RegisterCommand("save", function(source, args)
    print("triggered")
    MySQL.ready(function ()
        MySQL.Async.execute("INSERT INTO races (raceID, laps) VALUES(@raceID, @laps)",     
        {["@raceID"] = args[1], ["@laps"] = args[2]},
        function (result)
            print(result)
            --TriggerClientEvent("output", source, result)
        end)
    end)
end)


