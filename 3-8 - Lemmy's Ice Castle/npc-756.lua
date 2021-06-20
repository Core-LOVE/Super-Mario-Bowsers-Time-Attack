local n = {}
local npcManager = require("npcManager")

NPC.config[NPC_ID].nogravity = true
NPC.config[NPC_ID].frames = 4

npcManager.registerHarmTypes(NPC_ID, {HARM_TYPE_JUMP}, {})

function n.onInitAPI()
	npcManager.registerEvent(NPC_ID, n, "onTickEndNPC")
	registerEvent(n, "onNPCHarm")
	registerEvent(n, "onPostNPCHarm")
end

local function kill_it(v)
	Effect.spawn(131, v.x, v.y)
	v:kill(9)
end

function n.onNPCHarm(e, v, r, c)
	if v.id ~= NPC_ID then return end
	
	if r == 1 then
		SFX.play(2)
		v.ai2 = v.animationFrame
		v.ai1 = -16
		e.cancelled = true
	end
end

function n.onTickEndNPC(v)
	if v.ai1 >= 0 then
		v.speedY = v.speedY + 0.105
		v.ai3 = v.ai3 + 1
		if v.collidesBlockBottom then
			v.speedY = -7
			v.speedX = 2.25 * v.direction
		end
		if v.ai3 > 1280 then
			kill_it(v)
		end
	elseif v.ai1 < 0 then
		v.speedX = 0
		v.speedY = 0
		v.ai1 = v.ai1 + 1
		
		local rt = {
		[1] = v.ai2,
		[2] = v.ai2 + 4
		}
		
		local r = math.floor(math.random(1,2))
		v.animationFrame = rt[r]
	end
	
	if v.parent ~= nil then
		if not v.parent.isValid then
			kill_it(v)
		end
	end
end

return n