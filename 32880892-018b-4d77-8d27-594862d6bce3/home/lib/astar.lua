local component = require("component")
local robot = require("betterbot")
local sides = require("gsides")
local dirs = require("directions")
local test =require("sides")

local navigation = component.navigation
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
    posZ,   Number: 1
    negX,   Number: 2
    negZ,   Number: 3
    posX,   Number: 4
    posY,   Number: 5
    negY,   Number: 6
]]--

local function ConvertSide(number)
    if number == 3 then return 1 end
    if number == 4 then return 2 end
    if number == 2 then return 3 end
    if number == 5 then return 4 end
    if number == 1 then return 5 end
    if number == 0 then return 6 end
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

local function VecToString(vector)
    if type(vector) == "string" then return vector end
    if type(vector) ~= "table" then return nil end

    return vector.x .. " " .. vector.y .. " " .. vector.z
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

local function GetDirection(position, target)
    local difference = {x= target.x - position.x, y= target.y - position.y, z= target.z - position.z}
    local absDifference = {x=math.abs(difference.x), y=math.abs(difference.y), z=math.abs(difference.z)}

    if absDifference.x >= absDifference.z and absDifference.x >= absDifference.y then
        if difference.x > 0 then return dirs.posX else return dirs.negX end
    elseif absDifference.y >= absDifference.x and absDifference.y >= absDifference.z then
        if difference.y > 0 then return dirs.posY else return dirs.negY end
    elseif absDifference.z >= absDifference.x and absDifference.z >= absDifference.y then
        if difference.z > 0 then return dirs.posZ else return dirs.negZ end
    end
end

local function GetTotalScore(position, target)
    local targetDistance = math.abs(target.x - position.x) + math.abs(target.y - position.y) + math.abs(target.z - position.z)
    return targetDistance
end

local function GetRelativePosition(pos, facing, side)
    local position = Copy(pos)

    if side == sides.up then position.y = position.y + 1 return position end
    if side == sides.down then position.y = position.y - 1 return position end

    local out = facing + side
    out = (((out - 1) % (5 - 1)) + (5 - 1)) % (5 - 1) + 1
    
    if out == dirs.negX then position.x = position.x - 1 end
    if out == dirs.negZ then position.z = position.z - 1 end
    if out == dirs.posX then position.x = position.x + 1 end
    if out == dirs.posZ then position.z = position.z + 1 end

    return position
end

local function GetBestPosition(unlockPos)
    local bestKey = nil
    for k, v in pairs(unlockPos) do
        local data = unlockPos[bestKey]
        if bestKey ~= nil then
            if v.score == data.score and v.iter > data.iter then bestKey = k end
            if v.score < data.score then bestKey = k end
        else bestKey = k end
    end
    return StringToVec(bestKey)
end

local function DumbWalkToTarget(facing, position, target, pause)
    pause = pause or false

    local direction = GetDirection(position, target)
    if direction == dirs.posY then return robot.go(sides.up) 
    elseif direction == dirs.negY then return robot.go(sides.down) else
        AStar.FaceDirection(facing, direction)
        return robot.go(sides.forward, pause)
    end
end

local function AccumulateScores(lockPos, openPos, it, curPos, target, facing)
    local values = robot.detectAll()
    for i = 1, 6 do
        local state = values[i][2]
        if state == "passable" or state == "air" then
            local rPos = GetRelativePosition(curPos, facing, i - 1)
            if not ContainsVecTable(lockPos, rPos) then
                local totalScore = GetTotalScore(rPos, target)
                AddVecTable(openPos, rPos, {score=totalScore,iter=it})
            end
        end
    end
end

function AStar.GetPosition()
    local xx,yy,zz = navigation.getPosition()
    return {x=xx,y=yy,z=zz}
end

function AStar.GetFacing()
    return ConvertSide(navigation.getFacing())
end

function AStar.FaceDirection(facing, dir)
    if dir == nil or dir == dirs.posY or dir == dirs.negY then return end

    local toFace = dir - facing

    if toFace == -3 then toFace = 1 end
    if toFace == 3 then toFace = -1 end

    if toFace < 0 then robot.turn(sides.left, math.abs(toFace))
    else robot.turn(sides.right, toFace) end
end

-- Walks to target with surrounding data (SLOW)
function AStar.WalkToTarget(target)
    local sX,sY,sZ = navigation.getPosition()
    local sPos = {x=sX,y=sY,z=sZ}
    local lPos = {[sPos] = true}

    local it = 1
    while true do
        local pos = AStar.GetPosition()
        local facing = AStar.GetFacing()
        local ulPos = {}
    
        if pos.x == target.x and pos.y == target.y and pos.z == target.z then break end

        AccumulateScores(lPos,ulPos, it ,pos,target,facing)
        local bestPos = GetBestPosition(ulPos)  
        DumbWalkToTarget(facing, pos, bestPos, true)

        AddVecTable(lPos, bestPos)
        RemoveVecTable(ulPos, bestPos)
        it = it + 1
    end
end

-- Walks to target with trial and error (FAST, ERROR PRONE: MAKE SURE NOT TO GET IT INTO A POSITION WHERE IT CAN ONLY MOVE BACKWARDS)
function AStar.RunToTarget(target)
    local sX,sY,sZ = navigation.getPosition()
    local sPos = {x=sX,y=sY,z=sZ}
    local lPos = {}
    lPos[sPos] = true

    local prevPos

    local it = 1
    while true do
        local pos = AStar.GetPosition()
        local facing = AStar.GetFacing()
        local ulPos = {}
        local side = sides.forward

        if pos.x == target.x and pos.y == target.y and pos.z == target.z then break end

        local dir = GetDirection(pos, target)
        AStar.FaceDirection(facing, dir)
        if dir == dirs.negY then side = sides.down 
        elseif dir == dirs.posY then side = sides.down 
        else facing = dir end
        local rePos = GetRelativePosition(pos, facing, side)
        if not ContainsVecTable(lPos, rePos) and not DumbWalkToTarget(facing, pos, rePos) then 
            local values = robot.detectAll()
            for i = 1, 6 do
                local state = values[i][2]
                if state == "passable" or state == "air" then
                    local rPos = GetRelativePosition(pos, facing, i - 1)
                    if not ContainsVecTable(lPos, rPos) then
                        local totalScore = GetTotalScore(rPos, target)
                        AddVecTable(ulPos, rPos, {score=totalScore,iter=it})
                    end
                end
            end
            local bPos = GetBestPosition(ulPos)
            DumbWalkToTarget(facing, pos, bPos, true)
            AddVecTable(lPos, bPos, true)
        else AddVecTable(lPos, rePos, true) end
        prevPos = rePos
        it = it + 1
    end
end

return AStar