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

local function ConvertSide(number)
    if number == 3 then return 1 end
    if number == 4 then return 2 end
    if number == 2 then return 3 end
    if number == 5 then return 4 end
end

-- Will face towards a given side
local function FaceSide(side)
    local robotFacing = navigation.getFacing()
    robotFacing = ConvertSide(robotFacing)
    local turns = side - robotFacing 

    if turns == -3 then turns = 1 end
    if turns == 3 then turns = -1 end
    if turns < 0 then tempTurns = math.abs(turns) robot.turnLeft(tempTurns) end
    if turns > 0 then robot.turnRight(turns) end
end


--[[ My Side Values
    Front:  south,  posZ,   Number: 1
    Right:  west,   negX,   Number: 2
    Back:   north,  negZ,   Number: 3
    Left:   east,   posX,   Number: 4
]]--
local function relativePosition(position, facing, direction)    
    if direction == "Up" then
        position.y = position.y + 1 
        return position
    end
    if direction == "Down" then position.y = position.y - 1 return position end

    -- facing posZ
    if facing == 1 then 
        if direction == "Forward" then position.z = position.z + 1 return position end
        if direction == "Back" then position.z = position.z - 1 return position   end
        if direction == "Left" then position.x = position.x + 1 return position   end
        if direction == "Right" then position.x = position.x - 1 return position  end 
    end
    -- facing negX
    if facing == 2 then 
        if direction == "Forward" then position.x = position.x - 1 return position  end
        if direction == "Back" then position.x = position.x + 1 return position   end
        if direction == "Left" then position.z = position.z + 1 return position   end
        if direction == "Right" then position.z = position.z - 1 return position  end 
    end
    -- facing negZ
    if facing == 3 then
        if direction == "Forward" then position.z = position.z - 1 return position  end
        if direction == "Back" then position.z = position.z + 1 return position   end
        if direction == "Left" then position.x = position.x - 1 return position   end
        if direction == "Right" then position.x = position.x + 1 return position  end 
    end
    -- facing posX
    if facing == 4 then 
        if direction == "Forward" then position.x = position.x + 1 return position  end
        if direction == "Back" then position.x = position.x - 1 return position  end 
        if direction == "Left" then position.z = position.z - 1 return position   end
        if direction == "Right" then position.z = position.z + 1 return position  end 
    end
end

local function CalculateScore(thPosition, startPos, target)
    local aDistScore = math.abs((startPos.x - thPosition.x) + (startPos.y - thPosition.y) + (startPos.z - thPosition.z))
    local tDistScore = math.abs((target.x - thPosition.x) + (target.y - thPosition.y) + (target.z - thPosition.z))
    return aDistScore, tDistScore
end


local function WalkToTarget(target)
    local tmpX,tmpY,tmpZ = navigation.getPosition()
    local startPos = {x=tmpX,y=tmpY,z=tmpZ}
    local table = {}
    local iter = 1

    while true do
        local xx,yy,zz = navigation.getPosition()
        local relPos = {x=xx,y=yy,z=zz}
        local facing = ConvertSide(navigation.getFacing())
        if relPos == target then break end

        if robot.detect("air") then
            local thPos = relativePosition(relPos, facing, "Forward")
            local aDistScore, tDistScore = CalculateScore(thPos, startPos, target)
            table[iter] = {pos=thPos, to=aDistScore + tDistScore, d = "Forward", o = true}
        end
        if robot.detectUp("air") then
            local thPos = relativePosition(relPos, facing, "Up")
            local aDistScore, tDistScore = CalculateScore(thPos, startPos, target)
            table[iter] = {pos=thPos, to=aDistScore + tDistScore, d = "Up", o = true}
        end
        if robot.detectDown("air") then
            local thPos = relativePosition(relPos, facing, "Down")
            local aDistScore, tDistScore = CalculateScore(thPos, startPos, target)
            table[iter] = {pos=thPos, to=aDistScore + tDistScore, d = "Down", o = true}
        end
        if robot.detectLeft("air") then
            local thPos = relativePosition(relPos, facing, "Left")
            local aDistScore, tDistScore = CalculateScore(thPos, startPos, target)
            table[iter] = {pos=thPos, to=aDistScore + tDistScore, d = "Left", o = true}
        end
        if robot.detectRight("air") then
            local thPos = relativePosition(relPos, facing, "Right")
            local aDistScore, tDistScore = CalculateScore(thPos, startPos, target)
            table[iter] = {pos=thPos, to=aDistScore + tDistScore, d = "Right", o = true}
        end
        if robot.detectBack("air") then
            local thPos = relativePosition(relPos, facing, "Back")
            local aDistScore, tDistScore = CalculateScore(thPos, startPos, target)
            table[iter] = {pos=thPos, to=aDistScore + tDistScore, d = "Back", o = true}
        end

        os.sleep(2)

        local bestIndex = 1
        for i = 1, #table do
            local current = table[i]
            if current.o and current.to <= table[bestIndex].to then bestIndex = i end
        end

        table[bestIndex].o = false
        robot.go(table[bestIndex].d)
        
        iter = iter + 1
    end
end

WalkToTarget(chargerRelPos)