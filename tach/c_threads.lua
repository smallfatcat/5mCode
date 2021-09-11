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
            getEditSelectionCoords()
            if IsControlJustReleased(1, e_key) then
                local playerPos = GetEntityCoords(GetPlayerPed(-1), false)
                if cpToggle then
                    leftCoords = editSelectionCoords
                    --leftCoords.z = leftCoords.z + 1.0 
                    --local retval, groundZ = GetGroundZFor_3dCoord(leftCoords.x,leftCoords.y,leftCoords.z, true)
                    --leftCoordsZ = vector3(leftCoords.x,leftCoords.y,groundZ)
                    cpToggle = false
                    spawnTyre(leftCoords)
                else
                    rightCoords = editSelectionCoords
                    --rightCoords.z = rightCoords.z + 1.0
                    --local retval, groundZ = GetGroundZFor_3dCoord(rightCoords.x,rightCoords.y,rightCoords.z, true)
                    --local rightCoordsZ = vector3(rightCoords.x,rightCoords.y,groundZ)
                    local mp = leftCoords + ((rightCoords - leftCoords)/2)
                    retval, groundZ = GetGroundZFor_3dCoord(mp.x, mp.y, mp.z, true)
                    mp = vector3(mp.x,mp.y,groundZ)
                    table.insert(race.checkpoints, (#race.checkpoints ~= 0 and #race.checkpoints or 1),
                        {left = leftCoords, right = rightCoords , state = false, midpoint = mp, times = {}, splitTimes = {} })
                    cpToggle = true
                    print("number of race.checkpoints: "..#race.checkpoints)
                    spawnTyre(rightCoords)
                end
            end
        end
    end
end)

-- Ped and Traffic frequency thread
Citizen.CreateThread(function()
    local config = {
        pedFrequency = 0.2,
        trafficFrequency = 0.2,
    }
    while true do
        Citizen.Wait(0)
        SetPedDensityMultiplierThisFrame(config.pedFrequency) -- https://runtime.fivem.net/doc/natives/#_0x95E3D6257B166CF2
   
        SetScenarioPedDensityMultiplierThisFrame(config.pedFrequency, config.pedFrequency) -- https://runtime.fivem.net/doc/natives/#_0x7A556143A1C03898
        SetRandomVehicleDensityMultiplierThisFrame(config.trafficFrequency) -- https://runtime.fivem.net/doc/natives/#_0xB3B3359379FE77D3
        SetParkedVehicleDensityMultiplierThisFrame(config.trafficFrequency) -- https://runtime.fivem.net/doc/natives/#_0xEAE6DCC7EEE3DB1D
        SetVehicleDensityMultiplierThisFrame(config.trafficFrequency) -- https://runtime.fivem.net/doc/natives/#_0x245A6883D966D537
    end 
end)