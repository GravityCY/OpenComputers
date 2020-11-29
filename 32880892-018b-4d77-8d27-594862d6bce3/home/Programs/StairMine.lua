local robot = require("betterbot")
local computer = require("computer")
local astar = require("astar")
local shell = require("shell")
local sides = require("gsides")
local thread = require("thread")
local event = require("event")
local debug = require("debug")

local args = shell.parse(...)

local argFitPlayer = false
local argFitEnder = false
local argPlaceTorches = false


for i, v in pairs(args) do
    v:lower()
    if v == "fitplayer" then argFitPlayer = true end
    if v == "fitender" then argFitEnder = true end
    if v == "debug" then debug.doPrint = true end
end

local minEnergy = 10000

robot.setBurnout(15)

print("Please enter the distance to mine: ")
local distance = io.read()

print("How many times to repeat: ")
local repeats = tonumber(io.read())

print("Choose a direction (Left, Right): ")
local direction = io.read():lower()

-- Epic little dance
local function Dance()
    for i = 0, 1 do
        robot.go(sides.up, true)
        robot.go(sides.down, true)
    end
end

-- Will stair mine for distance amount of times assuming robot has a tool
local function Mine(fitPlayer, fitEnderman)
    debug.print("Starting to mine...")
    fitPlayer = fitPlayer or true

    for i = 1, distance do
        local info = {}
        info[1] = table.pack(robot.swing(sides.down))
        robot.go(sides.down, _, true)
        if not info[1][1] and info[1][2] ~= "air" then return i - 1 end
        info[2] = table.pack(robot.swing())
        robot.go(sides.forward, _, true)
        if not info[2][1] and info[2][2] ~= "air" then robot.go(sides.up, _, true) return i - 1 end

        if fitPlayer or fitEnderman then robot.swing(sides.up) end
        if fitEnderman then robot.go(sides.up, _, true) robot.swing(sides.up) robot.go(sides.down, _, true) end
    end
end

local function Charge()
    if computer.energy() < minEnergy then
        local lookDirection = astar.GetFacing()
        local curPosition = astar.GetPosition()
        debug.print("Running out of energy. Starting to go towards charging station...")
        
        thread.create(function() 
            event.pull("arrived_charger")
            local arriveTime = computer.uptime()
            print("Arrived at charging station")
            event.pull("leaving_charger")
            print("Leaving from charging station")
            local leaveTime = computer.uptime()
            print("Took a total of " .. leaveTime - arriveTime .. " seconds")
         end)

        os.execute("/Home/Programs/Charge")
        os.execute("/Home/Programs/Charge")
        debug.print("Finished charging.")
        debug.print("Going back to mining area...")
        astar.RunToTarget(curPosition)
        debug.print("Arrived at mining area.")
        astar.FaceDirection(astar.GetFacing(), lookDirection)
    end
end

-- Will return back up to the surface from inside the stair mine
local function ReturnUp(walkForwards, optDistance)
    walkForwards = walkForwards or false
    optDistance = optDistance or distance
    debug.print("Finished mining " .. optDistance * 4 .. " blocks...")

    debug.print("Starting to return to the surface...")
    if walkForwards then robot.turn(sides.back) end
    for i = 1, optDistance do
        if walkForwards then
            robot.go(sides.forward,_,true)
            robot.go(sides.up,_,true)
        else
            robot.go(sides.back,_,true)
            robot.go(sides.up,_,true)
        end
    end

    debug.print("Finished returning to the surface...")

    if direction == "right" then robot.turn(sides.left)
    else robot.turn(sides.right) end
end

-- Will go to the chest location assuming robot is at a mine repeat position
local function GoToStart(dist)
    debug.print("Going towards the starting postiion...")
    for i = 1, dist do
        robot.go(sides.forward,_,true)
    end

    debug.print("Arrived at starting position...")

    if direction == "right" then robot.turn(sides.left)
    else robot.turn(sides.right) end
end

-- Will just drop stuff in an adjacent chest assuming robot is facing the chest
local function DropInChest(turnAround)
    debug.print("Dropping items into chest...")
    local count = 0
    for i = 1, robot.inventorySize() do
       robot.select(i)
       count = count + robot.count()
       robot.drop(sides.forward, 64)
    end

    debug.print("All total " .. count .. " items dropped inside of the chest...")

    if turnAround then return robot.turn(sides.back) end

    if direction == "right" then robot.turn(sides.left)
    else robot.turn(sides.right) end
end

-- Will go towards a repeat position assuming robot is at start position
local function GoToRepeat(dist)

    debug.print("Going to the next mine position...")
    for i = 1, dist do
        robot.go(sides.forward,_,true)
    end

    debug.print("Arrived.")

    if direction == "right" then robot.turn(sides.left)
    else robot.turn(sides.right) end
end

for i = 1, repeats do
    local distanceMined = Mine(argFitPlayer, argFitEnder)
    ReturnUp(_,distanceMined)
    GoToStart(i - 1)
    DropInChest(i == repeats)
    Charge()
    if i == repeats then break end
    GoToRepeat(i)
end

Dance()