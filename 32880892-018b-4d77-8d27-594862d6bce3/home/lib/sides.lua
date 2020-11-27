local sides = {forward = 0, right = 1, back = 2, left = 3, up = 4, down = 5}
local sideString = {"Forward", "Right", "Back", "Left", "Up", "Down"}

function sides.ToString(side)
    return sideString[side]
end

return sides