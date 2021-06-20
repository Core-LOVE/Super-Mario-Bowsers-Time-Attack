local runningbumpty = {}

local npcManager = require("npcManager")
local ai = require("AI/bumptyAI")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})
npcManager.setNpcSettings({
	id = npcID,

	gfxwidth = 40,
	gfxheight = 40,

	width = 28,
	height = 38,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 14,
	framestyle = 1,
	framespeed = 8,

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

	neverstopsliding = false
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
		--HARM_TYPE_OFFSCREEN,
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
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=63,
	}
);

ai.register(npcID)

--these are all constants
local Slide = {
	STATE = 0,
	MAX_LOOP_COUNTER = 50,
	MAX_STOP_LOOP_COUNTER = 48,
	SLIDE_SPEED_MULTIPLIER = 0.98,
	START_FRAME = 7,
	NFRAMES = 7,
}
local Jump = {
	STATE = 1,
	MAX_LOOP_COUNTER = 1,
	MAX_JUMP_FRAMETIMER = 5,
	START_FRAME = 5,
	NFRAMES = 2,
	VER_SPEED = 1,
}
local Look = {
	STATE = 2,
	MAX_LOOP_COUNTER = 4,
	MAX_LOOK_FRAMETIMER = 7,
	START_FRAME = 0,
	NFRAMES = 1,
}
local Walk = {
	STATE = 3,
	MAX_LOOP_COUNTER = 2,
	MAX_FRAME_TIMER = 2,
	START_SPEED = 1,
	SPEED_MULTIPLIER = 0.92,
	START_FRAME = 0,
	NFRAMES = 5,
}
local Bump = {
	STATE = 4,
	MAX_LOOP_COUNTER = 5,
	MAX_STOP_LOOP_COUNTER = 3, --when bumped, it will move for a bit, then stop. it should stop for exactly 3 loop counters (and move for 2)
	START_FRAME = 7,
	NFRAMES = 1,
}
local frame = {
	MAX_FRAME_TIMER = 10
}

local function setFrameValues(data, startframe, nframes, maxtimer, maxloopcounter)
	data.frame.current = 0
	data.frame.currentstartframe = startframe
	data.frame.currentnframes = nframes
	data.frame.maxtimer = maxtimer
	data.frame.timer = data.frame.maxtimer
	data.frame.loopcounter = maxloopcounter
end

local function initSlide(v, data)
	data.state.current = Slide.STATE
	setFrameValues(data, Slide.START_FRAME, Slide.NFRAMES, frame.MAX_FRAME_TIMER, Slide.MAX_LOOP_COUNTER)
end

local function initJump(v, data)
	data.state.current = Jump.STATE
	setFrameValues(data, Jump.START_FRAME, Jump.NFRAMES, Jump.MAX_JUMP_FRAMETIMER, Jump.MAX_LOOP_COUNTER)
end

local function initLook(v, data)
	data.state.current = Look.STATE
	setFrameValues(data, Look.START_FRAME, Look.NFRAMES, Look.MAX_LOOK_FRAMETIMER, Look.MAX_LOOP_COUNTER)
end

local function initWalk(v, data)
	data.state.current = Walk.STATE
	setFrameValues(data, Walk.START_FRAME, Walk.NFRAMES, Walk.MAX_FRAME_TIMER, Walk.MAX_LOOP_COUNTER)
	data.state.direction = player.x < v.x and -1 or 1
	v.direction = data.state.direction
	v.speedX = Walk.START_SPEED * data.state.direction
end

local function initBumping(v, data)
	data.state.current = Bump.STATE
	setFrameValues(data, Bump.START_FRAME, Bump.NFRAMES, frame.MAX_FRAME_TIMER, Bump.MAX_LOOP_COUNTER)
	data.bump.direction = player.x < v.x and 1 or -1
	v.speedX = data.bump.direction == -1 and -3 or 3
	if not NPC.config[v.id].neverstopsliding then
		data.neverstopsliding = false
	end
end

local function init(v, data)
	data.init = true
	data.state = {
		current = 0,
		direction = v.direction,
	}
	data.bump = {
		direction = 0, --this is different from data.state.direction
	}
	data.frame = {
		current = 0,
		currentstartframe = 0,
		currentnframes = 0,
		maxtimer = frame.MAX_FRAME_TIMER,
		timer = frame.MAX_FRAME_TIMER,
		loopcounter = 0 --goes up every time we return to the first frame
	}
	data.neverstopsliding = NPC.config[v.id].neverstopsliding
end

function runningbumpty.onInitAPI()
	npcManager.registerEvent(npcID, runningbumpty, "onTickEndNPC")
	npcManager.registerEvent(npcID, runningbumpty, "onDrawNPC")
end

function runningbumpty.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	if not data.init then
		init(v, data)
		if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then --grabbed/thrown/generated
			data.neverstopsliding = true
			initSlide(v, data)
		else
			initWalk(v, data)
		end
	end

	if v:mem(0x12A, FIELD_WORD) <= 0 then return end --offscreen
	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then return end --grabbed/thrown/generated

	--Collision with player.
	if Colliders.collide(player, v) and not v.friendly then
		initBumping(v, data)
	end

	--movement stuff
	if data.state.current == Bump.STATE then
		if data.frame.loopcounter <= Bump.MAX_STOP_LOOP_COUNTER and v.collidesBlockBottom then --if it should stop moving
			v.speedX = 0
		end
		if (data.frame.loopcounter <= 0 or ai.isNearPit(v)) and v.collidesBlockBottom then --if it should get up
			v.speedX = 0
			initJump(v, data)
		end
	elseif data.state.current == Slide.STATE then
		if v.collidesBlockLeft or v.collidesBlockRight then
			data.state.direction = data.state.direction * -1
		end
		if not data.neverstopsliding then
			v.speedX = v.speedX * Slide.SLIDE_SPEED_MULTIPLIER
			if data.frame.loopcounter <= Slide.MAX_STOP_LOOP_COUNTER then
				v.speedX = 0
			end
			if data.frame.loopcounter <= 0 then
				initJump(v, data)
			end
		end
	elseif data.state.current == Jump.STATE then
		if data.frame.loopcounter > 0 then
			v.speedY = Jump.VER_SPEED * -1
		elseif data.frame.loopcounter <= 0 and v.collidesBlockBottom then
			if v.speedX == 0 then
				initLook(v, data)
			else
				initSlide(v, data)
			end
		end
	elseif data.state.current == Look.STATE then
		if data.frame.timer == 0 then
			data.state.direction = data.state.direction * -1
		end
		if data.frame.loopcounter <= 0 then
			initWalk(v, data)
		end
	elseif data.state.current == Walk.STATE then
		v.speedX = v.speedX / Walk.SPEED_MULTIPLIER
		if data.frame.loopcounter <= 0 then
			initJump(v, data)
		end
	end
end

function runningbumpty.onDrawNPC(v)
	if Misc.isPaused() then return end

	local data = v.data

	if not data.init then
		init(v, data)
	end

	if data.frame.timer == 0 then
		if data.frame.current + 1 == data.frame.currentnframes then
			data.frame.current = 0
			data.frame.loopcounter = data.frame.loopcounter - 1
		else
			data.frame.current = data.frame.current + 1
		end
		data.frame.timer = data.frame.maxtimer
	end
	data.frame.timer = data.frame.timer - 1

	--check for edge cases
	if data.state.current == Slide.STATE and not data.neverstopsliding and data.frame.loopcounter <= Slide.MAX_STOP_LOOP_COUNTER then
		data.frame.current = 6 --(with offset and direction = -1, the actual frame is 14)
		data.frame.loopcounter = data.frame.loopcounter - 1
	elseif data.state.current == Jump.STATE and data.frame.loopcounter <= 0 then
		data.frame.current = 1 --(with offset and direction = -1, the actual frame is 6)
	end

	local offset = data.frame.currentstartframe
	if data.state.direction == 1 then
		offset = offset + NPC.config[v.id].frames
	end

	v.animationFrame = data.frame.current + offset
end

return runningbumpty