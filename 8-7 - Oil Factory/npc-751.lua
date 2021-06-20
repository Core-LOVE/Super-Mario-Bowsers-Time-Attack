--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local fireNipper = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fireNipperSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 4,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,
	grabside=false,
	grabtop=false,

	--NPC-specific properties
	--projectileID = 752, --Projectile NPC ID, default being npcID+1. Uncomment and set this manually otherwise
	
	--deathEffectID = 751, --Death Effect ID, default being npcID. Uncomment and set this manually otherwise
}

local deathEffectID = fireNipperSettings["deathEffectID"] or npcID

--Applies NPC settings
npcManager.setNpcSettings(fireNipperSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_FROMBELOW]=deathEffectID,
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_IDLE = 0
local STATE_SHOOTING = 1

--Register events
function fireNipper.onInitAPI()
	npcManager.registerEvent(npcID, fireNipper, "onTickNPC")
	npcManager.registerEvent(npcID, fireNipper, "onDrawNPC")
end

function fireNipper.onDrawNPC(v)
	if Defines.levelFreeze then return end
	
	--if despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then return end
	
	local data = v.data
	
	local f = 0
	
	if data.state == STATE_IDLE then
		f = data.animationFrame
	elseif data.state == STATE_SHOOTING then
		f = 2
	end
	
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame=f})
end

function fireNipper.onTickNPC(v)
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
		
		local cfg = NPC.config[v.id]
		
		data.projectileID = cfg.projectileID or 752
		
		data.cooldowntime = data._settings.cooldowntime or 240
		
		data.fireBallCount = data._settings.fireballcount or 4
		data.projectileDelay = data._settings.projectiledelay or 6
		
		data.state = STATE_IDLE
		
		data.timer = 6
		
		data.animationTimer = 8
		data.animationFrame = 0
		
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		data.isholding = true
	end
	
	
	if data.isholding then
		v.speedX = v.speedX*0.95
		
		if math.abs(v.speedX)<0.2 then
			v.speedX = 0
			data.isholding = false
		end
		
		return
	end
	
	npcutils.faceNearestPlayer(v)
	
	if data.state == STATE_IDLE then

		--Handle Animation
		if data.animationTimer > 0 then
			data.animationTimer = data.animationTimer-1
		else
			data.animationTimer = 8
			data.animationFrame = (data.animationFrame+1)%2
		end
		
		data.timer = data.timer-1
		
		if data.timer <= 0 then
			data.state = STATE_SHOOTING
			data.timer = data.fireBallCount*data.projectileDelay
		end
	
	elseif data.state == STATE_SHOOTING then
	
		data.timer = data.timer-1
		
		if data.timer%data.projectileDelay==0 then
			SFX.play(18)
		
			local w = NPC.spawn(data.projectileID, v.x+0.5*v.width, v.y+0.5*v.height, v.section, false, true)
			w.speedX = 3*v.direction
			w.speedY = -8
			w.layerName = "Spawned NPCs"
			w.friendly = v.friendly
		end
		
		if data.timer <= 0 then
			data.state = STATE_IDLE
			data.timer = data.cooldowntime
		end
	
	end
	
end

--Gotta return the library table!
return fireNipper