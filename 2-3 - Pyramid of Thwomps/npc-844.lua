local thwomps = {}

local npcManager = require("npcManager")
local thwompAI = require("npcs/ai/thwomps")

local npcID = NPC_ID

local settings = {
	id = npcID, width = 64, height = 64, gfxwidth = 64, gfxheight = 64, playerblocktop = true, npcblocktop = true, staticdirection = true, spinjumpsafe = false, harmTypes = {
		[HARM_TYPE_HELD] = 844,
		[HARM_TYPE_PROJECTILE_USED] = 844,
		[HARM_TYPE_NPC] = 844,
		--[HARM_TYPE_FROMBELOW] = 10,
		[HARM_TYPE_LAVA] = 10
	}
}

thwompAI.registerThwomp(settings)

return thwomps