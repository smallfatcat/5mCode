local spawnPos = vector3(-848.586, -3213.992, 13.944)

AddEventHandler('onClientGameTypeStart', function()
    exports.spawnmanager:setAutoSpawnCallback(function()
        exports.spawnmanager:spawnPlayer({
            x = spawnPos.x,
            y = spawnPos.y,
            z = spawnPos.z,
            model = 'a_m_m_skater_01'
        }, function()
            TriggerEvent('chat:addMessage', {
                args = { 'Welcome to the party!~' }
            })
        end)
    end)

    exports.spawnmanager:setAutoSpawn(true)
    exports.spawnmanager:forceRespawn()
end)

RegisterCommand('car', function(source, args)
    -- account for the argument not being passed
    local vehicleName = args[1] or 'adder'

    -- check if the vehicle actually exists
    if not IsModelInCdimage(vehicleName) or not IsModelAVehicle(vehicleName) then
        TriggerEvent('chat:addMessage', {
            args = { 'It might have been a good thing that you tried to spawn a ' .. vehicleName .. '. Who even wants their spawning to actually ^*succeed?' }
        })

        return
    end

    -- load the model
    RequestModel(vehicleName)

    -- wait for the model to load
    while not HasModelLoaded(vehicleName) do
        Wait(500) -- often you'll also see Citizen.Wait
    end

    -- get the player's position
    local playerPed = PlayerPedId() -- get the local player ped
    local pos = GetEntityCoords(playerPed) -- get the position of the local player ped

    -- create the vehicle
    local vehicle = CreateVehicle(vehicleName, pos.x, pos.y, pos.z, GetEntityHeading(playerPed), true, false)

    -- set the player ped into the vehicle's driver seat
    SetPedIntoVehicle(playerPed, vehicle, -1)

    -- give the vehicle back to the game (this'll make the game decide when to despawn the vehicle)
    SetEntityAsNoLongerNeeded(vehicle)

    -- release the model
    SetModelAsNoLongerNeeded(vehicleName)

    -- tell the player
    TriggerEvent('chat:addMessage', {
        args = { 'Woohoo! Enjoy your new ^*' .. vehicleName .. '!' }
    })
end, false)

function Draw3DText(v, text)
    SetDrawOrigin(v.x, v.y, v.z, 0)
    SetTextScale(0.0, 0.35)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0, 0)
    ClearDrawOrigin()
end

function text(content) 
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(0.5,0.5)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(content)
    DrawText(0.01,0.75)
end

function giveWeapon(hash)
    GiveWeaponToPed(GetPlayerPed(-1), GetHashKey(hash), 999, false, false)
end

-- Giveweapon test thread
Citizen.CreateThread(function()

    local h_key = 74
    while true do
        Citizen.Wait(1)
        if IsControlJustReleased(1, h_key) then
            print("The key ".. h_key .. " was pressed")
            giveWeapon("weapon_pistol")

            giveWeapon("weapon_pumpshotgun")
                weaponComponent("weapon_pumpshotgun", "COMPONENT_AT_AR_FLSH")

            giveWeapon("weapon_knife")
            alert("~b~Given Weapons with ~INPUT_VEH_HEADLIGHT~")
        end
    end

end)



-- Vehicle Hud Thread
Citizen.CreateThread(function()

    while true do
        Citizen.Wait(1)
        -- Condition to check if the ped is in a vehicle
        if(IsPedInAnyVehicle(GetPlayerPed(-1), false)) then
            local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
            local speed = (GetEntitySpeed(vehicle)*2.2369)
            
            local gear  = GetVehicleCurrentGear(vehicle)
            local fuel = GetVehicleFuelLevel(vehicle)
            local clutch  = GetVehicleClutch(vehicle)
            local rpm  = GetVehicleCurrentRpm(vehicle)
            --local accel = GetVehicleCurrentAcceleration(vehicle)
            local maxV = GetVehicleHandlingInt(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
            local driveF = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
            driveF = math.floor(driveF*100) / 100
            --print(driveF)
            local health = GetVehicleEngineHealth(vehicle)
            SetVehicleEnginePowerMultiplier(vehicle , 50.0)
                    
            --text(math.floor(speed) .. " MPH ")
            text(
                math.floor(speed) 
                .. " MPH - Gear " 
                .. math.floor(gear) 
                .. " - Fuel " 
                .. math.floor(fuel) 
                .. " - rpm " 
                .. math.floor(rpm*8000) 
                .. " - MaxV " 
                .. maxV
                .. " - DF " 
                .. driveF
                .. " - health " 
                .. health
            )
        end
    end
end)

