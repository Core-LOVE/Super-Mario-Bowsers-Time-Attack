local bumpty = {}

local npcManager = require("npcManager")
local rng = require("rng")
local ai = require("AI/bumptyAI")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})
npcManager.setNpcSettings({
	id = npcID,

	gfxwidth = 40,
	gfxheight = 32,

	width = 28,
	height = 30,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 5,
	framestyle = 1,
	framespeed = 2,

	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = false,

	jumphurt = false,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,
})
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=801,
		[HARM_TYPE_NPC]=801,
		[HARM_TYPE_PROJECTILE_USED]=801,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=801,
		[HARM_TYPE_TAIL]=801,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_SWORD]=63,
	}
);

ai.register(npcID)

--these are all constants
local Look = {
	STATE = 0,
	MAX_TIMER = 12,
	MIN_TIMER = 5,
	MAX_FRAME_TIMER = 40,
	MIN_FRAME_TIMER = 5,
	FRAME = 0,
}
local Walk = {
	STATE = 1,
	MAX_TIMER = 20,
	MIN_TIMER = 5,
	WALK_SPEED = 1,
}
local Bump = {
	STATE = 2,
	MAX_BUMP_TIMER = 10
}

local function init(v, data)
	data.state = {
		current = Look.STATE,
		direction = v.direction,
		currentframe = 0,
		nearpit = false,
	}
	data.walk = {
		timer = 0,
	}
	data.look = {
		timer = 0,
		frameTimer = Look.MAX_FRAME_TIMER,
	}
	data.bump = {
		timer = Bump.MAX_BUMP_TIMER,
		direction = 0,
	}
	data.init = true
end

local function initWalking(v, data)
	data.state.current = Walk.STATE
	local t = rng.randomInt(Walk.MIN_TIMER, Walk.MAX_TIMER) * 10
	data.walk.timer = t
	local d = 0

	local nearpit = ai.isNearPit(v)
	if nearpit then 
		data.state.direction = nearpit
		data.state.nearpit = true
	elseif v.collidesBlockLeft then data.state.direction = 1
	elseif v.collidesBlockRight then data.state.direction = -1
	else
		repeat
			d = rng.randomInt(-1, 1)
		until d ~= 0
		 data.state.direction = d
	end
	v.speedX = Walk.WALK_SPEED * data.state.direction
end

local function initLooking(v, data)
	data.state.current = Look.STATE
	local t = rng.randomInt(Look.MIN_TIMER, Look.MAX_TIMER) * 10
	data.look.timer = t
	data.look.frameTimer = Look.MAX_FRAME_TIMER
	data.state.currentframe = Look.FRAME
	v.direction = data.state.direction
	v.speedX = 0
end

local function initBumping(v, data)
	data.state.current = Bump.STATE
	data.bump.direction = player.x < v.x and 1 or -1
	data.bump.timer = Bump.MAX_BUMP_TIMER
	data.state.currentframe = v.animationFrame
end

function bumpty.onInitAPI()
	npcManager.registerEvent(npcID, bumpty, "onTickEndNPC")
	npcManager.registerEvent(npcID, bumpty, "onDrawNPC")
end

function bumpty.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	if not data.init then
		init(v, data)
		initLooking(v, data)
	end

	if v:mem(0x12A, FIELD_WORD) <= 0 then return end --offscreen

	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then --grabbed/thrown/generator
		if not data.state.isWalking then
			initWalking(v, data)
		end
		v.speedX = Walk.WALK_SPEED * v.direction
		return
	end

	--Collision with player.
	if Colliders.collide(player, v) and not v.friendly then
		initBumping(v, data)
	end

	--Bump when npc and player have collided
	if data.state.current == Bump.STATE then
		v.speedX = data.bump.direction == -1 and -3 or 3
		data.bump.timer = data.bump.timer - 1
		if ai.isNearPit(v) or v.collidesBlockLeft or v.collidesBlockRight or data.bump.timer == 0 then
			initLooking(v, data)
		end
	elseif data.state.current == Look.STATE and not data.state.isBumped then
		data.look.timer = data.look.timer - 1
		if data.look.timer == 0 and not v.dontMove then --finished looking
			initWalking(v, data)
		end
	elseif data.state.current == Walk.STATE and not data.state.isBumped then
		data.walk.timer = data.walk.timer - 1
		if data.state.nearpit and not ai.isNearPit(v) then
			data.state.nearpit = false
		end
		--Don't go to the looking state if it's near a pit! Instead, it should keep walking to the opposite direction.
		if not data.state.nearpit then
			if data.walk.timer == 0 or v.collidesBlockLeft or v.collidesBlockRight or ai.isNearPit(v) then
				initLooking(v, data)
			end
		end
	end
end

function bumpty.onDrawNPC(v)
	if Misc.isPaused() then return end

	local data = v.data
	if not data.init then
		init(v, data)
	end

	if data.state.current == Walk.STATE then return end --for walking, we can default to everything

	local offset = 0
	if data.state.current == Look.STATE then
		data.look.frameTimer = data.look.frameTimer - 1
		if data.look.frameTimer == 0 then
			data.look.frameTimer = rng.randomInt(Look.MIN_FRAME_TIMER, Look.MAX_FRAME_TIMER)
			data.state.direction = data.state.direction * -1
		end
		if data.state.direction == 1 then
			offset = offset + NPC.config[v.id].frames
		end
	end
	v.animationFrame = data.state.currentframe + offset
end

return bumpty