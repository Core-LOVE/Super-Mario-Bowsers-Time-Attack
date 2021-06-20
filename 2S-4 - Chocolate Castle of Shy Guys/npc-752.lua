--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local fatGuy = require("fatGuy")

--Create the library table
local greenFatGuy = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local greenFatGuySettings = {
	id = npcID,
	gfxheight = 66,
	gfxwidth = 68,
	width = 48,
	height = 56,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 6,
	framestyle = 1,
	framespeed = 0,
	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = false,

	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	cliffturn = 1,
	score = 0,
	
	--NPC Specific settings
	--deatheffectID = 752 --Death effect when collide with NPC, default is npcID. Uncomment this if otherwise
}

--Applies NPC settings
npcManager.setNpcSettings(greenFatGuySettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
fatGuy.registerHarmType(npcID,NPC.config[npcID].deatheffectID or npcID)

fatGuy.register(npcID,fatGuy.TYPE_GREEN)

--Gotta return the library table!
return greenFatGuy