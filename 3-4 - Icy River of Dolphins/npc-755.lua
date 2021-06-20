--[[

	Written by MrDoubleA
	Please give credit!

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local clearpipe = require("blocks/ai/clearpipe")

local ai = require("spike_ai")

local spike = {}
local npcID = NPC_ID
local deathEffectID = 753

local throwID = 756

local spikeSettings = {
	id = npcID,
	
	gfxwidth = 36,
	gfxheight = 34,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32,
	height = 32,
	
	frames = 5,
	idleFrames = 2,
	idleFramespeed = 8,
	framestyle = 1,

	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	isheavy = false,

	idleTime = 96, -- How long the spike is idle before spawning a ball.
	holdTime = 32, -- How long the spike ball is held before throwing it.

	throwID = throwID, -- The ID of the thrown spike ball.
	throwXSpeed = 3,
	throwYSpeed = 4,

	throwSFX = nil, -- Sound effect to be played after throwing the spike ball.
}

npcManager.setNpcSettings(spikeSettings)
npcManager.registerDefines(npcID, {NPC.HITTABLE})
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
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_JUMP]=deathEffectID,
		[HARM_TYPE_FROMBELOW]=deathEffectID,
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SPINJUMP]=10,
	}
)

--clearpipe.registerNPC(npcID)

ai.registerSpike(npcID)

return spike