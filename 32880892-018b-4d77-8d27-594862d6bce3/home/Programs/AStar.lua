local component = require("component")
local robot = require("betterbot")

local navigation = component.navigation

local sides = {forward = 0, right = 1, back = 2, left = 3, up = 4, down = 5}
local dirs = {posZ = 1, negX = 2, negZ = 3, posX = 4}

local AStar = {}

--[[
    Normal Side Values
    Back:   north,  negZ,   Number: 2
    Front:  south,  posZ,   Number: 3
    Right:  west,   negX,   Number: 4
    Left:   east,   posX,   Number: 5
]]--

--[[
    My Side Values
    Front:  south,  posZ,   Number: 1
    Right:  west,   negX,   Number: 2
    Back:   north,  negZ,   Number: 3
    Left:   east,   posX,   Number: 4
]]--

local function ConvertSide(number)
    if number == 3 then return 1 end
    if number == 4 then return 2 end
    if number == 2 then return 3 end
    if number == 5 then return 4 end
end

local function Copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[Copy(k, s)] = Copy(v, s) end
    return res
end

local function GetDirection(position, target)
    local difference = {x= target.x - position.x, z= target.z - position.z}

    if math.abs(difference.x) > math.abs(difference.z) then
        if difference.x > 0 then return dirs.posX else return dirs.negX end
    elseif difference.z > 0 then return dirs.posZ else return dirs.negZ end
end

local function DumbWalkToTarget(facing, position, target)
    AStar.FaceTarget(facing,position,target)
    robot.forward()
end

local function GetRelativePosition(pos, facing, direction)
    local out = facing + direction
    out = (((out - 1) % (5 - 1)) + (5 - 1)) % (5 - 1) + 1

    local position = Copy(pos)

    if direction == sides.up then position.y = position.y + 1 return position end
    if direction == sides.down then position.y = position.y - 1 return position end
    if out == dirs.negX then position.x = position.x - 1 end
    if out == dirs.negZ then position.z = position.z - 1 end
    if out == dirs.posX then position.x = position.x + 1 end
    if out == dirs.posZ then position.z = position.z + 1 end

    return position
end

local function GetTotalScore(startPosition, position, target)
    local targetDistance = math.abs(target.x - position.x) + math.abs(target.y - position.y) + math.abs(target.z - position.z)
    return targetDistance
end

local function VecToString(vector)
    if type(vector) == "string" then return vector end
    if type(vector) ~= "table" then return nil end

    return vector.x .. " " .. vector.y .. " " .. vector.z
end

local function AddVecTable(table, key, value)
    value = value or true
    table[VecToString(key)] = value
end

local function ContainsVecTable(table, vec)
    return table[VecToString(vec)] ~= nil
end

local function RemoveVecTable(table, vec)
    table[VecToString(vec)] = nil
end

local function StringToVec(string)
    local vec = {}

    local i = 1
    for substring in string:gmatch("%S+") do
        if i == 1 then vec["x"] = tonumber(substring) end
        if i == 2 then vec["y"] = tonumber(substring) end
        if i == 3 then vec["z"] = tonumber(substring) end
        i = i + 1
    end
    return vec
end

local function AccumulateScores(closePositions, openPositions, iteration, initPosition, position, target, facing, side)
    local rPos = GetRelativePosition(position, facing, side)
    if not ContainsVecTable(closePositions, rPos) then
        local totalScore = GetTotalScore(initPosition, rPos, target)
        print("Front Score: " .. totalScore)
        if not ContainsVecTable(openPositions, rPos) then
            AddVecTable(openPositions, rPos, {score=totalScore,iter=iteration})
        end
    end
end

function AStar.FaceDirection(facing, dir)
    local toFace = dir - facing

    if toFace == -3 then toFace = 1 end
    if toFace == 3 then toFace = -1 end

    if toFace < 0 then robot.turnLeft(math.abs(toFace))
    else robot.turnRight(toFace) end
end

function AStar.FaceTarget(facing, position, target)
    AStar.FaceDirection(facing, GetDirection(position,target))
end
-- Walks to target with surrounding data (SLOW)
function AStar.WalkToTarget(target)
    local initX,initY,initZ = navigation.getPosition()
    local initPosition = {x=initX,y=initY,z=initZ}
    local closePositions = {[initPosition] = true}
    local iterations = 1

    while true do
        local xx,yy,zz = navigation.getPosition()
        local position = {x=xx,y=yy,z=zz}
        local facing = ConvertSide(navigation.getFacing())
        local openPositions = {}

        if position.x == target.x and position.y == target.y and position.z == target.z then break end

        local values = robot.detectAll()
        for i = 1, 6 do
            if values[1][2] == "passable" or values[1][2] == "air" then
                AccumulateScores(closePositions, openPositions, iterations, initPosition, position, target, facing, i - 1)
            end
        end
        
        local bestKey = nil
        for k, v in pairs(openPositions) do
            if bestKey ~= nil then
                if v.score == openPositions[bestKey].score and v.iter > openPositions[bestKey].iter then bestKey = k end
                if v.score < openPositions[bestKey].score then bestKey = k end
            else bestKey = k end
        end
    
        DumbWalkToTarget(facing, position, StringToVec(bestKey))

        AddVecTable(closePositions, bestKey)
        RemoveVecTable(openPositions, bestKey)
        iterations = iterations + 1
    end
end

return AStar