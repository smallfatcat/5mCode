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

RegisterCommand('sw', function(source, args)
    timer = 0
    timeMid = 0.0
    timeTop = 0.0
    startSpeedTimer()
end)

RegisterCommand("pos", function(source)
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
    outputString = "X: " .. x .." Y: " .. y .." Z: " .. z
    TriggerEvent("chatMessage", "[GPS]", {0,255,0}, outputString)
end)

function intersection (s1, e1, s2, e2)
    local d = (s1.x - e1.x) * (s2.y - e2.y) - (s1.y - e1.y) * (s2.x - e2.x)
    local a = s1.x * e1.y - s1.y * e1.x
    local b = s2.x * e2.y - s2.y * e2.x
    local x = (a * (s2.x - e2.x) - (s1.x - e1.x) * b) / d
    local y = (a * (s2.y - e2.y) - (s1.y - e1.y) * b) / d
    return x, y
end

local line1start, line1end = {x = 4, y = 0}, {x = 6, y = 10}
local line2start, line2end = {x = 0, y = 3}, {x = 10, y = 7}
print(intersection(line1start, line1end, line2start, line2end))

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
                    print("distanceFromStart:"..tostring(distanceFromStart).."timer:"..tostring(timer))
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