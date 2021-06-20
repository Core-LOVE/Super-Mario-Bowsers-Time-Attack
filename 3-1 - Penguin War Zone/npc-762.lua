local cooligan1 = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 64,
	gfxheight = 34,
	width = 64,
	height = 32,
	frames = 2,
	framespeed = 8,
	framestyle = 1,
	speed = 3,
        iswalker = true,
        score = 0,
	npcblocktop = true, 
	playerblocktop = true, 
	nofireball = true,
	noiceball = true,
	noyoshi = true,
        nohurt = true,
}) 
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{
	[HARM_TYPE_FROMBELOW] = 761,
	[HARM_TYPE_NPC] = 761,
	[HARM_TYPE_HELD] = 761,
	[HARM_TYPE_TAIL] = 761,
	[HARM_TYPE_PROJECTILE_USED] = 761,
	[HARM_TYPE_LAVA]={id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function cooligan1.onNPCKill(eventObj, npc, reason)

end

function cooligan1.onInitAPI()
	registerEvent(cooligan1, "onNPCKill", "onNPCKill")
end

return cooligan1
