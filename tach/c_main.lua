print("Loaded Tach")

editSelectionCoords = vector3(0.0, 0.0, 0.0)

-- test vars
dbStoreTime = 0

-- player vars
player = {
    lastPos = GetEntityCoords(GetPlayerPed(-1), false)
}

-- race vars
race = {}
race.lapTimes = {}
race.raceTimerStart = GetGameTimer()
race.laps = 3
race.currentLap = 1
race.currentCP = 1
race.active = false
race.lastCPTime = 0
race.lastLapTime = 0
race.totalTime = 0
race.checkpoints = {}


track = {
    trackID = 1,
    checkpoints = {}
}

driver = {
    driverID = 1,
    driverName = "SFC"
}

raceEvent = {
    eventID = 1,
    trackID = 1,
    laps = 3,
    drivers = {1}
}

function startNewRace(trackID, laps)
    raceEvent.trackID = trackID
    raceEvent.laps = laps
    race.laps = laps
    TriggerServerEvent("getNextEventID", cpTimeObj)

end

function setupRaceEvent(nextEventID)
    print("nextEventID[1].eventID:"..nextEventID[1].eventID)
    raceEvent.eventID = tonumber(nextEventID[1].eventID)
    drivers = {driver.driverID}
    getCheckPointsFromDB(raceEvent.trackID)
end

-- ui vars
editCP = {editMode = 0, active = false}

function storeCheckpointTimeToDB(cpTimeObj)
    TriggerServerEvent("storeCheckpointTime", cpTimeObj)
end

function storeLapTimeToDB(lapTimeObj)
    TriggerServerEvent("storeLapTime", lapTimeObj)
end

function storeCheckpointsToDB(raceID)
    for i, cp in ipairs(race.checkpoints) do
        --local raceID = 2
        TriggerServerEvent("storeCheckpoint", cp, i, raceID)
    end
end

function getCheckPointsFromDB(raceID)
    --local raceID = 2
    --local playerID = PlayerPedId()
    TriggerServerEvent("getCheckpoints",raceID)
end

function resetRace()
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
    --race.laps = 3
    race.currentLap = 1
    race.currentCP = 1
    race.active = false
    race.lastCPTime = 0
    race.lastLapTime = 0
    race.totalTime = 0
    showRoute()
end

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
    DrawText(0.8 + offsetX, 0.20 + offsetY)
end

function UI_Race()
    --update race.raceTimer
    if race.active then
        race.raceTimer = GetGameTimer() - race.raceTimerStart
    end

    -- draw race info
    raceTimeTextBox("Lap: "..tostring(race.currentLap).."/"..tostring(race.laps), -0.01, -0.04, false)
    raceTimeTextBox("Timer: "..(race.active and timeTxt(race.raceTimer) or "Waiting"), -0.01, -0.02, false)
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
        raceTimeTextBox(tostring(i), -0.012, offsetY, false)
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
    pp = GetEntityCoords(GetPlayerPed(-1), false)
    if race.active then
        -- check if velocity vector intersects checkpoint line
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
                table.insert(cp.splitTimes, race.raceTimer - race.lastCPTime)

                -- store cp time in DB
                local cpTimeObj = {
                    checkpointID = race.currentCP,
                    raceID = raceEvent.trackID,
                    driverID = driver.driverID,
                    eventID = raceEvent.eventID,
                    time = race.raceTimer - race.lastCPTime,
                    lap = race.currentLap
                }
                dbStoreTime = GetGameTimer()
                storeCheckpointTimeToDB(cpTimeObj)
                
                local lapTimeObj = {
                    lapID = race.currentLap,
                    raceID = raceEvent.trackID,
                    driverID = driver.driverID,
                    eventID = raceEvent.eventID,
                    time = race.raceTimer - race.lastLapTime
                }

                -- if not last checkpoint then increment currentCP
                if #race.checkpoints > race.currentCP then
                    race.currentCP = race.currentCP + 1
                -- else if not last lap then increment currentLap and reset currentCP to 1
                elseif  race.currentLap < race.laps then
                    table.insert(race.lapTimes, race.raceTimer - race.lastLapTime)
                    
                    -- store lap time in DB
                    storeLapTimeToDB(lapTimeObj)

                    race.lastLapTime = race.raceTimer
                    race.currentLap = race.currentLap + 1
                    race.currentCP = 1
                -- end race
                else
                    table.insert(race.lapTimes, race.raceTimer - race.lastLapTime)
                    storeLapTimeToDB(lapTimeObj)
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

-- spawn in checkpont markers
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

function timeTxt(mstime)
    local minutes = math.floor(mstime/60000)
    local seconds = (mstime % 60000)/1000
    local prefix = ""
    local minuteTxt = ""
    if minutes > 0 then minuteTxt = tostring(minutes).."\'" end
    if seconds < 10 and minutes > 0 then prefix = "0" end
    return minuteTxt..prefix..tostring(seconds).."\""
end

local function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera(distance)
	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination = 
	{ 
		x = cameraCoord.x + direction.x * distance, 
		y = cameraCoord.y + direction.y * distance, 
		z = cameraCoord.z + direction.z * distance 
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
	return b, c, e
end

--[[ Citizen.CreateThread(function()
	while not NetworkIsPlayerActive do
		Citizen.Wait(0)
	end
	
	while true do
		Citizen.Wait(0)

		local hit, coords, entity = RayCastGamePlayCamera(1000.0)

		if hit and (IsEntityAVehicle(entity) or IsEntityAPed(entity)) then
			local position = GetEntityCoords(GetPlayerPed(-1))
			--DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 255, 0, 0, 255)
            DrawSphere(coords.x, coords.y, coords.z, 0.1, 255, 0, 0, 0.5)
		end
	end
end) ]]

function getEditSelectionCoords()
    local hit, coords, entity = RayCastGamePlayCamera(1000.0)

    if hit --[[ and (IsEntityAVehicle(entity) or IsEntityAPed(entity)) ]] then
        local position = GetEntityCoords(GetPlayerPed(-1))
        --DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 255, 0, 0, 255)
        DrawSphere(coords.x, coords.y, coords.z, 0.1, 255, 0, 0, 0.5)
        editSelectionCoords = vector3(coords.x, coords.y, coords.z)
    end
    return 
end




