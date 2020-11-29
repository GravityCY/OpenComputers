local dirs = {posZ = 1, negX = 2, negZ = 3, posX = 4, posY = 5, negY = 6}
local stringDirs = {"posZ", "negX", "negZ", "posX", "posY", "negY"}

function dirs.ToString(direction)
    return stringDirs[direction]
end

return dirs