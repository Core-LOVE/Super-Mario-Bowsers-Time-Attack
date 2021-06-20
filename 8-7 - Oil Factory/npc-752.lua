--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local fireBall = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fireBallSettings = {
	id = npcID,
	gfxheight = 16,
	gfxwidth = 16,
	width = 16,
	height = 16,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 4,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = false,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	
	ignorethrownnpcs = true,
	linkshieldable = true,
}

--Applies NPC settings
npcManager.setNpcSettings(fireBallSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
	}, 
	{
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
	}
);

--Custom local definitions below


--Register events
function fireBall.onInitAPI()
	npcManager.registerEvent(npcID, fireBall, "onTickNPC")
end

function fireBall.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true

	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	
end

--Gotta return the library table!
return fireBall