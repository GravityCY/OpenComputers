local robot = require("betterbot")

print("Please enter the distance to mine: ")
local distance = io.read()

print("How many times to repeat: ")
local repeats = tonumber(io.read())

print("Choose a direction (Left, Right): ")
local direction = io.read()

-- Will stair mine for distance amount of times assuming robot has a tool
local function Mine(fitPlayer)
    fitPlayer = fitPlayer or true

    for i = 1, distance do
        robot.swingDown()
        robot.down(_,true)
        robot.swing()
        robot.forward(_,true)
        if fitPlayer then robot.swingUp() end
    end
end

-- Will return back up to the surface from inside the stair mine
local function ReturnUp(walkForwards)
    walkForwards = walkForwards or false

    if walkForwards then robot.turnAround() end
    for i = 1, distance do
        if walkForwards then
            robot.forward(_,true)
            robot.up(_,true)
        else
            robot.back(_,true)
            robot.up(_,true)
        end
    end

    if direction == "Right" then robot.turnLeft()
    else robot.turnRight() end
end

-- Epic little dance
local function Dance()
    for i = 0, 1 do
        robot.up(true)
        robot.down(true)
    end
end

-- Will just drop stuff in an adjacent chest assuming robot is facing the chest
local function DropInChest(turnAround)
    for i = 1, robot.inventorySize() do
       robot.select(i)      
       robot.drop(64)
    end

    if turnAround then robot.turnAround() return end

    if direction == "Right" then robot.turnLeft()
    else robot.turnRight() end
end

-- Will go to the chest location assuming robot is at a mine repeat position
local function GoToStart(distance)
    for i = 1, distance do
        robot.forward(_,true)
    end

    if direction == "Right" then robot.turnLeft()
    else robot.turnRight() end
end


-- Will go towards a repeat position assuming robot is at start position
local function GoToRepeat(distance)
    for i = 1, distance do
        robot.forward(_,true)
    end

    if direction == "Right" then robot.turnLeft()
    else robot.turnRight() end
end

for i = 1, repeats do
    Mine()
    ReturnUp()
    GoToStart(i - 1)
    DropInChest(i == repeats)
    if i == repeats then break end
    GoToRepeat(i)
end

Dance()