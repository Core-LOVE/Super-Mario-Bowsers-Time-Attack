local cooligan1 = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 64,
	gfxheight = 34,
	width = 64,
	height = 34,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	speed = 3,
        iswalker = true,
        score = 0,
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{
	[HARM_TYPE_FROMBELOW] = 760,
	[HARM_TYPE_NPC] = 760,
	[HARM_TYPE_HELD] = 760,
	[HARM_TYPE_TAIL] = 760,
	[HARM_TYPE_PROJECTILE_USED] = 760,
	[HARM_TYPE_LAVA]={id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function cooligan1.onNPCKill(eventObj, npc, reason)
	if npc.id == npcID and (reason == 1 or reason == 6) then
		eventObj.cancelled = true
		npc:transform(761)
		end
end

function cooligan1.onInitAPI()
	registerEvent(cooligan1, "onNPCKill", "onNPCKill")
end

return cooligan1
