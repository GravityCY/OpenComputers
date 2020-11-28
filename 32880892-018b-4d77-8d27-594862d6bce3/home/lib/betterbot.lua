local bot = require("robot")
local computer = require("computer")
local sides = require("gsides")

local obstacleInfo = {entity="entity", solid="solid"}
local sObstacleInfo = {entity="entity", block="block", fire="fire"}
local sleepTime = 1
local burnoutTime = 2

local robot = {}

-- == To-Do == --
-- Add a failed attempts var to stop trying a certain operation after the said attempts

--[[
 Will just make the robot go towards a direction using a direction variable
 Is repeatable at the expense of not getting accurate failed attempt information
 Example it tries to go 3 times forward without being able to relay information-
 -on whether they were succesful
--]]



local function go(side, repeats)
    side = side or sides.forward
    repeats = repeats or 1

    if repeats == 1 then
        if side == sides.forward then return bot.forward() end
        if side == sides.back then return bot.back() end
        if side == sides.left then bot.turnLeft() return bot.forward() end
        if side == sides.right then bot.turnRight() return bot.forward() end
        if side == sides.up then return bot.up() end
        if side == sides.down then return bot.down() end
    else
        for i = 1, repeats do
            if side == sides.forward then bot.forward() end
            if side == sides.back then bot.back() end
            if side == sides.left then bot.turnLeft() bot.forward() end
            if side == sides.right then bot.turnRight() bot.forward() end
            if side == sides.up then bot.up() end
            if side == sides.down then bot.down() end
        end
    end
    return true
end

local function turn(side, repeats)
    repeats = repeats or 1
    side = side or sides.forward

    if repeats == 1 then
        if side == sides.left then return bot.turnLeft() end
        if side == sides.right then return bot.turnRight() end
        if side == sides.back then bot.turnRight() return bot.turnRight() end
    else
        for i = 1, repeats do
            if side == sides.left then bot.turnLeft() end
            if side == sides.right then bot.turnRight() end
            if side == sides.back then bot.turnRight() bot.turnRight() end
        end
    end
    return true
end

local function swing(side, repeats)
    repeats = repeats or 1
    side = side or sides.forward

    if repeats == 1 then
        if side == sides.forward then return bot.swing() end
        if side == sides.back then bot.turnAround() local success = bot.swing() bot.turnAround() return success end
        if side == sides.up then return bot.swingUp() end
        if side == sides.down then return bot.swingDown() end
    else
        for i = 1, repeats do
            if side == sides.forward then bot.swing() end
            if side == sides.back then bot.turnAround() bot.swing() bot.turnAround() end
            if side == sides.up then bot.swingUp() end
            if side == sides.down then bot.swingDown() end
        end
    end
    return true
end

local function goPause(side, burnout, repeats )
    repeats = repeats or 1
    burnout = burnout or false
    local start = computer.uptime()
    for i = 1, repeats do
        while true do
            local moveSuccess, moveInfo = robot.go(side)
            if not moveSuccess and moveInfo == obstacleInfo[2] or moveInfo == obstacleInfo[1] then
                os.sleep(sleepTime)
            end
            if burnout and computer.uptime() - start >= burnoutTime then return -1 end
            if moveSuccess then break end
        end
    end
    return true
end

local function goBreak(side, hangIfUnbreakable, burnout, repeats)
    hangIfUnbreakable = hangIfUnbreakable or false
    repeats = repeats or 1

    for i = 1, repeats do
        while true do
            local moveSuccess, moveInfo = go(side)
            if not moveSuccess and moveInfo == obstacleInfo.solid then 
                local swingSuccess = swing(side)
                if not swingSuccess then 
                    if hangIfUnbreakable then
                        goPause(side, burnout, repeats)
                    else return false end
                end
            elseif not moveSuccess and moveInfo == obstacleInfo.entity then moveSuccess = goPause(side) end
            if moveSuccess then return true end
        end
    end
    return true
end

local function detect(side, filter)
    side = side or sides.forward
    filter = filter or nil

    if filter == nil then
        if side == sides.forward then return bot.detect() end
        if side == sides.back then turn(sides.back) local info = bot.detect() turn(sides.back) return info end
        if side == sides.left then turn(sides.left) local info = bot.detect() turn(sides.right) return info end
        if side == sides.right then turn(sides.right) local info = bot.detect() turn(sides.left) return info end
        if side == sides.up then return bot.detectUp() end
        if side == sides.down then return bot.detectDown() end
    else
        if side == sides.forward then return ({bot.detect()})[2] == filter end
        if side == sides.back then turn(sides.back) local info = ({bot.detect()})[2] == filter turn(sides.back) return info end
        if side == sides.left then turn(sides.left) local info = ({bot.detect()})[2] == filter turn(sides.right) return info end
        if side == sides.right then turn(sides.right) local info = ({bot.detect()})[2] == filter turn(sides.left) return info end
        if side == sides.up then return ({bot.detectUp()})[2] == filter end
        if side == sides.down then return ({bot.detectDown()})[2] == filter end
    end
end

local function drop(side, amount)
    side = side or sides.forward
    amount = amount or 1

    if side == sides.forward then return bot.drop(amount) end
    if side == sides.back then turn(sides.back) local info = bot.drop(amount) turn(sides.back) return info end
    if side == sides.left then turn(sides.left) local info = bot.drop(amount) turn(sides.right) return info end
    if side == sides.right then turn(sides.right) local info = bot.drop(amount) turn(sides.left) return info end
    if side == sides.up then return bot.dropUp(amount) end
    if side == sides.down then return bot.dropDown(amount) end
end

-- = { PUBLIC FUNCTIONS } = --

function robot.go(side, pauseIfObstruct, breakIfObstruct, hangIfUnbreakable, burnout, repeats)
    pauseIfObstruct = pauseIfObstruct or false
    breakIfObstruct = breakIfObstruct or false
    hangIfUnbreakable = hangIfUnbreakable or false

    if pauseIfObstruct then
        return goPause(side, burnout, repeats)
    elseif breakIfObstruct then
        return goBreak(side, hangIfUnbreakable, burnout, repeats)
    else return go(side,repeats) end
end

function robot.turn(side, repeats)
    return turn(side, repeats)
end

function robot.swing(side, repeats)
    return swing(side, repeats)
end

function robot.detect(side, filter)
    return detect(side, filter)
end

function robot.detectAll()
    local values = {}
    values[1] = table.pack(robot.detect())
    robot.turn(sides.right)
    values[2] = table.pack(robot.detect())
    robot.turn(sides.right)
    values[3] = table.pack(robot.detect())
    robot.turn(sides.right)
    values[4] = table.pack(robot.detect())
    robot.turn(sides.right)
    values[5] = table.pack(robot.detect(sides.up))
    values[6] = table.pack(robot.detect(sides.down))
    return values
end

function robot.drop(side, amount)
    return drop(side, amount)
end

function robot.inventorySize()
    return bot.inventorySize()
end

function robot.select(itemSlot)
    return bot.select(itemSlot)
end

function robot.count(itemSlot)
    return bot.count(itemSlot)
end

function robot.setBurnout(time)
    burnoutTime = time
end

return robot