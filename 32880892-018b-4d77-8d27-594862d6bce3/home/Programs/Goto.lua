local shell = require("shell")
local astar = require("astar")

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

print("Enter X Y Z (Eg. 1 -2 3): ")
local xyz = io.read()

astar.RunToTarget(StringToVec(xyz))


