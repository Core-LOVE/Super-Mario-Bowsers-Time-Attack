local n = {}
local npcManager = require("npcManager")

NPC.config[267].speed = 1.5

function n.onInitAPI()
	npcManager.registerEvent(NPC_ID, n, "onTickEndNPC")
end

function n.onTickEndNPC(v)
	if v.dontMove then
		v.dontMove = false
	end
	
	v.ai1 = 0
	v.ai3 = 0
	v.ai4 = 0
	
	if v.data.ai6 == nil then
		v.data.ai6 = 0
	else
		v.data.ai6 = v.data.ai6 + 1
		if v.data.ai6 > 240 then
			local b = NPC.spawn(756, v.x, v.y + 64)
			b.speedY = -7
			b.speedX = 2.25 * v.direction
			b.parent = v
			v.data.ai6 = 0
		end
	end
end

return n