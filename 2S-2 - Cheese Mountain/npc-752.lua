--Para-Skipsqueak by SpoonyBardOL

local paraskipsqueak = {}

local npcManager = require("npcManager")
local squeaks = require("AI/squeaks")

local npcID = NPC_ID
local deathEffect = 752
npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local paraskipsqueakSettings = {
	id = npcID, 
	gfxoffsetx = 0, 
	gfxoffsety = 10, 
	width = 32, 
    height = 32,
    gfxwidth = 42,
    gfxheight = 42,
    frames = 6,
    framestyle = 1,
	framespeed = 8,
    nofireball = false,
    noiceball = false,
    nogravity=false,
    cliffturn=true,
	
	doesFlutter = true,
	jumpHeight = -9,
	isSkip = true,
}

local configFile = npcManager.setNpcSettings(paraskipsqueakSettings);

npcManager.registerHarmTypes(npcID,
{
    HARM_TYPE_JUMP,
    HARM_TYPE_SPINJUMP,
    HARM_TYPE_TAIL,
    HARM_TYPE_NPC,
    HARM_TYPE_PROJECTILE_USED,
    HARM_TYPE_HELD,
    HARM_TYPE_SWORD,
    HARM_TYPE_FROMBELOW,
    HARM_TYPE_LAVA,
}, 
{
    [HARM_TYPE_JUMP]=deathEffect,
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


return paraskipsqueak