local smwfuzzy = {}

local npcManager = require("npcManager")
local munchers = require("AI/munchers")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

-- settings
local config = {
	id = npcID, 
	gfxoffsety = 0, 
	width = 60, 
    height = 64,
    gfxwidth = 64,
    gfxheight = 64,
    frames = 2,
    framestyle = 0,
    noiceball = true,
    nofireball = true,
    noyoshi = true,
	noblockcollision = false,
    jumphurt = true,
    spinjumpSafe = false,
    nogravity = false,
    playerblocktop = true,
    npcblocktop = true,
    playerblock = true,
    npcblock = true,
    grabside = true,
    grabtop = true,
}

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_LAVA,
	}, 
	{
		[HARM_TYPE_FROMBELOW]=754,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

npcManager.setNpcSettings(config)

function smwfuzzy.onInitAPI()
    munchers.register(npcID)
end

return smwfuzzy