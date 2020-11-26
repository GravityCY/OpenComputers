local component = require("component")
local sides = require("sides")
local robot = require("betterbot")
local navigation = component.navigation
local chargerRelPos = {x=-886,y=69.5,z=135.5}

--[[ Normal Side Values
    Back:   north,  negZ,   Number: 2
    Front:  south,  posZ,   Number: 3
    Right:  west,   negX,   Number: 4
    Left:   east,   posX,   Number: 5
]]--

--[[ My Side Values
    Front:  south,  posZ,   Number: 1
    Right:  west,   negX,   Number: 2
    Back:   north,  negZ,   Number: 3
    Left:   east,   posX,   Number: 4
]]--

local function SideToString(number)
    if number == 1 then return "posZ" end
    if number == 2 then return"negX" end
    if number == 3 then return "negZ" end
    if number == 4 then return "posX" end
    return side
end

local function ConvertSides(number)
    if number == 3 then return 1 end
    if number == 4 then return 2 end
    if number == 2 then return 3 end
    if number == 5 then return 4 end
end

-- Will face towards a given side
local function FaceSide(side)
    local robotFacing = navigation.getFacing()
    robotFacing = ConvertSides(robotFacing)
    turns = side - robotFacing 

    if turns == -3 then turns = 1 end
    if turns == 3 then turns = -1 end
    if turns < 0 then tempTurns = math.abs(turns) robot.turnLeft(tempTurns) end
    if turns > 0 then robot.turnRight(turns) end
end

-- Will return a direction between two vectors
local function GetTargetDirection(target)
    local tempX,_,tempZ = navigation.getPosition()
    local relPos = {x = tempX, z = tempZ}
    local diff = {x = target.x-relPos.x , z = target.z-relPos.z}

    if math.abs(diff.x) > math.abs(diff.z) then
        if diff.x < 0 then return 2 else return 4 end
    else
        if diff.z < 0 then return 3 else return 1 end
    end
end

local function FaceTarget(target)
    direction = GetTargetDirection(target)
    FaceSide(direction)
end

local function WalkToTarget(target)
    local tempX,tempY,tempZ = navigation.getPosition()
    local relPos = {x = tempX, y = tempY, z = tempZ}
    if relPos.x ~= target.x then
        local difference = target.x - relPos.x
        if difference > 0 then FaceSide(4) else FaceSide(2) end
        for i = 1, math.abs(difference) do
            robot.forward()
        end
    end
    if relPos.y ~= target.y then
        local difference = target.y - relPos.y
        local dir = "Up"
        if difference > 0 then dir = "Up" else dir = "Down" end
        for i = 1, math.abs(difference) do
            if dir == "Up" then robot.up() else robot.down() end
        end
    end
    if relPos.z ~= target.z then
        local difference = target.z - relPos.z
        if difference > 0 then FaceSide(1) else FaceSide(3) end
        for i = 1, math.abs(difference) do
            robot.forward()
        end
    end
end

local function GoToTarget(target)
    while true do 
        WalkToTarget(target)
        local tempX,tempY,tempZ = navigation.getPosition()
        local relPos = {x = tempX,y = tempY, z = tempZ}
        if relPos.x == target.x and relPos.y == target.y and relPos.z == target.z then print("At target lol") break end
    end
end

GoToTarget(chargerRelPos)