local npcManager = require("npcManager")

local burnerTop = {}
local npcID = NPC_ID

local burnerTopSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 2,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	
	npcblock = true,
	npcblocktop = true,
	playerblock = true,
	playerblocktop = true,

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	fireID = 785,
	fireDirection = -1,
	cooldown = 200,
}

local configFile = npcManager.setNpcSettings(burnerTopSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

function burnerTop.onInitAPI()
	npcManager.registerEvent(npcID, burnerTop, "onStartNPC")
	npcManager.registerEvent(npcID, burnerTop, "onTickNPC")
end

local DIR_ON = -1
local DIR_OFF = 1

function burnerTop.onStartNPC(v)
	local data = v.data
	if not data._settings.activateOnWalk then
		if v.direction == DIR_OFF then
			data.state = 0
		elseif v.direction == DIR_ON then
			data.state = 1
		end
	end
	
	if v.friendly then
		data.friendly = true
		v.friendly = false
	else
		data.friendly = false
	end
end

function burnerTop.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	data.timer = data.timer or 0
	data.state = data.state or 0 --0 is for cooldown, 1 is for releasing fire
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		return
	end
	v.animationTimer = 0

	if not data.initialized then
		data.initialized = true
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--a
	else
		--b
	end
	
	--AI
	if lunatime.tick() > 0 and not data._settings.activateOnWalk then
		data.timer = data.timer + 1
	end
	
	if data.state == 0 then
		if data.timer >= configFile.cooldown + 48 then
			data.state = 1
			data.timer = 0
		end
	elseif data.state == 1 then
		if data.timer == 1 then
			SFX.play(42)
			data.flame = NPC.spawn(configFile.fireID, v.x + 2, v.y - NPC.config[configFile.fireID].height, v:mem(0x146, FIELD_WORD))
			
			data.flame.direction = configFile.fireDirection
			data.flame.layerName = "Spawned NPCs"
			data.flame.friendly = data.friendly
			data.flame.data._settings.parent = v
		elseif data.timer >= configFile.cooldown + 48 then
			data.state = 0
			data.timer = 0
		end
	end
	
	if data._settings.activateOnWalk then
		if v.animationFrame ~= 1 then
			v.animationFrame = 1
		end
		if player.standingNPC ~= nil and player.standingNPC.idx == v.idx then
			if data.state == 0 then
				data.state = 2
			end
		end
		
		if data.state == 2 and data.timer == 32 then
			SFX.play(42)
			data.flame = NPC.spawn(configFile.fireID, v.x + 2, v.y - NPC.config[configFile.fireID].height, v:mem(0x146, FIELD_WORD))
			
			data.flame.direction = configFile.fireDirection
			data.flame.layerName = "Spawned NPCs"
			data.flame.friendly = data.friendly
			data.flame.data._settings.parent = v
			data.timer = 0
			data.state = 0
		end
		
		if data.state == 2 and data.timer < configFile.cooldown + 48 then
			data.timer = data.timer + 1
		elseif data.state == 2 and data.timer >= configFile.cooldown + 48 then
			data.timer = 0
			data.state = 1
		end
	end
	
	--make this thing movable, shall we?
	v.x = v.x + v.layerObj.speedX
	v.y = v.y + v.layerObj.speedY
end

--Gotta return the library table!
return burnerTop