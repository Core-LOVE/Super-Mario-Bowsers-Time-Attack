local npcManager = require("npcManager")

local burnerLeft = {}
local npcID = NPC_ID

local burnerLeftSettings = {
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

	fireID = 766,
	fireDirection = -1,
	cooldown = 200,
	fire_xOffset = 0,
	fire_yOffset = 0
}

local configFile = npcManager.setNpcSettings(burnerLeftSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

function burnerLeft.onInitAPI()
	npcManager.registerEvent(npcID, burnerLeft, "onStartNPC")
	npcManager.registerEvent(npcID, burnerLeft, "onTickNPC")
end

local DIR_ON = -1
local DIR_OFF = 1

function burnerLeft.onStartNPC(v)
	local data = v.data
	if v.direction == DIR_OFF then
		data.state = 0
	elseif v.direction == DIR_ON then
		data.state = 1
	end
	
	if v.friendly then
		data.friendly = true
		v.friendly = false
	else
		data.friendly = false
	end
end

function burnerLeft.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		return
	end
	
	data.timer = data.timer or 0
	data.state = data.state or 0 --0 is for cooldown, 1 is for releasing fire
	
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
	if lunatime.tick() > 0 and not data._basegame.activateOnWalk then
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
			data.flame = NPC.spawn(configFile.fireID, v.x - NPC.config[configFile.fireID].width, v.y + 2, v:mem(0x146, FIELD_WORD))
			
			data.flame.direction = configFile.fireDirection
			data.flame.layerName = "Spawned NPCs"
			data.flame.friendly = data.friendly
			data.flame.data._basegame.parent = v
		elseif data.timer >= configFile.cooldown + 48 then
			data.state = 0
			data.timer = 0
		end
	end
	
	--make this thing movable, shall we?
	v.x = v.x + v.layerObj.speedX
	v.y = v.y + v.layerObj.speedY
end

--Gotta return the library table!
return burnerLeft