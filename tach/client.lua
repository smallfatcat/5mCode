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

print("Starting Tach...")
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
race = {laps = 3, currentLap = 1, currentCP = 1, checkpoints = {}, raceTimer = 0, raceTimerStart = GetGameTimer()}

RegisterCommand('tyres', function(source, args)
    for i, cp in ipairs(race.checkpoints) do
        spawnTyre(cp.left)
        spawnTyre(cp.right)
    end
end)

RegisterCommand('tpr', function(source, args)
    SetPedCoordsKeepVehicle(PlayerPedId(), race.checkpoints[#race.checkpoints].midpoint.x, race.checkpoints[#race.checkpoints].midpoint.y, race.checkpoints[#race.checkpoints].midpoint.z)
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
        cp.time = 0
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
    race.raceTimerStart = GetGameTimer()
    race.laps = 3
    race.currentLap = 1
    race.currentCP = 1
    race.active = true
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

function cpTextBox(text, offset) 
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(0.5,0.5)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(
        tostring(text)
    )
    DrawText(0.9,0.60 + offset)
end

-- checkpoint thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if #race.checkpoints ~= 0 then   
            --update race.raceTimer
            if race.active then
                race.raceTimer = GetGameTimer() - race.raceTimerStart
            end

            -- draw cp info
            cpTextBox(" Lap: "..tostring(race.currentLap).."/"..tostring(race.laps), -0.04)
            cpTextBox(" Timer: "..tostring(race.raceTimer/1000), -0.02)
            cpTextBox(" Checkpoint: "..tostring(race.currentCP).."/"..tostring(#race.checkpoints), 0)
            for i,cp in ipairs(race.checkpoints) do
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
                -- update times
                if cp.state then
                    cpTextBox(tostring(i).." T: "..tostring(cp.time/1000), i/50)
                else
                    cpTextBox(tostring(i).." T: -.---", i/50)
                end
            end

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
                    cp.time = race.raceTimer
                    
                    if #race.checkpoints > race.currentCP then
                        -- increment checkpoint
                        race.currentCP = race.currentCP + 1
                    elseif  race.currentLap < race.laps then
                        -- increment laps
                        race.currentLap = race.currentLap + 1
                        race.currentCP = 1
                    else
                        -- end race
                        race.active = false;
                    end
                    showRoute()
                end
            end
            player.lastPos = pp
        end
    end
end)

-- Create Checkpoint Thread
local cpToggle = true
local leftCoords = vector3(0.0,0.0,0.0)

Citizen.CreateThread(function()

    local h_key = 86
    while true do
        Citizen.Wait(1)
        if IsControlJustReleased(1, h_key) then
            if cpToggle then
                leftCoords = GetEntityCoords(GetPlayerPed(-1), false)
                cpToggle = false
            else
                rightCoords = GetEntityCoords(GetPlayerPed(-1), false)
                mp = leftCoords + ((rightCoords - leftCoords)/2)
                table.insert(race.checkpoints, (#race.checkpoints ~= 0 and #race.checkpoints or 1), {left = leftCoords, right = rightCoords , state = false, midpoint = mp })
                cpToggle = true
                print("number of race.checkpoints: "..#race.checkpoints)
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
        groundZ, 
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


function timerTextBox() 
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

-- Timer Thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if timerRunning then
            timer = GetGameTimer() - timerStart
        end
        if timerVisible then
            timerTextBox()
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


