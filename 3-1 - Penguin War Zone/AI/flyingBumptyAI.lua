local flyingbumptyAI = {}

local npcManager = require("npcManager")

local npcIDs = {}

local MAX_SPEED = 1
local MIN_SPEED = 0.3
local MAX_PERIOD_COUNTER = 1
local MAX_FRAME_TIMER = 5
local TIME_STEP = 0.5
local PERIOD_CONSTANT = 2 * math.pi
local Fly = {
	STATE = 0,
	START_FRAME = 0,
	NFRAMES = 2,
	MAX_VER_LOOPCOUNTER = 10,
	SPEED_MULTIPLIER = 0.98
}
local Stop = {
	STATE = 1,
	START_FRAME = 2,
	NFRAMES = 2,
	MAX_VER_LOOPCOUNTER = 10,
	SPEED_MULTIPLIER = 0.98
}
local Turn = {
	STATE = 2,
	START_FRAME = 4,
	NFRAMES = 1,
	MAX_LOOP_COUNTER = 2,
	MAX_FRAME_TIMER = 3,
}

local function init(v, data)
	data.state = {
		current = 0,
		direction = v.direction,
	}
	data.move = {
		nextperiod = 2*math.pi,
		time = 0,
		speed = MIN_SPEED * data.state.direction,
		periodcounter = MAX_PERIOD_COUNTER,

		horizontal = data._basegame.isHorizontal,
	}
	data.frame = {
		current = 0,
		currentnframes = 0,
		currentstartframe = 0,
		timer = MAX_FRAME_TIMER,
		loopcounter = 0,
	}
	data.init = true
end

local function setValues(data, frametimer, startframe, nframes, loopcounter)
	--set various values (mostly for frames, but there's also period counter)
	data.frame.current = 0
	data.frame.currentstartframe = startframe
	data.frame.currentnframes = nframes
	data.frame.timer = frametimer
	data.frame.loopcounter = loopcounter
	data.move.periodcounter = MAX_PERIOD_COUNTER
end

local function initFly(v, data)
	data.state.current = Fly.STATE
	setValues(data, MAX_FRAME_TIMER, Fly.START_FRAME, Fly.NFRAMES, Fly.MAX_VER_LOOPCOUNTER)
	data.move.speed = MIN_SPEED * data.state.direction
end

local function initStop(v, data)
	data.state.current = Stop.STATE
	setValues(data, MAX_FRAME_TIMER, Stop.START_FRAME, Stop.NFRAMES, Stop.MAX_VER_LOOPCOUNTER)
end

local function initTurn(v, data)
	data.state.current = Turn.STATE
	setValues(data, Turn.MAX_FRAME_TIMER, Turn.START_FRAME, Turn.NFRAMES, Turn.MAX_LOOP_COUNTER)
	data.move.speed = 0
end

function flyingbumptyAI.register(id, horizontal, shouldturn)
    npcManager.registerEvent(id, flyingbumptyAI, "onTickEndNPC")
    npcManager.registerEvent(id, flyingbumptyAI, "onDrawNPC")
    npcIDs[id] = {
        isHorizontal = horizontal,
        turns = shouldturn,
    }
end

function flyingbumptyAI.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
	if not data.init then
		init(v, data)
		initFly(v, data)
		if not npcIDs[v.id].turns then data.move.speed = MAX_SPEED * data.state.direction end
		if not npcIDs[v.id].isHorizontal then v.speedX = 0 end
	end

	if v:mem(0x12A, FIELD_WORD) <= 0 then return end --offscreen

	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x138, FIELD_WORD) > 0 then return end

    --movement stuff
	if data.state.current == Fly.STATE then
		if math.abs(data.move.speed) < MAX_SPEED then
			data.move.speed = data.move.speed / Fly.SPEED_MULTIPLIER
		end
		if (data.move.periodcounter == 0 or data.frame.loopcounter <= 0 and not npcIDs[v.id].isHorizontal) and npcIDs[v.id].turns then
			initStop(v, data)
		end
	elseif data.state.current == Stop.STATE then
		data.move.speed = data.move.speed * Stop.SPEED_MULTIPLIER
		if data.move.periodcounter == 0 or data.frame.loopcounter <= 0 and not npcIDs[v.id].isHorizontal then
			initTurn(v, data)
		end
	elseif data.state.current == Turn.STATE then
		if data.frame.loopcounter <= 0 then
			data.state.direction = data.state.direction * -1
			initFly(v, data)
		end
	end

	if npcIDs[v.id].isHorizontal then
		v.speedX = data.move.speed
		--formula: y = A * sin(2π*f*x + θ)
		local angle = math.rad(data.move.time * PERIOD_CONSTANT)
		if angle >= data.move.nextperiod then
			data.move.periodcounter = data.move.periodcounter - 1
			data.move.nextperiod = data.move.nextperiod + PERIOD_CONSTANT
		end
		data.move.time = data.move.time + TIME_STEP
		v.y = v.y + math.sin(angle)
	else
		v.speedY = data.move.speed
    end
end

function flyingbumptyAI.onDrawNPC(v)
	if Misc.isPaused() then return end

	local data = v.data
	if not data.init then
		init(v, data)
	end

	if v:mem(0x12A, FIELD_WORD) <= 0 then return end --offscreen

	data.frame.timer = data.frame.timer - 1
	if data.frame.timer == 0 then
		if data.frame.current + 1 == data.frame.currentnframes then
			data.frame.current = 0
			data.frame.loopcounter = data.frame.loopcounter - 1
		else
			data.frame.current = data.frame.current + 1
		end
		data.frame.timer = MAX_FRAME_TIMER
	end

	local offset = data.frame.currentstartframe
	if data.state.direction == 1 then
		offset = offset + NPC.config[v.id].frames
	end

	v.animationFrame = data.frame.current + offset
end

return flyingbumptyAI