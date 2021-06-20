local flyingbumpty = {}

local npcManager = require("npcManager")
local flyingai = require("AI/flyingBumptyAI")
local ai = require("AI/bumptyAI")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})
npcManager.setNpcSettings({
	id = npcID,

	gfxwidth = 56,
	gfxheight = 44,

	width = 28,
	height = 30,

	gfxoffsetx = 2,
	gfxoffsety = 10,

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
flyingai.register(npcID, true, false)

return flyingbumpty