--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local triclyde = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local triclydeSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 94,
	gfxwidth = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 80,
	height = 94,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 0,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	cliffturn = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	--Identity-related flags. Apply various vanilla AI based on the flag:
	iswalker = true,
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
npcManager.setNpcSettings(triclydeSettings)

--Registers the category of the NPC. Options include HITTABLE, UNHITTABLE, POWERUP, COLLECTIBLE, SHELL. For more options, check expandedDefines.lua
npcManager.registerDefines(npcID, {NPC.HITTABLE})

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=753,
		[HARM_TYPE_FROMBELOW]=753,
		[HARM_TYPE_NPC]=753,
		[HARM_TYPE_PROJECTILE_USED]=753,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=753,
		[HARM_TYPE_TAIL]=753,
		[HARM_TYPE_SPINJUMP]=753,
		[HARM_TYPE_OFFSCREEN]=753,
		[HARM_TYPE_SWORD]=753,
	}
);

--Custom local definitions below


--Register events
function triclyde.onInitAPI()
	--npcManager.registerEvent(npcID, triclyde, "onTickNPC")
	npcManager.registerEvent(npcID, triclyde, "onTickEndNPC")
	--npcManager.registerEvent(npcID, triclyde, "onDrawNPC")
	registerEvent(triclyde, "onNPCHarm")
end

function triclyde.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if data.ftimer == nil then
		data.ftimer = 0
	end
	if data.pdtimer == nil then --play dead timer
		data.pdtimer = 0
	end	
	if data.animtimer == nil then 
		data.animtimer = 0
	end
	if data.pd == nil then --play dead
		data.pd = false
	end
	if data.health == nil then
		data.health = 6
	end
	

	
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
	
	--Execute main AI.
	if not v:mem(0x128,FIELD_BOOL) and not data.pd then
		data.ftimer = data.ftimer + 1
		if data.ftimer >= 155 and data.ftimer < 239 then 
			if v.direction == -1 then
				v.animationFrame = 4
			if data.ftimer == 156 or data.ftimer == 166 or data.ftimer == 176 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x,(v.y+15),player.section)
			end			
				if data.ftimer == 186 and data.health <= 5 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x,(v.y+15),player.section)
			end				
			if data.ftimer == 196 and data.health <= 4 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x,(v.y+15),player.section)
			end			
			if data.ftimer == 206 and data.health <= 3 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x,(v.y+15),player.section)
				fire.speedY = 0
				fire.speedX = v.direction*2
			end			
			if data.ftimer == 216 and data.health <= 2 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x,(v.y+15),player.section)
			end			
			if data.ftimer == 226 and data.health <= 1 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x,(v.y+15),player.section)
			end			
			if data.ftimer == 236 and data.health == 1 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x,v.y+15,player.section)
			end
                        end
                if v.direction == 1 then
				v.animationFrame = 5
			if data.ftimer == 156 or data.ftimer == 166 or data.ftimer == 176 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x+66,(v.y+15),player.section)
			end			
				if data.ftimer == 186 and data.health <= 5 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x+66,(v.y+15),player.section)
			end				
			if data.ftimer == 196 and data.health <= 4 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x+66,(v.y+15),player.section)
			end			
			if data.ftimer == 206 and data.health <= 3 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x+66,(v.y+15),player.section)
				fire.speedY = 0
				fire.speedX = v.direction*2
			end			
			if data.ftimer == 216 and data.health <= 2 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x+66,(v.y+15),player.section)
			end			
			if data.ftimer == 226 and data.health <= 1 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x+66,(v.y+15),player.section)
			end			
			if data.ftimer == 236 and data.health == 1 then
				SFX.play(42)
				local fire = NPC.spawn(754,v.x+66,v.y+15,player.section)
			end
                        end
		elseif data.ftimer == 239 then
			data.ftimer = 0
		end
	end
	if data.pd then
		v.friendly = true
		data.pdtimer = data.pdtimer + 1
		data.animtimer = data.animtimer + 1
		if data.animtimer < 8 and data.animtimer >= 0 and v.direction == -1 then
		v.animationFrame = 6
		elseif data.animtimer >= 8 and data.animtimer < 16 and v.direction == -1 then
		v.animationFrame = 7
		elseif data.animtimer >= 16 then
		data.animtimer = 0		
		end
		if data.animtimer < 8 and data.animtimer >= 0 and v.direction == 1 then
		v.animationFrame = 8
		elseif data.animtimer >= 8 and data.animtimer < 16 and v.direction == 1 then
		v.animationFrame = 9
		elseif data.animtimer >= 16 then
		data.animtimer = 0
	end
	end
	if data.pdtimer == 80 then
		v.friendly = false
		data.pd = false
		data.pdtimer = 0
		data.animtimer = 0
	end	
	if data.health == 0 then
		v:kill(9)
		SFX.play(63)
	end
    if Player.getNearest(v.x, v.y).x < v.x then
					v.direction = -1
				else
					v.direction = 1
				end
end
   

function triclyde.onNPCHarm(eventObj, v, killReason, culprit)
	if v.id ~= npcID then return end
	if killReason ~= HARM_TYPE_NPC and killReason ~= HARM_TYPE_HELD and killReason ~= HARM_TYPE_SWORD then return end
	
	local data = v.data
	data.pd = true
	data.health = data.health - 1
        SFX.play(39)
	if health ~= 0 then
		eventObj.cancelled = true
	end
end

--Gotta return the library table!
return triclyde