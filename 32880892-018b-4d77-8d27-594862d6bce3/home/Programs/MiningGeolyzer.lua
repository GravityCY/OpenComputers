local robot = require("betterbot")
local comp = require("component")
local geo = comp.geolyzer

local scanDistance = 32

local function danceVertically()
	for i = 0, 1 do
		robot.up()
		robot.down()
	end
end

local function danceHorizontally()
	for i = 0, 1 do
		robot.turnRight()
		robot.turnLeft()
	end
end

local function scanHasBedrock(scanData)
	for i = 1, scanDistance do
		if scanData[i] < -0.3 then print("Scan has bedrock") return true end 
	end
	print("Scan did not have bedrock")
	return false
end

local function distToBedrock(scanData)
	for i = scanDistance, 1, -1 do
		if scanData[i] < -0.3 then print("Distance to reach bedrock: " .. (scanDistance - i)) return scanDistance - i end
	end
end

local timesWentDown = 0
local function mine(distance)
	print("Mining, " .. distance)
	for i = 1, distance do 
		robot.swingDown()
		if robot.down() then timesWentDown = timesWentDown + 1 end
		robot.swing()
	end
end

local function main()
	scanData = geo.scan(0,0,1,1,1,scanDistance * -1)
	while not scanHasBedrock(scanData) do
		mine(scanDistance)
		scanData = geo.scan(0,0,1,1,1,scanDistance * -1)
	end
	local distToBedrock = distToBedrock(scanData)
	mine(distToBedrock)
	for i = 1, timesWentDown do
		if not robot.up() then
			robot.selectSlot(1)
			robot.placeDown()
		end
	end
	robot.placeDown()
	robot.forward()
	robot.placeDown()
	robot.back()
	danceVertically()
	danceHorizontally()
end

main()