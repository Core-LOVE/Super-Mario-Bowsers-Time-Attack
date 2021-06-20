--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local crabmeatNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local crabmeatNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 76,
	gfxwidth = 100,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 46,
	height = 76,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 8,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
        cliffturn = true,
	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = true,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(crabmeatNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=751,
		[HARM_TYPE_FROMBELOW]=751,
		[HARM_TYPE_NPC]=751,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=751,
		[HARM_TYPE_TAIL]=751,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function crabmeatNPC.onInitAPI()
	npcManager.registerEvent(npcID, crabmeatNPC, "onTickNPC")
	npcManager.registerEvent(npcID, crabmeatNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, crabmeatNPC, "onDrawNPC")
	--registerEvent(crabmeatNPC, "onNPCKill")
end

function crabmeatNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if data.ftimer == nil then
		data.ftimer = 0
	end
	--If despawned
	if v.despawnTimer <= 0 then
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
	if not v:mem(0x128,FIELD_BOOL) then
                v.speedX = v.direction*1
		
		data.ftimer = data.ftimer + 1
			if data.ftimer >= 158 and data.ftimer < 200 then
			v.speedX = v.direction*0
                        v.animationFrame = 8
			end
                 end
			if data.ftimer == 164 then
				local fire = NPC.spawn(752,v.x-25,v.y+20,player.section)
				local fire2 = NPC.spawn(752,v.x+45,v.y+20,player.section)
				fire.speedY = -5
				fire.speedX = -3
				fire2.speedY = -5
				fire2.speedX = 3
			end
		if data.ftimer == 200 then
			v.speedX = v.direction*1
			data.ftimer = 0
		end
	end
	

--Gotta return the library table!
return crabmeatNPC