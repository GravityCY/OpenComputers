local bot = require("robot")

local sleepTime = 1

local robot = {}

function robot.up(pauseIfObstruct, breakIfObstruct)
  pauseIfObstruct = pauseIfObstruct or false
  breakIfObstruct = breakIfObstruct or false

  if pauseIfObstruct then
    while not bot.up() do os.sleep(sleepTime) end
    return true
  end
  if breakIfObstruct then
    while not bot.up() do bot.swingUp() end
    return true
  else return bot.up() end
end

function robot.down(pauseIfObstruct, breakIfObstruct)
  pauseIfObstruct = pauseIfObstruct or false
  breakIfObstruct = breakIfObstruct or false

  if pauseIfObstruct then
    while not bot.down() do os.sleep(sleepTime) end
    return true
  end
  if breakIfObstruct then
    while not bot.down() do bot.swingDown() end
    return true
  else return bot.down() end
end

function robot.forward(pauseIfObstruct, breakIfObstruct)
  pauseIfObstruct = pauseIfObstruct or false
  breakIfObstruct = breakIfObstruct or false

  if pauseIfObstruct then
    while not bot.forward() do os.sleep(sleepTime) end
    return true
  end
  if breakIfObstruct then
    while not bot.forward() do bot.swing() end
    return true
  else return bot.forward() end
end
  
function robot.back(pauseIfObstruct, breakIfObstruct)
  pauseIfObstruct = pauseIfObstruct or false
  breakIfObstruct = breakIfObstruct or false

  if pauseIfObstruct then
    while not bot.back() do os.sleep(sleepTime) end
    return true
  end
  if breakIfObstruct then
    while not bot.back() do
      bot.turnAround() 
      swing = bot.swing()
      bot.turnAround() 
      return swing
    end
    return true
  else return bot.back() end
end

function robot.right(pauseIfObstruct, breakIfObstruct)
  bot.turnRight()
  return forward(pauseIfObstruct)
end

function robot.left(pauseIfObstruct, breakIfObstruct)
  bot.turnLeft()
  return forward(pauseIfObstruct)
end

function robot.turnLeft()
  return bot.turnLeft()
end

function robot.turnRight()
  return bot.turnRight()
end

function robot.turnAround()
  bot.turnRight()
  return bot.turnRight()
end

function robot.drop()
  return bot.drop()
end

function robot.swing()
  return bot.swing()
end

function robot.swingUp()
  return bot.swingUp()
end

function robot.swingDown()
  return bot.swingDown()
end

function robot.inventorySize()
  return bot.inventorySize()
end

function robot.select(itemSlot)
  return bot.select(itemSlot)
end

function robot.detect()
  return bot.detect()
end

function robot.detectUp()
  return bot.detectUp()
end

function robot.detectDown()
  return bot.detectDown()
end

return robot