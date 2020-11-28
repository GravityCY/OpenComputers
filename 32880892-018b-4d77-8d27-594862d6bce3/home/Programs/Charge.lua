local AStar = require("AStar")
local computer = require("computer")
local chargerRelPos = {x=-885.5,y=69.5,z=135.5}

AStar.WalkToTarget(chargerRelPos)

while computer.energy() < computer.maxEnergy() - 1000 do
    os.sleep(1)
end