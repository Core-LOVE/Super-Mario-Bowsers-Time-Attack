local npcManager = require("npcManager")

local hammers = {}
local npcID = NPC_ID
local hammerSettings = {
	id = npcID,
	gfxheight = 24,
	gfxwidth = 28,
	height = 24,
	width = 28,
	frames = 2,
	framestyle = 0,
	jumphurt = 1,
	noblockcollision = 1,
    noyoshi = 1,
	noiceball = 1,
	speed = 1
}
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local configFile = npcManager.setNpcSettings(hammerSettings)

function hammers.onInitAPI()
	npcManager.registerEvent(npcID, hammers, "onTickNPC")
end

function hammers.onTickNPC(hammer)
	if hammer.ai1 == 0 then
		hammer.ai1 = 1
		
		-- Multiply the hammer's x-speed by whatever speed was defined in the config file.
		
		hammer.speedX = hammer.speedX * configFile.speed
	end
end
	
return hammers