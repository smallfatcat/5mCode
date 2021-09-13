RegisterServerEvent("storeCheckpoint")
RegisterServerEvent("getCheckpoints")
RegisterServerEvent("storeCheckpointTime")
RegisterServerEvent("storeLapTime")
RegisterServerEvent("setupNewRace")

function getEventID()
    MySQL.ready(function ()
        MySQL.Async.fetchAll(
            "SELECT eventID FROM raceevent ORDER BY eventID DESC LIMIT 1",     
            {},
        function (result)
            nextEventID =  result[1].eventID + 1
        end)
    end)
end

function getTrackID()
    MySQL.ready(function ()
        MySQL.Async.fetchAll(
            "SELECT trackID FROM tracks ORDER BY trackID DESC LIMIT 1",     
            {},
        function (result)
            nextTrackID =  result[1].trackID + 1
        end)
    end)
end

raceObject = {}

nextEventID = 0
nextTrackID = 0

-- Fudge timer to allow MySQL object time to set up, doesn't seem to work as expected on resource restart but still works?
Citizen.SetTimeout(10000, function()
    print(tostring("Timer"))
    nextEventID = getEventID()
    nextTrackID = getTrackID()
end)

AddEventHandler("setupNewRace", function(raceEvent)
    raceObject.trackID = raceEvent.trackID
    raceObject.laps = raceEvent.laps
    raceObject.eventID = nextEventID
    nextEventID = nextEventID + 1
    print("source = "..source)
    local replyTo = source
    TriggerClientEvent("rcvNewRace", replyTo, raceObject)
    --[[ MySQL.ready(function ()
        MySQL.Async.fetchAll(
            "SELECT eventID FROM raceevent ORDER BY eventID DESC LIMIT 1",     
            {},
        function (result)
            --print("result.eventID:"..tostring(result[1].eventID))
            TriggerClientEvent("rcvNextEventID", replyTo, result)
        end)
    end) ]]
end)

AddEventHandler("getCheckpoints", function(trackID)
    print("source = "..source)
    local replyTo = source
    MySQL.ready(function ()
        MySQL.Async.fetchAll(
            "SELECT * FROM checkpoints WHERE trackID = @trackID ORDER BY checkpointOrder",     
            {["@trackID"] = trackID},
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

--playerConnecting(playerName: string, setKickReason: (reason: string) => void, deferrals: { defer: any; done: any; handover: any; presentCard: any; update: any }, source: string): void

AddEventHandler('playerConnecting', function(playerName)
    print("playerName:"..(playerName and playerName or "none"))
    print("source:"..source)
    local steamid  = false
    local license  = false
    local discord  = false
    local xbl      = false
    local liveid   = false
    local ip       = false

    for k,v in pairs(GetPlayerIdentifiers(source))do
        print(v)
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
        steamid = v
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
        license = v
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
        xbl  = v
        elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
        ip = v
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
        discord = v
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
        liveid = v
        end
    end
end)

AddEventHandler('playerJoining', function()
    print("source:"..source)
    print("oldID:"..(oldID and oldID or "none"))
end)

AddEventHandler('startProjectileEvent', function(sender, data)
    print("data.initialPositionX:"..data.initialPositionX)
end)

--[[ AddEventHandler('entityCreated', function(handle)
    print("handle:"..(handle and handle or "none"))
end) ]]


