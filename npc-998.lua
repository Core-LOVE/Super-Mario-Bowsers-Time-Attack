--[[

	Written by MrDoubleA
    Please give credit!
    
    Credits to Eri7 for help on improving Mario's P-Balloon sprites

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local ai = require("pballoon_ai")

local pBalloon = {}
local npcID = NPC_ID

local pBalloonSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	isinteractable = true,

	-- P-Balloon settings

	duration = 772, -- How long the P-Balloon's effect lasts for.
	warnTime = 160, -- How long the player flashes before the P-Balloon's effect wears off.

	horizontalSpeed          = 2,     -- The maximum speed that the player can move at horizontally.
	horizontalAcceleration   = 0.075, -- How fast the player accelerates horizontally.
	horizontalDeacceleration = 0.05,  -- How fast the player deaccelerates horizontally.

	neutralSpeed = -0.75, -- The speed that the player moves at vertically when not holding up or down.

	upwardsSpeed        = -1.25, -- The speed that the player moves at vertically when holding the up button.
	upwardsAcceleration = 0.05,  -- How fast the player accelerates upwards.

	downwardsSpeed        = 0.5,   -- The speed that the player moves at vertically when holding the down button.
	downwardsAcceleration = 0.025, -- How fast the player accelerates downwards.

	collectSFX = SFX.open(Misc.resolveFile("pballoon_collect.wav")), -- The sound effect played upon collecting the P-Balloon. Can be nil for no sound effect, a number for a vanilla sound effect, or a sound object/string for a custom sound effect.
}

npcManager.setNpcSettings(pBalloonSettings)
npcManager.registerDefines(npcID,{NPC.COLLECTIBLE})
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})

ai.register(npcID)

function pBalloon.onInitAPI()
	npcManager.registerEvent(npcID,pBalloon,"onTickNPC")
end

function pBalloon.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.waveTimer = nil
		return
	end

	if not data.waveTimer then
		data.waveTimer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then data.waveTimer = 0 return end

	data.waveTimer = data.waveTimer + 1
	
	v.speedX = (0.5*v.direction)
	v.speedY = (-math.cos(data.waveTimer/32)*0.75)
end

return pBalloon