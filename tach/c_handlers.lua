RegisterNetEvent("output")
RegisterNetEvent("rcvCheckpoints")
RegisterNetEvent("cptStatus")
RegisterNetEvent("laptStatus")

AddEventHandler("cptStatus", function(result)
    print("time taken to store cp time: "..tostring(GetGameTimer() -dbStoreTime ))
    --TriggerEvent("chatMessage", "output:", {0,255,0}, #result)
end)

AddEventHandler("laptStatus", function(result)
    print("time taken to store lap time: "..tostring(GetGameTimer() -dbStoreTime ))
    --TriggerEvent("chatMessage", "output:", {0,255,0}, #result)
end)

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