local n = {}
local npcManager = require("npcManager")

function n.onInitAPI()
	npcManager.registerEvent(NPC_ID, n, "onTickEndNPC")
end

function n.onTickEndNPC(v)
	if not v.dontMove then
		v.dontMove = true
		v.speedX = 0
	end
	
	if v.ai1 == 0 and v.ai2 < 60 then
		v.ai1 = 1
		v.ai2 = 200
	end
end

return n