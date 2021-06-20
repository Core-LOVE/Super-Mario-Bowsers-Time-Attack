--[[

	Written by MrDoubleA
	Please give credit!

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local clearpipe = require("blocks/ai/clearpipe")

local ai = require("spike_ai")

local spikeball = {}
local npcID = NPC_ID

local spikeballSettings = {
	id = npcID,
	
	gfxwidth = 64,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 64,
	height = 64,
	
	frames = 1,
	framespeed = 8,
	framestyle = 0,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside = false,
	isheavy = true,

	issnowball = true,
	islarge = true,

	startingSpeed = 2.5, -- What speed to start at when spawned.
	bounceHeight = 4, -- Height of bounce.
}

npcManager.setNpcSettings(spikeballSettings)
npcManager.registerDefines(npcID, {NPC.HITTABLE})
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)

clearpipe.registerNPC(npcID)

ai.registerBall(npcID)

return spikeball