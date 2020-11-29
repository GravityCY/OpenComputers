local AStar = require("AStar")
local computer = require("computer")
local event = require("event")
local chargerRelPos = {x=-885.5,y=69.5,z=135.5}

local startTime = computer.uptime()
AStar.FlashToTarget(chargerRelPos)
local endTime = computer.uptime()

print("Took a total of " .. endTime - startTime .. " seconds to reach the charger...")

event.push("arrived_charger")

while computer.energy() < computer.maxEnergy() - 1000 do
    os.sleep(1)
end

event.push("leaving_charger")