RegisterNetEvent("output")
AddEventHandler("output", function(argument)
    print(argument.." rows added")
    --TriggerEvent("chatMessage", "[Success]", {0,255,0}, argument)
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

-- checkpoint vars
raceTimer = 0
raceTimerStart = GetGameTimer()
lastPlayerPos = GetEntityCoords(GetPlayerPed(-1), false)

local race = {laps = 3, currentLap = 1, currentCP = 1}

local checkpoints = {}
table.insert(checkpoints, {left = vector3(1448.84, -2571.93, 48.12), right = vector3(1444.81, -2585.61, 48.39), state = false})
for i, cp in ipairs(checkpoints) do
    cp.midpoint = cp.left + ((cp.right - cp.left)/2)
end

function storeCheckpointsToDB()
    for i, cp in ipairs(checkpoints) do
        TriggerServerEvent("storeCheckpoint", cp, i)
    end
end

function getCheckPointsFromDB()
    local raceID = 1
    TriggerServerEvent("getCheckpoints", raceID)
end

RegisterCommand('scp', function(source, args)
    storeCheckpointsToDB()
end)

RegisterCommand('sw', function(source, args)
    timer = 0
    timeMid = 0.0
    timeTop = 0.0
    startSpeedTimer()
end)

RegisterCommand('rcp', function(source, args)
    for i, cp in ipairs(checkpoints) do
        cp.state = false
        cp.time = 0
        cp.blip = AddBlipForCoord(cp.midpoint.x, cp.midpoint.y, cp.midpoint.z)
        --SetBlipRoute(cp.blip, true)
        if i == #checkpoints then
            SetBlipSprite(cp.blip, 309)
        else
            SetBlipColour(cp.blip, 1)
            SetBlipScale(cp.blip, 0.5)
	        SetBlipSprite(cp.blip, 145)
        end
        
    end
    raceTimerStart = GetGameTimer()
    race = {laps = 3, currentLap = 1, currentCP = 1, active = true}
    showRoute()
end)

RegisterCommand("pos", function(source)
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
    outputString = "X: " .. x .." Y: " .. y .." Z: " .. z
    TriggerEvent("chatMessage", "[GPS]", {0,255,0}, outputString)
end)

function showRoute()
    -- Clear any old route first
    ClearGpsMultiRoute()
    -- Start a new route
    StartGpsMultiRoute(6, false, false)
    -- Add the points
    AddPointToGpsMultiRoute(checkpoints[#checkpoints].midpoint.x, checkpoints[#checkpoints].midpoint.y, checkpoints[#checkpoints].midpoint.z)
    for j = 1, race.laps do
        for i, cp in ipairs(checkpoints) do
            AddPointToGpsMultiRoute(cp.midpoint.x, cp.midpoint.y, cp.midpoint.z)
        end
    end
    -- Set the route to render
    SetGpsMultiRouteRender(true)
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

function checkpointTextBox() 
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(0.5,0.5)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(
        "checkpoint reached"
    )
    DrawText(0.9,0.70)
end

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

-- checkpoint thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        
        --update raceTimer
        if race.active then
            raceTimer = GetGameTimer() - raceTimerStart
        end

        -- draw cp info
        cpTextBox(" Lap: "..tostring(race.currentLap).."/"..tostring(race.laps), -0.04)
        cpTextBox(" Timer: "..tostring(raceTimer/1000), -0.02)
        cpTextBox(" Checkpoint: "..tostring(race.currentCP).."/"..tostring(#checkpoints), 0)
        for i,cp in ipairs(checkpoints) do
            drawCPLine(cp.left, cp.right)
            if cp.state then
                cpTextBox(tostring(i).." T: "..tostring(cp.time/1000), i/50)
            else
                cpTextBox(tostring(i).." T: -.---", i/50)
            end
        end

        -- check if velocity vector intersects checkpoint line
        pp = GetEntityCoords(GetPlayerPed(-1), false)
        frameVector = pp - lastPlayerPos
        frameVectorMag = #frameVector
        if(frameVectorMag > 0.0) then
            vel = pp + ((frameVector/frameVectorMag))
            cp = checkpoints[race.currentCP]
            intersection = get_intersection(cp.left.x, cp.left.y, cp.right.x, cp.right.y, pp.x, pp.y, vel.x, vel.y ) 
            
            -- if checkpont was crossed
            if intersection ~= nil then
                cp.state = true
                cp.time = raceTimer
                if #checkpoints > race.currentCP then
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
            end
        end
        lastPlayerPos = pp
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
                table.insert(checkpoints, #checkpoints, {left = leftCoords, right = rightCoords , state = false, midpoint = mp })
                cpToggle = true
            end
        end
    end

end)