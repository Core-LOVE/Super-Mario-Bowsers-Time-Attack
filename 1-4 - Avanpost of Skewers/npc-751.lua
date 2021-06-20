--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local BoomBoomNPC = {
e_heart = Graphics.loadImage("heart-1.png"),
heart = Graphics.loadImage("heart-2.png"),
bossName = "Boom Boom"
}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local BoomBoomNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 54,
	gfxwidth = 60,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 60,
	height = 54,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 6, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 4,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
    cliffturn = false,
	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	grabside = false,
	grabtop = false,
	hp = 10,
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
npcManager.setNpcSettings(BoomBoomNPCSettings)

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
function BoomBoomNPC.onInitAPI()
	npcManager.registerEvent(npcID, BoomBoomNPC, "onTickNPC")
	npcManager.registerEvent(npcID, BoomBoomNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, BoomBoomNPC, "onDrawNPC")
	registerEvent(BoomBoomNPC, "onNPCHarm")
end

function BoomBoomNPC.onNPCHarm(e,v,r,c)
	if v.id ~= npcID then return end
	
	if v.hp > 0 then
		v.immunity = -80
		SFX.play(2)
		v.hp = v.hp - 1
		e.cancelled = true
	end
end

function BoomBoomNPC.onDrawNPC(v)
	if v.hp == nil then return end
	
	local vx = 16
	local vy = 600 - (30 + 15)
	local str = BoomBoomNPC.bossName
	
	for i = 0, v.hp do
		Graphics.drawImageWP(BoomBoomNPC.heart, vx + (33 * i), vy, 5)
	end
	
	for i = 0, NPC.config[npcID].hp do
		Graphics.drawImageWP(BoomBoomNPC.e_heart, vx + (33 * i), vy, 0.5, 4.9)
	end
	
	Text.print(str, 800 - (18 * str:len()) - 24, 600 - 32)
end

function BoomBoomNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if data.ftimer == nil then
		data.ftimer = 0
	end
	
	if data.gtimer == nil then
		data.gtimer = 0
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
		v.immunity = 0
		v.hp = NPC.config[npcID].hp
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
        v.speedX = v.direction * 1
		
			data.ftimer = data.ftimer + 1
			data.gtimer = data.gtimer + 1
			if data.ftimer > 25 then
				if v:mem(0x0A,FIELD_WORD) > 0 then
					v.speedY = -5.3
					data.ftimer = 0
				end
			end
			if data.gtimer > 350 and data.gtimer < 390 then
				v.speedY = -4.7
			elseif data.gtimer == 400 then
				data.gtimer = 0
			end
	end
	if v.immunity < 0 then
		v.friendly = true
		v.animationFrame = math.floor(math.random(-1, v.animationFrame))
		v.immunity = v.immunity + 1
	elseif v.immunity >= 0 then
		v.friendly = false
	end
end
	

--Gotta return the library table!
return BoomBoomNPC