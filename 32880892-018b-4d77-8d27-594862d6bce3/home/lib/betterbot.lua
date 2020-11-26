local bot = require("robot")

local obstacleInfo = {"entity", "solid"}

local sleepTime = 1

local robot = {}

-- == To-Do == --
-- Add a failed attempts var to stop trying a certain operation after the said attempts

--[[
 Will just make the robot go towards a direction using a direction variable
 Is repeatable at the expense of not getting accurate failed attempt information
 Example it tries to go 3 times forward without being able to relay information-
 -on whether they were succesful
--]]
local function go(direction, repeats)
    repeats = repeats or 1

    if repeats == 1 then
        if direction == "Forward" then return bot.forward() end
        if direction == "Back" then return bot.back() end
        if direction == "Up" then return bot.up() end
        if direction == "Down" then return bot.down() end
    else
        for i = 1, repeats do
            if direction == "Forward" then bot.forward() end
            if direction == "Back" then bot.back() end
            if direction == "Up" then bot.up() end
            if direction == "Down" then bot.down() end
        end
    end
    return true
end

--[[
    Will just swing towards a direction using a direction variable
    Is repeatable at the expense of not getting accurate failed attempt information
--]]
local function swing(direction, repeats)
    repeats = repeats or 1

    if repeats == 1 then
        if direction == "Forward" then return bot.swing() end
        if direction == "Back" then bot.turnAround() success = bot.swing() bot.turnAround() return success end
        if direction == "Up" then return bot.swingUp() end
        if direction == "Down" then return bot.swingDown() end
    else
        for i = 1, repeats do
            if direction == "Forward" then bot.swing() end
            if direction == "Back" then bot.turnAround() bot.swing() bot.turnAround() end
            if direction == "Up" then bot.swingUp() end
            if direction == "Down" then bot.swingDown() end
        end
    end
    return true
end

local function turn(direction, repeats)
    repeats = repeats or 1

    if repeats == 1 then
        if direction == "Left" then return bot.turnLeft() end
        if direction == "Right" then return bot.turnRight() end
        if direction == "Back" then bot.turnRight() return bot.turnRight() end
    else
        for i = 1, repeats do
            if direction == "Left" then bot.turnLeft() end
            if direction == "Right" then bot.turnRight() end
            if direction == "Back" then bot.turnRight() bot.turnRight() end
        end
    end
    return true
end

--[[
    Will go towards a direction and if obstructed by specified obstacles will just pause / hang until able to move again
    Is repeatable
    It will only say it was succesful when it is finally able to finish the moves
--]]

local function goPause(direction, repeats)
    repeats = repeats or 1

    for i = 1, repeats do
        while true do 
            success, info = go(direction)
            if not success and info == obstacleInfo[2] or info == obstacleInfo[1] then
                os.sleep(sleepTime)
            end
            if success then break end
        end
    end
    return true
end

--[[
    Will go towards a direction and if obstructed by specified obstacles-
    -it will try to break them assuming it holds a tool capable of doing so,-
    if not it will just pause and hang
    Is Repeatable
    It will only say it was succesful when it finally is able to finish the moves
--]]
local function goBreak(direction, repeats, hangIfUnbreakable)
    hangIfUnbreakable = hangIfUnbreakable or false
    repeats = repeats or 1

    for i = 1, repeats do
        while true do 
            success, info = go(direction)
            if not success and info == obstacleInfo[2] then
                swing(direction)
            end
            if hangIfUnbreakable and not success then success = goPause(direction) end
            if success then break end
        end
    end
    return true
end

function robot.up(pauseIfObstruct, breakIfObstruct, repeats)
    local dir = "Up"

    pauseIfObstruct = pauseIfObstruct or false
    breakIfObstruct = breakIfObstruct or false

    if pauseIfObstruct then
        return goPause(dir, repeats)
    end
    if breakIfObstruct then
        return goBreak(dir, repeats, true)
    else return go(dir) end
end

function robot.down(pauseIfObstruct, breakIfObstruct, repeats)
    local dir = "Down"

    local pauseIfObstruct = pauseIfObstruct or false
    local breakIfObstruct = breakIfObstruct or false

    if pauseIfObstruct then
        return goPause(dir, repeats)
    end
    if breakIfObstruct then
        return goBreak(dir, repeats, true)
    else return go(dir) end
end

function robot.forward(pauseIfObstruct, breakIfObstruct, repeats)
    local dir = "Forward"

    pauseIfObstruct = pauseIfObstruct or false
    breakIfObstruct = breakIfObstruct or false

    if pauseIfObstruct then
        return goPause(dir, repeats)
    end
    if breakIfObstruct then
        return goBreak(dir, repeats, true)
    else return go(dir) end
end
  
function robot.back(pauseIfObstruct, breakIfObstruct, repeats)
    local dir = "Back"

    pauseIfObstruct = pauseIfObstruct or false
    breakIfObstruct = breakIfObstruct or false

    if pauseIfObstruct then
        return goPause(dir, repeats)
    end
    if breakIfObstruct then
        return goBreak(dir, repeats, true)
    else return go(dir) end
end

function robot.right(pauseIfObstruct, breakIfObstruct)
    bot.turnRight()
    return forward(pauseIfObstruct, breakIfObstruct)
end

function robot.left(pauseIfObstruct, breakIfObstruct)
    bot.turnLeft()
    return forward(pauseIfObstruct, breakIfObstruct)
end

function robot.turnLeft(repeats)
    return turn("Left", repeats)
end

function robot.turnRight(repeats)
    return turn("Right", repeats)
end

function robot.turnAround(repeats)
    return bot.turnAround("Back", repeats)
end

function robot.drop()
    return bot.drop()
end

function robot.swing(repeats)
    local dir = "Forward"
    return swing(dir, repeats)
end

function robot.swingUp(repeats)
    local dir = "Up"
    return swing(dir, repeats)
end

function robot.swingDown(repeats)
    local dir = "Down"
    return swing(dir, repeats)
end

function robot.inventorySize()
    return bot.inventorySize()
end

function robot.select(itemSlot)
    return bot.select(itemSlot)
end

function robot.detect()
    return bot.detect()
end

function robot.detectUp()
    return bot.detectUp()
end

function robot.detectDown()
    return bot.detectDown()
end

return robot