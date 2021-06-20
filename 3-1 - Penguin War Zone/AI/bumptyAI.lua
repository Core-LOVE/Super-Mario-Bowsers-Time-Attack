local bumptyAI = {}
local npcManager = require("npcManager")
local npcIDs = {}

function bumptyAI.register(id)
    npcManager.registerEvent(id, bumptyAI, "onTickEndNPC")
    npcIDs[id] = true
end

function bumptyAI.onInitAPI()
	registerEvent(bumptyAI, "onNPCHarm")
end

local function doCollision(p, v)
	if Colliders.collide(p, v) and not v.friendly and p:mem(0x13E, FIELD_WORD) == 0 then
		p:mem(0x40, FIELD_WORD, 0) --player climbing state, if he's climbing then have him stop climbing
		Audio.playSFX(24) --bump sound
		p.speedX = Defines.player_runspeed
		if p.x < v.x then
			p.speedX = p.speedX * -1
		end
	end
end

function bumptyAI.isNearPit(v)
	--this function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Colliders.BLOCK_SOLID
	for _, w in ipairs(Colliders.BLOCK_SEMISOLID) do table.insert(testblocks, w) end

	local centerbox = Colliders.Box(v.x + 8, v.y, 8, 48)
	if Colliders.collideBlock(centerbox, testblocks) then
		return false
	end

	local leftbox = Colliders.Box(v.x - 8, v.y, 8, 48) --Draw a box to the left of the npc. This is used to get what direction should the npc move to.
	if Colliders.collideBlock(leftbox, testblocks) then
		return -1 --means the pit is on the RIGHT, so the npc should go to the left
	else
		return 1
	end
end

function bumptyAI.onTickEndNPC(v)
    if Defines.levelFreeze then return end

	if v:mem(0x12A, FIELD_WORD) <= 0 then return end --offscreen
	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then 
		for _, p in ipairs(Player.get()) do
			doCollision(p, v)
		end
		return
	end --grabbed/thrown/generated

	--Collision with player.
	for _, p in ipairs(Player.get()) do
		doCollision(p, v)
	end

	--do not show the smoke effect that appears when you jump on the npc
	for _, e in ipairs(Animation.getIntersecting(v.x, v.y, v.x + 32, v.y + 32)) do
		e.width = 0
		e.height = 0
	end
end

function bumptyAI.onNPCHarm(eventObj, v, killReason, culprit)
	if not npcIDs[v.id] then return end

	if killReason ~= HARM_TYPE_JUMP and killReason ~= HARM_TYPE_SPINJUMP then return end

	eventObj.cancelled = true
	player.speedY = 1
	Audio.playSFX(24)
end

return bumptyAI