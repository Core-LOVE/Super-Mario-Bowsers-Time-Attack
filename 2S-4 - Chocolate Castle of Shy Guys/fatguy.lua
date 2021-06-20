local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local fatGuy = {}

local npcIDs = {}

--Custom local definitions below


local STATE_SQUASH = 0
local STATE_WALK = 1
local STATE_RUN = 2

fatGuy.TYPE_RED = 1
fatGuy.TYPE_GREEN = 2

function getAnimationFrame(v)
	local data = v.data
	
	local f = 0
	
	if v.state == STATE_WALK then
		f =  6+math.floor(data.timer/4)%12
	elseif v.state == STATE_SQUASH then
		f =  2+getSquashedFrame(v)
	elseif v.state == STATE_RUN then
		f =  math.floor(data.timer/6)%2
	end
	
	return npcutils.getFrameByFramestyle(v, {frame=f})
	
end

function getSquashedFrame(v)
	local data = v.data
	
	local f = 0

	return 3-math.floor(data.stunframe/4)%4
end

--Register events
function fatGuy.onInitAPI()
	registerEvent(fatGuy, "onNPCKill")
end

function fatGuy.registerHarmType(id,effectID)
	npcManager.registerHarmTypes(id,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
	}, 
	{
		[HARM_TYPE_NPC]=effectID,
	}
);
end

function fatGuy.register(id,initstate)
	npcManager.registerEvent(id, fatGuy, "onTickNPC")
	npcManager.registerEvent(id, fatGuy, "onDrawNPC")
	
	npcIDs[id] = initstate
	
end

function fatGuy.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		
		v.state = npcIDs[v.id]
		
		data.timer = 0 --used for animation timing
		
		data.stunframe = 0 --used for stunt time
		
		data.initialized = true
	end
	
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		return
	end
	
	if v.state == STATE_WALK then
		v.speedX = v.direction*1
	elseif v.state == STATE_SQUASH then
		v.speedX = 0
		data.stunframe = data.stunframe+1
		
		if data.stunframe >= 16 then
			v.state = STATE_RUN
			data.stunframe = 0
			data.timer = 0
		end
	elseif v.state == STATE_RUN then
		v.speedX = v.direction*2
	end
	
	data.timer = data.timer+1
end

function fatGuy.onDrawNPC(v)
	
	--Don't draw if despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end

	v.animationFrame = getAnimationFrame(v)
end

function fatGuy.onNPCKill(eventObj,v,harmReason,culprit)
	if not npcIDs[v.id] then return end
	
	if harmReason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		v.state = STATE_SQUASH
		v.data.timer = 0
		SFX.play(9)
	end

end

return fatGuy