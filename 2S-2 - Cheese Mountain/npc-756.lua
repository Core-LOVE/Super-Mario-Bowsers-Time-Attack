--Mega Spiny Skipsqueak by SpoonyBardOL

local megaspinyskipsqueak = {}

local npcManager = require("npcManager")
local squeaks = require("AI/squeaks")

local npcID = NPC_ID
local deathEffect = 756
npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local megaspinyskipsqueakSettings = {
	id = npcID, 
	gfxoffsetx = 0, 
	gfxoffsety = 12, 
	width = 42, 
    height = 58,
    gfxwidth = 50,
    gfxheight = 72,
    frames = 6,
	framespeed = 8,
    framestyle = 1,
    nofireball = false,
    noiceball = false,
    nogravity=false,
    cliffturn=true,
	jumphurt = true,
	spinjumpsafe = true,
	
	jumpHeight = -9,
	isSkip = true,
}

local configFile = npcManager.setNpcSettings(megaspinyskipsqueakSettings);

npcManager.registerHarmTypes(npcID,
{
    HARM_TYPE_TAIL,
    HARM_TYPE_NPC,
    HARM_TYPE_PROJECTILE_USED,
    HARM_TYPE_HELD,
    HARM_TYPE_SWORD,
    HARM_TYPE_FROMBELOW,
    HARM_TYPE_LAVA,
}, 
{
    [HARM_TYPE_TAIL]=deathEffect,
    [HARM_TYPE_NPC]=deathEffect,
    [HARM_TYPE_PROJECTILE_USED]=deathEffect,
    [HARM_TYPE_HELD]=deathEffect,
    [HARM_TYPE_FROMBELOW]=deathEffect,
    [HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
}
);

squeaks.register(npcID)
squeaks.frameCount = configFile.frames

return megaspinyskipsqueak