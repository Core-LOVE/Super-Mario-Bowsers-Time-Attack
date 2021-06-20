--By WhimWidget!

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local SilverPSwitch = require("SilverPSwitch")


--Create the library table
local SilverNPC = {}
SilverNPC.switch_sound = Misc.resolveFile("smw-switch.spc") or Misc.resolveFile("music/smw-switch.spc")

--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

SilverPSwitch.NonaffectedNPCs[npcID] = true


--Defines NPC config for our NPC. You can remove superfluous definitions.
local SilverNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	grabside = true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

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
	effectid = 751,
	coinnpcid = 752,
	score = 0,
	incrementscore = true,
}

--Applies NPC settings
npcManager.setNpcSettings(SilverNPCSettings)

--Registers the category of the NPC. Options include HITTABLE, UNHITTABLE, POWERUP, COLLECTIBLE, SHELL. For more options, check expandedDefines.lua
npcManager.registerDefines(npcID, {NPC.UNHITTABLE, NPC.SWITCH})

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=751,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function SilverNPC.onInitAPI()
	npcManager.registerEvent(npcID, SilverNPC, "onTickNPC")
	registerEvent(SilverNPC,"onTick")
	registerEvent(SilverNPC,"onLoadSection")
	registerEvent(SilverNPC, "onNPCKill")
end


function SilverNPC.onLoadSection()
	for _ , rep_coin in ipairs(SilverPSwitch.MuncherCoins) do
		if rep_coin.isValid then
			rep_coin:mem(0x146, FIELD_WORD, player.section)
			rep_coin:mem(0x124, FIELD_BOOL, true)
		end
	end

end

function SilverNPC.onNPCKill(its_event_obj, its_npc, its_kill_reason)
	if its_npc.id ~= npcID then
		return
	end

	if its_kill_reason == HARM_TYPE_OFFSCREEN then
		its_event_obj.cancelled = true
	elseif its_kill_reason == HARM_TYPE_JUMP then
		SilverNPC.PressSwitch(its_npc)
	end
end

--Global tick
function SilverNPC.onTick()
	SilverPSwitch.GlobalTimer = SilverPSwitch.GlobalTimer - 1
	if SilverPSwitch.SilverToggled and SilverPSwitch.GlobalTimer <= 0 then
		triggerEvent("Silver P Switch - End")

		SilverPSwitch.SilverToggled = false
		Audio.MusicStop()
		Audio.ReleaseStream(-1)

		--revert muncher coins
		for _ , rep_coin in ipairs(SilverPSwitch.MuncherCoins) do
			if rep_coin.isValid then
				--Text.showMessageBox("Coin!")
				--Block.spawn(rep_coin.data.last_type, rep_coin.x, rep_coin.y).isHidden = false
				rep_coin.data.block_form.layerObj = rep_coin.layerObj
				rep_coin.data.block_form.x = rep_coin.x
				rep_coin.data.block_form.y = rep_coin.y
				rep_coin.data.block_form.isHidden = false
				rep_coin:kill()
			end
		end

		SilverPSwitch.MuncherCoins = {}
	end
end

--Hides an NPC and if the NPC isn't counted as a coin already, it creates a coin corresponding to it
function SilverNPC.createCoin(its_npc)
	its_npc:mem(0x124, FIELD_BOOL, true)
	its_npc:mem(0x12A, FIELD_WORD, 0)

	local quick_coin_id = NPC.config[npcID].coinnpcid

	--Check if the NPC is already a coin
	for _ , rep_npc in ipairs(NPC.get(quick_coin_id)) do
		if rep_npc.data.from_npc == rep_npc then
			return
		end
	end

	NPC.spawn(quick_coin_id, its_npc.x + its_npc.width /2 - NPC.config[quick_coin_id].width/2, its_npc.y + quick_self.height - NPC.config[quick_coin_id].height/2, quick_self:mem(0x146,FIELD_WORD))
end

--Tick for each Silver P-Switch
function SilverNPC.onTickNPC(v)
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
	
	--Execute main AI. This template just jumps when it touches the ground.
	--Movement copied from Enjl's spring behaviour to better match that of SMW
	v.speedX = v.speedX * 0.96
	--if math.abs(v.speedX) < 0.1 then
		--v.speedX = 0
	--end
	--for _, rep_player in ipairs(Player.get()) do
		--if rep_player.standingNPC ~= nil and v.idx == rep_player.standingNPC.idx then --temporary, when we get FFI NPCs, they should be cached so the objects themselves should be equal
			--SilverNPC.PressSwitch(self)
			--break
		--end
	--end
end


function SilverNPC.PressSwitch(its_self)
	if not SilverPSwitch.SilverToggled then
		SilverPSwitch.GlobalCollectCount = 0
		triggerEvent("Silver P Switch - Start")
	end
	SilverPSwitch.SilverToggled = true
	SilverPSwitch.GlobalTimer = 64 * 12

	--Loop through all affected NPCs and turn them into coins
	for _ , rep_npc in ipairs(NPC.get()) do
		--Check if an NPC is on screen first as it is likely quicker
		--Check if the NPC is viable to be turned into a coin
		if --rep_npc:mem(0x12A, FIELD_WORD) > 0 and not rep_npc:mem(0x124, FIELD_BOOL)
		--Default conditions
		(((NPC.config[rep_npc.id].health == nil or NPC.config[rep_npc.id].health <= 1) and
		(NPC.config[rep_npc.id].powerup == nil or NPC.config[rep_npc.id].powerup == false) and
		(NPC.config[rep_npc.id].notcointransformable == nil or NPC.config[rep_npc.id].notcointransformable == false) and
		(not NPC.COLLECTIBLE_MAP[rep_npc.id])
		--NPC.config[rep_npc.id].vulnerableharmtypes ~= nil and 
		--(NPC.config[rep_npc.id].vulnerableharmtypes[HARM_TYPE_NPC] ~= nil or NPC.config[rep_npc.id].vulnerableharmtypes[HARM_TYPE_PROJECTILE_USED] ~= nil))

		--Overridden by "NonaffectedNPCs"
		and not SilverPSwitch.NonaffectedNPCs[rep_npc.id])

		--Overriden by "AffectedNPCs"
		or SilverPSwitch.AffectedNPCs[rep_npc.id])

		--Overridden by being friendly
		and rep_npc.friendly == false
		
		--NPC Maps depreciated with defines
		then
			local quick_coin_id = NPC.config[npcID].coinnpcid
			local quick_id = rep_npc.id
			rep_npc.x = rep_npc.x + rep_npc.width/2
			rep_npc.y = rep_npc.y + rep_npc.height
			rep_npc.id = quick_coin_id
			rep_npc.width = NPC.config[quick_coin_id].width
			rep_npc.height = NPC.config[quick_coin_id].height
			rep_npc.x = rep_npc.x - rep_npc.width/2
			rep_npc.y = rep_npc.y - rep_npc.height

			--Only set the speed if it is already on screen
			if rep_npc:mem(0x12A, FIELD_WORD) > 0 and rep_npc:mem(0x124, FIELD_BOOL) then
				rep_npc.direction = 1
				rep_npc.speedX = 1 * NPC.config[quick_coin_id].speed
				if rep_npc.speedY >= -2 then
					rep_npc.speedY = - 5
				else
					rep_npc.speedY = rep_npc.speedY - 3
				end
			end

			if quick_id ~= quick_coin_id then
				rep_npc.data.from_npc = quick_id
			end
		end
	end

	--Loop through muncher blocks and turn them into coins
	--Text.showMessageBox("How may Coins?")
	for _ , rep_block in ipairs(Block.get(SilverPSwitch.MuncherBlocks)) do
		--Text.showMessageBox("Coin")
		if rep_block.isHidden == false then
			SilverPSwitch.MuncherCoins[#SilverPSwitch.MuncherCoins + 1] = NPC.spawn(33,rep_block.x,rep_block.y,player.section,true)
			SilverPSwitch.MuncherCoins[#SilverPSwitch.MuncherCoins].data.last_type = rep_block.id
			SilverPSwitch.MuncherCoins[#SilverPSwitch.MuncherCoins].data.block_form = rep_block
			SilverPSwitch.MuncherCoins[#SilverPSwitch.MuncherCoins].layerObj = rep_block.layerObj
			rep_block:remove()
		end
	end

	SFX.play(32)

	Audio.SeizeStream(-1)
	Audio.MusicStop()
	Audio.MusicOpen(SilverNPC.switch_sound)
	Audio.MusicPlay()
	

	Animation.spawn(NPC.config[npcID].effectid, its_self.x, its_self.y)
	its_self:kill()
end


--Gotta return the library table!
return SilverNPC