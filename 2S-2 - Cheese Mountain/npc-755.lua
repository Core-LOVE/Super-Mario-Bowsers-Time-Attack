--Mega Skipsqueak by SpoonyBardOL

local megaskipsqueak = {}

local npcManager = require("npcManager")
local squeaks = require("AI/squeaks")

local npcID = NPC_ID
local deathEffect = 755
npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local megaskipsqueakSettings = {
	id = npcID, 
	gfxoffsetx = 0, 
	gfxoffsety = 10, 
	width = 42, 
    height = 58,
    gfxwidth = 46,
    gfxheight = 68,
    frames = 6,
	framespeed = 8,
    framestyle = 1,
    nofireball = false,
    noiceball = false,
    nogravity=false,
    cliffturn=true,
	
	jumpHeight = -9,
	isSkip = true,
}

local configFile = npcManager.setNpcSettings(megaskipsqueakSettings);

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

return megaskipsqueak