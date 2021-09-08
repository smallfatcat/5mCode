print("Loaded Tach")
RegisterNetEvent("output")
RegisterNetEvent("rcvCheckpoints")

AddEventHandler("output", function(result)
    print(tostring(result[1].checkpointOrder))
    TriggerEvent("chatMessage", "output:", {0,255,0}, #result)
end)

AddEventHandler("rcvCheckpoints", function(result)
    print("Got "..#result.." results")
    local newCheckpoints = {}
    for i, cp in ipairs(result) do
        local newCP = {}
        newCP.left = vector3(cp.leftX,cp.leftY,cp.leftZ)
        newCP.right = vector3(cp.rightX,cp.rightY,cp.rightZ)
        newCP.midpoint = vector3(cp.mpX,cp.mpY,cp.mpZ)
        newCP.state = false
        table.insert(newCheckpoints, newCP)
    end
    removeBlipsFromCheckpoints()
    race.checkpoints = newCheckpoints
    resetCheckpoints()
end)

function timeTxt(mstime)
    local minutes = math.floor(mstime/60000)
    local seconds = (mstime % 60000)/1000
    local prefix = ""
    local minuteTxt = ""
    if minutes > 0 then minuteTxt = tostring(minutes).."\'" end
    if seconds < 10 and minutes > 0 then prefix = "0" end
    return minuteTxt..prefix..tostring(seconds).."\""
end

-- timer vars
limitBottom = 1.0
limitA = 60.0
limitB = 100.0
limitC = 140.0
limitdistA = 402.336
timerWaitingToEnd   = false
timerWaitingToStart = false
timerVisible = false
timerRunning = false
speedTimerRunning = false
timerFlagA = true
timerFlagB = true
timerFlagC = true
timerDistFlagA = true
timerStart   = 0
timerEnd     = 0
timer        = 0
timeA        = 0.0
timeB        = 0.0
timeC        = 0.0
timeDistA = 0.0
timeTop      = 0.0
startX = 0.0
startY = 0.0
startZ = 0.0
distanceFromStart = 0.0

-- player vars
player = {lastPos = GetEntityCoords(GetPlayerPed(-1), false)}

-- race vars
race = {laps = 3, currentLap = 1, currentCP = 1, checkpoints = {}, raceTimer = 0, raceTimerStart = GetGameTimer(), lapTimes = {}}

-- ui vars
editCP = {editMode = 0, active = false}

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

function storeCheckpointsToDB(raceID)
    for i, cp in ipairs(race.checkpoints) do
        --local raceID = 2
        TriggerServerEvent("storeCheckpoint", cp, i, raceID)
    end
end

-- retrieve race.checkpoints from database
RegisterCommand('getcp', function(source, args)
    getCheckPointsFromDB(args[1] and args[1] or 1)
end)

function getCheckPointsFromDB(raceID)
    --local raceID = 2
    --local playerID = PlayerPedId()
    TriggerServerEvent("getCheckpoints",raceID)
end

-- Reset race.checkpoints
RegisterCommand('rcp', function(source, args)
    resetCheckpoints()
end)

function resetCheckpoints()
    for i, cp in ipairs(race.checkpoints) do
        cp.state = false
        cp.times = {}
        cp.splitTimes = {}
        cp.blip = AddBlipForCoord(cp.midpoint.x, cp.midpoint.y, cp.midpoint.z)
        --SetBlipRoute(cp.blip, true)
        if i == #race.checkpoints then
            SetBlipSprite(cp.blip, 309)
        else
            --SetBlipColour(cp.blip, 2)
            SetBlipScale(cp.blip, 0.5)
	        SetBlipSprite(cp.blip, 145)
        end
        
    end
    race.lapTimes = {}
    race.raceTimerStart = GetGameTimer()
    race.laps = 3
    race.currentLap = 1
    race.currentCP = 1
    race.active = true
    race.lastCPTime = 0
    race.lastLapTime = 0
    race.totalTime = 0
    showRoute()
end

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

function removeBlipsFromCheckpoints()
    for i, cp in ipairs(race.checkpoints) do
        RemoveBlip(cp.blip) 
    end
end

function showRoute()
    -- Clear any old route first
    ClearGpsMultiRoute()
    StartGpsMultiRoute(6, false, true)
    if #race.checkpoints ~= 0 then
        -- Start a new route
        
        -- Add the points
        if race.currentCP == 1 then
            AddPointToGpsMultiRoute(race.checkpoints[#race.checkpoints].midpoint.x, race.checkpoints[#race.checkpoints].midpoint.y, race.checkpoints[#race.checkpoints].midpoint.z)
        end
        local tempVal = 0
        for j = 1, race.laps do
            for i, cp in ipairs(race.checkpoints) do
                if (j == race.currentLap and (i+1) >= race.currentCP) or j > race.currentLap then
                    AddPointToGpsMultiRoute(cp.midpoint.x, cp.midpoint.y, cp.midpoint.z)
                    tempVal = tempVal + 1
                end
            end
        end
        print("route points set: "..tempVal)
        -- Set the route to render
        SetGpsMultiRouteRender(true)
    else
        SetGpsMultiRouteRender(false)
    end
end

function get_intersection (ax, ay, bx, by, cx, cy, dx, dy) -- start end start end
    local d = (ax-bx)*(cy-dy)-(ay-by)*(cx-dx)
    if d == 0 then return end  -- they are parallel
    local a, b = ax*by-ay*bx, cx*dy-cy*dx
    local x = (a*(cx-dx) - b*(ax-bx))/d
    local y = (a*(cy-dy) - b*(ay-by))/d
    if x <= math.max(ax, bx) and x >= math.min(ax, bx) and
        x <= math.max(cx, dx) and x >= math.min(cx, dx) then
        -- between start and end of both lines
        return {x=x, y=y}
    end
end

function drawCPLine(a, b)
    DrawLine(
        a.x --[[ number ]], 
        a.y --[[ number ]], 
        a.z --[[ number ]], 
        b.x --[[ number ]], 
        b.y --[[ number ]], 
        b.z --[[ number ]], 
        255 --[[ integer ]], 
        0 --[[ integer ]], 
        0 --[[ integer ]], 
        255 --[[ integer ]]
    )
end

--[[ local line1start, line1end = {x = 4, y = 0}, {x = 6, y = 10}
local line2start, line2end = {x = 0, y = 3}, {x = 10, y = 7}
print(intersection(line1start, line1end, line2start, line2end)) ]]

function raceTimeTextBox(text, offsetX, offsetY, highlight) 
    SetTextFont(4)
    SetTextProportional(0)
    if highlight then
        SetTextColour(0,255,0,255)
    else
        --SetTextColour(255,255,0,255)
    end
    SetTextScale(0.5,0.5)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(
        tostring(text)
    )
    DrawText(0.8 + offsetX, 0.60 + offsetY)
end

function UI_Race()
    --update race.raceTimer
    if race.active then
        race.raceTimer = GetGameTimer() - race.raceTimerStart
    end

    -- draw race info
    raceTimeTextBox("Lap: "..tostring(race.currentLap).."/"..tostring(race.laps), -0.01, -0.04, false)
    raceTimeTextBox("Timer: "..timeTxt(race.raceTimer), -0.01, -0.02, false)
    raceTimeTextBox("Checkpoint: "..tostring(race.currentCP).."/"..tostring(#race.checkpoints), -0.01, 0, false)
    for i,cp in ipairs(race.checkpoints) do
        -- draw checkpoint line for debug
        drawCPLine(cp.left, cp.right)
        
        -- update blips for race.checkpoints
        if race.currentCP == i then
            RemoveBlip(cp.blip)
            cp.blip = AddBlipForCoord(cp.midpoint.x, cp.midpoint.y, cp.midpoint.z)
            if i == #race.checkpoints then
                SetBlipSprite(cp.blip, 309)
            else
                SetBlipScale(cp.blip, 1.0)
                SetBlipSprite(cp.blip, 1)
                SetBlipColour(cp.blip, 2)
            end
        else
            RemoveBlip(cp.blip)
            cp.blip = AddBlipForCoord(cp.midpoint.x, cp.midpoint.y, cp.midpoint.z)
            if i == #race.checkpoints then
                SetBlipSprite(cp.blip, 309)
            else
                SetBlipScale(cp.blip, 1.0)
                SetBlipSprite(cp.blip, 1)
                SetBlipColour(cp.blip, 3)
            end
        end

        -- draw sector times
        local offsetY = i/50
        raceTimeTextBox(tostring(i), -0.01, offsetY, false)
        local minSplit = math.huge
        for j, sectorTime in ipairs(cp.splitTimes) do
            minSplit = math.min (minSplit, sectorTime)
        end
        for j, sectorTime in ipairs(cp.splitTimes) do
            local offsetX = (j-1)/20
            raceTimeTextBox(timeTxt(sectorTime), (j-1)/20, offsetY, sectorTime == minSplit and true or false)
        end

        -- draw lap times
        if i == #race.checkpoints then
            local minLap = math.huge
            for j, lapTime in ipairs(race.lapTimes) do
                minLap = math.min (minLap, lapTime)
            end
            for j, lapTime in ipairs(race.lapTimes) do
                raceTimeTextBox(timeTxt(lapTime), (j-1)/20, (#race.checkpoints+1)/50, lapTime == minLap and true or false)
            end
        end
    end
end

function checkpointChecker()
    if race.active then
        -- check if velocity vector intersects checkpoint line
        pp = GetEntityCoords(GetPlayerPed(-1), false)
        frameVector = pp - player.lastPos
        frameVectorMag = #frameVector
        if(frameVectorMag > 0.0) then
            vel = pp + ((frameVector/frameVectorMag)*3)
            drawCPLine(pp, vel)
            cp = race.checkpoints[race.currentCP]
            intersection = get_intersection(cp.left.x, cp.left.y, cp.right.x, cp.right.y, pp.x, pp.y, vel.x, vel.y ) 
            
            -- if checkpont was crossed
            if intersection ~= nil then
                cp.state = true
                -- add time to checkpoint
                table.insert(cp.times, race.raceTimer)
                table.insert(cp.splitTs, race.raceTimer - race.lastCPTime)
                -- if not last checkpoint then increment currentCP
                if #race.checkpoints > race.currentCP then
                    race.currentCP = race.currentCP + 1
                -- else if not last lap then increment currentLap and reset currentCP to 1
                elseif  race.currentLap < race.laps then
                    table.insert(race.lapTimes, race.raceTimer - race.lastLapTime)
                    race.lastLapTime = race.raceTimer
                    race.currentLap = race.currentLap + 1
                    race.currentCP = 1
                -- end race
                else
                    table.insert(race.lapTimes, race.raceTimer - race.lastLapTime)
                    race.lastLapTime = race.raceTimer
                    race.totalTime = race.raceTimer
                    -- end race
                    race.active = false;
                end
                race.lastCPTime = race.raceTimer
                showRoute()
            end
        end
    end
    player.lastPos = pp
end

-- checkpoint thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if #race.checkpoints ~= 0 then   
            -- Draw Race UI
            UI_Race()
            -- check if current checkpoint has been hit and do game logic
            checkpointChecker()
        end
    end
end)

RegisterCommand('edit', function(source, args)
    if args[1] == "on" then
        editCP.active = true
    else
        editCP.active = false
    end
end)

function UI_Edit(cpToggle)
    if editCP.active then
        hintText = cpToggle and "Left" or "Right"
        editTextBox("Press E to make "..hintText.." CP",0,0,false)
    end
end

function editTextBox(text, offsetX, offsetY, highlight) 
    SetTextFont(4)
    SetTextProportional(0)
    if highlight then
        SetTextColour(0,255,0,255)
    else
        --SetTextColour(255,255,0,255)
    end
    SetTextScale(0.5,0.5)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(
        tostring(text)
    )
    DrawText(0.1, 0.1)
end

-- Create Checkpoint Thread


Citizen.CreateThread(function()
    local cpToggle = true
    local leftCoords = vector3(0.0,0.0,0.0)
    local leftCoordsZ = vector3(0.0,0.0,0.0)
    local e_key = 86
    while true do
        Citizen.Wait(1)
        -- draw Edit UI
        UI_Edit(cpToggle)

        if editCP.active then
            if IsControlJustReleased(1, e_key) then
                local playerPos = GetEntityCoords(GetPlayerPed(-1), false)
                if cpToggle then
                    leftCoords = playerPos
                    local retval, groundZ = GetGroundZFor_3dCoord(playerPos.x,playerPos.y,playerPos.z, true)
                    leftCoordsZ = vector3(playerPos.x,playerPos.y,groundZ)
                    cpToggle = false
                else
                    rightCoords = vector3(playerPos.x,playerPos.y,playerPos.z)
                    local retval, groundZ = GetGroundZFor_3dCoord(playerPos.x,playerPos.y,playerPos.z, true)
                    local rightCoordsZ = vector3(playerPos.x,playerPos.y,groundZ)
                    local mp = leftCoords + ((rightCoords - leftCoords)/2)
                    retval, groundZ = GetGroundZFor_3dCoord(mp.x, mp.y, mp.z, true)
                    mp = vector3(mp.x,mp.y,groundZ)
                    table.insert(race.checkpoints, (#race.checkpoints ~= 0 and #race.checkpoints or 1),
                        {left = leftCoordsZ, right = rightCoordsZ , state = false, midpoint = mp, times = {}, splitTimes = {} })
                    cpToggle = true
                    print("number of race.checkpoints: "..#race.checkpoints)
                end
            end
        end
    end
end)

-- CREATE_OBJECT

function spawnTyre(position)
    local tyreHash = 812376260
    while not HasModelLoaded(tyreHash) do
        RequestModel(tyreHash)
        Citizen.Wait(50)
    end
    local retval, groundZ = GetGroundZFor_3dCoord(
		position.x, 
		position.y, 
		position.z, 
		true
	)
    print("groundZ:"..groundZ)
    local tyreL = CreateObject(
        tyreHash, 
        position.x, 
        position.y, 
        position.z, 
        true, 
        true, 
        false 
    )
end

local config = {
    pedFrequency = 0.2,
    trafficFrequency = 0.2,
}

-- Ped and Traffic frequency thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        SetPedDensityMultiplierThisFrame(config.pedFrequency) -- https://runtime.fivem.net/doc/natives/#_0x95E3D6257B166CF2
   
        SetScenarioPedDensityMultiplierThisFrame(config.pedFrequency, config.pedFrequency) -- https://runtime.fivem.net/doc/natives/#_0x7A556143A1C03898
        SetRandomVehicleDensityMultiplierThisFrame(config.trafficFrequency) -- https://runtime.fivem.net/doc/natives/#_0xB3B3359379FE77D3
        SetParkedVehicleDensityMultiplierThisFrame(config.trafficFrequency) -- https://runtime.fivem.net/doc/natives/#_0xEAE6DCC7EEE3DB1D
        SetVehicleDensityMultiplierThisFrame(config.trafficFrequency) -- https://runtime.fivem.net/doc/natives/#_0x245A6883D966D537
    end 
end)


function dragTimerTextBox() 
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(0.5,0.5)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(
        tostring(timer/1000)
        .. "~n~0-60 : " ..tostring(timeA/1000)
        .. "~n~0-100 : " ..tostring(timeB/1000)
        .. "~n~0-140 : " ..tostring(timeC/1000)
        .. "~n~1/4M : " ..tostring(timeDistA/1000)
        .. "~n~Dist : " ..tostring(math.floor(distanceFromStart))
    )
    DrawText(0.9,0.80)
end

RegisterCommand('sw', function(source, args)
    timer = 0
    timeMid = 0.0
    timeTop = 0.0
    startSpeedTimer()
end)

function startTimer()
    timerStart = GetGameTimer()
    timerRunning = true
    timerVisible = true
    timerFlagA = true
    timerFlagB = true
    timerFlagC = true
    timerDistFlagA = true
    distanceFromStart = 0.0
    startX, startY, startZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
end

function stopTimer()
    timerEnd = timer
    timerRunning = false
    timerVisible = true
end

function startSpeedTimer()
    speedTimerRunning = true
    timerWaitingToStart = true
    --startTimer()
end

function stopSpeedTimer()
    speedTimerRunning = false
    stopTimer()
end

-- DragStrip Timer Thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if timerRunning then
            timer = GetGameTimer() - timerStart
        end
        if timerVisible then
            dragTimerTextBox()
        end
        if speedTimerRunning then
            if(IsPedInAnyVehicle(GetPlayerPed(-1), false)) then
                local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
                local speed = tonumber(GetEntitySpeed(vehicle)*2.2369)
                
                local firstVec = vector3(startX, startY, startZ)
                local secondVec = GetEntityCoords(GetPlayerPed(-1), false)

                distanceFromStart = GetDistanceBetweenCoords(firstVec.x, firstVec.y, firstVec.z, secondVec.x, secondVec.y, secondVec.z, true)

                if (speed >= limitBottom) and (timerWaitingToStart) then
                    timerWaitingToStart = false
                    startTimer()
                end
                if (speed >= limitA) and (timerFlagA) then
                    timeA = timer
                    timerFlagA = false
                end
                if (speed >= limitB) and (timerFlagB) then
                    timeB = timer
                    timerFlagB = false
                end
                if (distanceFromStart >= limitdistA) and (timerDistFlagA) then
                    --print("distanceFromStart:"..tostring(distanceFromStart).."timer:"..tostring(timer))
                    timeDistA = timer
                    timerDistFlagA = false
                end
                if (speed >= limitC) and (timerFlagC) then
                    timeC = timer
                    timerFlagC = false
                end
                if (speed >= limitC) and (distanceFromStart >= limitdistA) and (speedTimerRunning) then
                    stopSpeedTimer()
                end
            end
        end
    end
end)


