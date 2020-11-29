local component = require("component")
local robot = require("betterbot")
local sides = require("gsides")
local dirs = require("directions")

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

-- == Private methods == --

    -- Converts the sides api to my sides
    local function ConvertSide(number)
        if number == 3 then return 1 end
        if number == 4 then return 2 end
        if number == 2 then return 3 end
        if number == 5 then return 4 end
        if number == 1 then return 5 end
        if number == 0 then return 6 end
    end

    -- Copies a vector
    local function Copy(vector)
        return {x=vector.x, y=vector.y, z=vector.z}
    end

    -- Converts a vector into a string
    local function VecToString(vector)
        if type(vector) == "string" then return vector end
        if type(vector) ~= "table" then return nil end

        return vector.x .. " " .. vector.y .. " " .. vector.z
    end

    -- Converts a vector string to a vector
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

    -- Adds a avector to a table
    local function AddVecTable(table, key, value)
        value = value or true
        table[VecToString(key)] = value
    end

    -- Checks if a vector is inside a table
    local function ContainsVecTable(table, vec)
        return table[VecToString(vec)] ~= nil
    end

    -- Removes a vector from a table
    local function RemoveVecTable(table, vec)
        table[VecToString(vec)] = nil
    end

    -- Returns an absolute version of a given vector
    local function VecAbs(vector)
        return {x=math.abs(vector.x),y=math.abs(vector.y),z=math.abs(vector.z)}
    end

    -- Gets the difference between two vectors
    local function GetDifference(position, target)
        local difference = {x = target.x - position.x, y = target.y - position.y, z = target.z - position.z}
        return difference
    end

    -- Gets the direction based off a position and a target
    local function GetDirection(position, target)
        local difference = GetDifference(position, target)
        local absDifference = VecAbs(difference)

        if absDifference.x >= absDifference.z and absDifference.x >= absDifference.y then
            if difference.x > 0 then return dirs.posX else return dirs.negX end
        elseif absDifference.y >= absDifference.x and absDifference.y >= absDifference.z then
            if difference.y > 0 then return dirs.posY else return dirs.negY end
        elseif absDifference.z >= absDifference.x and absDifference.z >= absDifference.y then
            if difference.z > 0 then return dirs.posZ else return dirs.negZ end
        end
    end

    -- Gets the total scoring for a position
    local function GetTotalScore(position, target)
        local targetDistance = math.abs(target.x - position.x) + math.abs(target.y - position.y) + math.abs(target.z - position.z)
        return targetDistance
    end

    local function WrapAround(value, min, max)
        max = max + 1
        return (((value - min) % (max - min)) + (max - min)) % (max - min) + min
    end

    -- Gets a neighbor position towards direction
    local function GetRelativePosition(pos, facing, side)
        local position = Copy(pos)

        if side == sides.up then position.y = position.y + 1 return position end
        if side == sides.down then position.y = position.y - 1 return position end

        local out = facing + side
        out = WrapAround(out, 1, 4)

        if out == dirs.negX then position.x = position.x - 1 end
        if out == dirs.negZ then position.z = position.z - 1 end
        if out == dirs.posX then position.x = position.x + 1 end
        if out == dirs.posZ then position.z = position.z + 1 end

        return position
    end

    -- Goes through a table of position and returns the lowest scoring position (golf)
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

    local function FaceTarget(facing, position, target)
        local direction = GetDirection(position, target)
        if direction == dirs.posY then return sides.up
        elseif direction == dirs.negY then return sides.down else
            AStar.FaceDirection(facing, direction)
        end
    end

    -- Walks towards a target
    local function DumbWalkToTarget(facing, position, target, pause)
        pause = pause or false

        local side = FaceTarget(facing, position, target)
        if side == nil then return robot.go(sides.forward, pause) else return robot.go(side, pause) end
    end

    local function AccumulateScores(lockPos, it, curPos, target, facing)
        local openPos = {}

        local values = robot.detectAll()
        for i = 1, 6 do
            local state = values[i][2]
            if state == "air" then
                local rPos = GetRelativePosition(curPos, facing, i - 1)
                if not ContainsVecTable(lockPos, rPos) then
                    local totalScore = GetTotalScore(rPos, target)
                    AddVecTable(openPos, rPos, {score=totalScore,iter=it})
                end
            end
        end

        return openPos
    end
--

-- == Public methods == --

    -- Returns a vector position
    function AStar.GetPosition()
        local xx,yy,zz = navigation.getPosition()
        return {x=xx,y=yy,z=zz}
    end

    -- Returns the robots facing direction
    function AStar.GetFacing()
        return ConvertSide(navigation.getFacing())
    end

    -- Faces towards a given direction
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
        local sPos = AStar.GetPosition()
        local lPos = {}
        AddVecTable(lPos, sPos)

        local it = 1
        while true do
            local pos = AStar.GetPosition()
            local facing = AStar.GetFacing()

            if pos.x == target.x and pos.y == target.y and pos.z == target.z then break end

            local ulPos = AccumulateScores(lPos, it ,pos,target,facing)
            local bestPos = GetBestPosition(ulPos)
            DumbWalkToTarget(facing, pos, bestPos, true)

            AddVecTable(lPos, bestPos)
            RemoveVecTable(ulPos, bestPos)
            it = it + 1
        end
    end

    -- Walks to target with trial and error (FAST, ERROR PRONE: MAKE SURE NOT TO GET IT INTO A POSITION WHERE IT CAN ONLY MOVE BACKWARDS)
    function AStar.RunToTarget(target)
        local sPos = AStar.GetPosition()
        local lPos = {}
        AddVecTable(lPos, sPos)

        local it = 1
        while true do
            local pos = AStar.GetPosition()
            local facing = AStar.GetFacing()
            local side = sides.forward

            if pos.x == target.x and pos.y == target.y and pos.z == target.z then break end

            local dir = GetDirection(pos, target)
            AStar.FaceDirection(facing, dir)
            if dir == dirs.negY then side = sides.down
            elseif dir == dirs.posY then side = sides.down
            else facing = dir end
            local rePos = GetRelativePosition(pos, facing, side)
            if not ContainsVecTable(lPos, rePos) then
                if not DumbWalkToTarget(facing, pos, rePos) then
                    local ulPos = AccumulateScores(lPos,it,pos,target,facing)
                    local bPos = GetBestPosition(ulPos)
                    DumbWalkToTarget(facing, pos, bPos, true)
                    AddVecTable(lPos, bPos, true)
                else AddVecTable(lPos, rePos, true) end
            else
                local ulPos = AccumulateScores(lPos,it,pos,target,facing)
                local bPos = GetBestPosition(ulPos)
                DumbWalkToTarget(facing, pos, bPos, true)
                AddVecTable(lPos, bPos, true) 
            end
            it = it + 1
        end
    end


    -- Walks to target by going through rotating directions, in order not to rotate as much
    function AStar.FlashToTarget(target)
        local facing = AStar.GetFacing()

        local sX,sY,sZ = navigation.getPosition()
        local sPos = {x=sX,y=sY,z=sZ}
        local pos = Copy(sPos)

        local axes = {x=0, z=1, y=2}
        local axis = axes.x

        local prevPos = {}
        local sameTimes = 0
        while true do
            if pos.x == target.x and pos.y == target.y and pos.z == target.z then break end
            local tMod = Copy(target)
            if axis == axes.x then
                tMod.y = pos.y
                tMod.z = pos.z
            elseif axis == axes.z then
                tMod.x = pos.x
                tMod.y = pos.y
            elseif axis == axes.y then
                tMod.x = pos.x
                tMod.z = pos.z
            end

            local tDir = GetDirection(pos, tMod)

            if axis ~= axes.y then
                AStar.FaceDirection(facing, tDir)
                facing = tDir
            end

            while true do
                if (axis == axes.x and pos.x == target.x) or
                   (axis == axes.y and pos.y == target.y) or
                   (axis == axes.z and pos.z == target.z)
                then AStar.RunToTarget(target) return end

                if axis ~= axes.y then
                    if not robot.go(sides.forward) then axis = WrapAround(axis + 1, 0, 2) break
                    else pos = GetRelativePosition(pos, facing, sides.forward) end
                else
                    if tDir == dirs.posY then
                        if not robot.go(sides.up) then axis = WrapAround(axis + 1, 0, 2) break
                        else pos = GetRelativePosition(pos, facing, sides.up) end
                    else
                        if not robot.go(sides.down) then axis = WrapAround(axis + 1, 0, 2) break
                        else pos = GetRelativePosition(pos, facing, sides.down) end
                    end
                end
                if prevPos == pos then sameTimes = sameTimes + 1 end
                if sameTimes == 3 then AStar.RunToTarget(target) return end
                prevPos = pos
            end
        end
    end
--

return AStar