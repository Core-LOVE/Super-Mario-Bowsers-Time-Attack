local extendedKoopas = require("extendedKoopas")
local customPlayer = require 'Lib/player'
local hud = require 'Lib/hud'

local anim = require 'Lib/animation'

local animation = {}
animation[10] = anim.new()
do
	local t = {}
	for i = 0,17 do
		t[i] = i
	end
	t.framedelay = 6
	
	animation[10]:defineState(0, t)
	animation[10]:setState(0)
end

function onTickEnd()
	animation[10]:update()
	for k,v in ipairs(NPC.get(10)) do
		v.animationFrame = animation[10]:getFrame()
	end
	
	for k,v in ipairs(Effect.get(11)) do
		local e = Effect.spawn(780, v.x + 16, v.y + 16)
		e.speedY = v.speedY
		e.speedX = v.speedX
		v.id = 0
	end
end