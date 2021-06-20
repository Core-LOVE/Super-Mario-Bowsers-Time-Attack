--By WhimWidget!

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local SilverPSwitch = require("SilverPSwitch")

--Create the library table
local SilverCoinNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

SilverPSwitch.AffectedNPCs[752] = true

--Defines NPC config for our NPC. You can remove superfluous definitions.
local SilverCoinNPCSettings = {
	id = npcID,
	--Sprite size
	gfxwidth = 20,
	gfxheight = 32,	
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 6, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	isinteractable = true,
	score = 0,
	--isCoin = true

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
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
npcManager.setNpcSettings(SilverCoinNPCSettings)

--Registers the category of the NPC. Options include HITTABLE, UNHITTABLE, POWERUP, COLLECTIBLE, SHELL. For more options, check expandedDefines.lua
npcManager.registerDefines(npcID, {NPC.COLLECTIBLE})

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function SilverCoinNPC.onInitAPI()
	npcManager.registerEvent(npcID, SilverCoinNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, SilverCoinNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, SilverCoinNPC, "onDrawNPC")
	registerEvent(SilverCoinNPC, "onNPCKill")
end

function SilverCoinNPC.onNPCKill(its_event_obj, its_npc, its_kill_reason)
	if its_npc.id ~= npcID then
		return
	end

	if its_kill_reason == 9 then
		--Get the total enemy count from the Silver P-Switch
		local quick_frame = 3 + SilverPSwitch.GlobalCollectCount
		if quick_frame > 12 then
			quick_frame = 12
		end
		--Animation.spawn(79, quick_npc.x, quick_npc.y).animationFrame = quick_frame
		Misc.givePoints(quick_frame, {x = its_npc.x, y = its_npc.y}, false)
		SilverPSwitch.GlobalCollectCount = SilverPSwitch.GlobalCollectCount + 1
	end
end

function SilverCoinNPC.revert(its_npc)
	--local quick_id = its_npc.id
	its_npc.id = its_npc.data.from_npc
	its_npc.width = NPC.config[its_npc.id].width
	its_npc.height = NPC.config[its_npc.id].height
	its_npc:mem(0xDC, FIELD_WORD, its_npc.id)
end

function SilverCoinNPC.onTickNPC(v)
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
		--Check if the NPC is 
		if SilverPSwitch.SilverToggled or not data.from_npc then
			--Initialize necessary data.
			data.initialized = true
			v.direction = 1
			v.speedX = 0.7 * NPC.config[npcID].speed
		else
			SilverCoinNPC.revert(v)
			return
		end
	end

	

	--This check basically allows enemies to respawn as normal if the switch is still active, or respawn as a coin if not
	if SilverPSwitch.SilverToggled then
		v:mem(0xDC, FIELD_WORD, npcID)
	elseif data.from_npc then
		v:mem(0xDC, FIELD_WORD, data.from_npc)
	end

end

--Gotta return the library table!
return SilverCoinNPC