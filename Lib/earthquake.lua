local earthquake = {}
earthquake.shake = 0
earthquake.rot = false

local handycam = require("handycam")
local cam = handycam[1]

function earthquake.pow(shake, rot)
	earthquake.shake = shake or 1
	earthquake.rot = rot or false
end

function earthquake.onInitAPI()
	registerEvent(earthquake, "onCameraUpdate")
end

function earthquake.onCameraUpdate()
	if earthquake.shake > 0 then
		earthquake.shake = earthquake.shake - 0.1
		
		local shake = earthquake.shake
	
		cam.xOffset = math.random(-shake, shake)
		cam.yOffset = math.random(-shake, shake)
		
		if earthquake.rot then
			cam.rotation = math.random(-shake / 8, shake / 8)
		end
	elseif earthquake.shake <= 0 then
		if earthquake.rot then earthquake.rot = false end
		
		cam.xOffset = 0
		cam.yOffset = 0
	end
end

setmetatable(earthquake, {__call = function(self, shake, rot) 
	return earthquake.pow(shake, rot)
end})

return earthquake