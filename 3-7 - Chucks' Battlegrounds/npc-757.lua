local npc = {}
local npcID = NPC_ID

local npcSettings = {
	id = NPC_ID,
	gfxheight = 28,
	gfxwidth = 32,
	width = 32,
	height = 28,
	frames = 1,
	framestyle = 1,
	framespeed = 1,
	speed = 1,
	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = false,
	noyoshi= false,
	noshell= false,
	nohammer= false,
	nowaterphysics = false
}

do
	local npcManager = require("npcManager")
	
	npcManager.registerHarmTypes(npcID,{HARM_TYPE_JUMP,HARM_TYPE_NPC,HARM_TYPE_PROJECTILE_USED,HARM_TYPE_SPINJUMP,}, {[HARM_TYPE_JUMP]=757, [HARM_TYPE_NPC]=757, [HARM_TYPE_PROJECTILE_USED]=757, [HARM_TYPE_SPINJUMP]=757});
										
	npcManager.setNpcSettings(npcSettings)
	npcManager.registerDefines(npcID, {NPC.HITTABLE})
	
	function npc.onInitAPI()
		npcManager.registerEvent(npcID, npc, "onTickNPC")	
		registerEvent(npc, "onNPCHarm")	
	end
end

function npc.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.p = Player.getNearest(v.x, v.y)
		data.old_direction = v.direction
		data.initialized = true
	end	
	
	if v.ai3 < 3 then
		local p = data.p
		v.speedX = math.clamp(v.speedX, -5, 5)
	
		if v.x + (0.5 * v.width) > p.x + (0.5 * p.width) then
			v.speedX = v.speedX - 0.1
		else
			v.speedX = v.speedX + 0.1
		end
		
		if math.random(0,16) > 8 then
			local d = (v.direction == 1 and -8) or (v.direction == -1 and (v.width - 4))
			
			local e = Effect.spawn(74, v.x + d, v.y + v.height / 2)
			e.speedX, e.speedY = (math.random() * -v.direction), math.random(-1, 1)	
		end
	elseif v.ai3 >= 3 then
		if not v.friendly then v.friendly = true end
		
		v.speedY = v.speedY + 0.24
	end
	
	if data.old_direction ~= v.direction then
		v.ai3 = (v.ai3 + 1)
		
		local d = (v.direction == 1 and -32) or (v.direction == -1 and v.width)
		
		Effect.spawn(131, v.x + d, v.y).speedX = (math.random(0,2) * -v.direction)
		data.old_direction = v.direction
	end
end

return npc