local function AddVecTable(table, vec)
    table[vec.x] = {}
    table[vec.x][vec.y] = {}
    table[vec.x][vec.y][vec.z] = {}
    table[vec.x][vec.y][vec.z] = true
end

local initPosition = {x=1,y=2,z=3} -- has value 1,2,3
local closePositions = {} -- set index {1,2,3} to true
AddVecTable(closePositions, initPosition)
local test = {x=1,y=2,z=3} -- has value 1,2,3
print(closePositions[test.x][test.y][test.z]) -- that index does not exist since it doesn't pass by value help