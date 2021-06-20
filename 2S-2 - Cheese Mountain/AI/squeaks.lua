--Squeak family AI by SpoonyBardOL
--Based on Bearvor by Enjl

local squeaks = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local slime = require("blocks/ai/slime")

local cam = Camera.get()[1]

local npcIDs = {}
local ST_IDLE = 0
local ST_CROUCH = 1
local ST_JUMP = 2
local ST_SKIPCHECK = 3
local flutterSound = Misc.multiResolveFile("swooperflap.ogg", "sound/extended/swooperflap.ogg")
local pJumpCheck = false


--v.ai2 Countdown Timer
--v.ai3 Is Return Jumping
--v.ai4 Wall Check
--v.ai5 Animation Timer


function squeaks.register(id)
    npcManager.registerEvent(id, squeaks, "onTickEndNPC")
	npcManager.registerEvent(id, squeaks, "onTickNPC")
	npcIDs[id] = true
end

function squeakAnim(v)
	local data = v.data
	v.ai5 = v.ai5 + 1
	if data.state == ST_IDLE then
		if not v.dontMove and (not NPC.config[v.id].isSkip or (NPC.config[v.id].isSkip and data.skipMove and v.speedY == 0)) then
			if v.ai5 <= NPC.config[v.id].framespeed * 1 then
				data.frame = 0
			elseif v.ai5 > NPC.config[v.id].framespeed * 1 and v.ai5 <= NPC.config[v.id].framespeed * 2 then
				data.frame = 1
			elseif v.ai5 > NPC.config[v.id].framespeed * 2 and v.ai5 <= NPC.config[v.id].framespeed * 3 then
				data.frame = 2
			elseif v.ai5 > NPC.config[v.id].framespeed * 3 and v.ai5 <= NPC.config[v.id].framespeed * 4 then
				data.frame = 1
			elseif v.ai5 > NPC.config[v.id].framespeed * 4 then
				data.frame = 0
				v.ai5 = 0
			end
		elseif NPC.config[v.id].isSkip and data.skipMove and v.speedY ~= 0 then
			if v.speedY < 0 then
				if v.ai5 <= NPC.config[v.id].framespeed * 1 then
					data.frame = 3
				elseif v.ai5 > NPC.config[v.id].framespeed * 1 and v.ai5 <= NPC.config[v.id].framespeed * 2 then
					data.frame = 4
				elseif v.ai5 > NPC.config[v.id].framespeed * 2 then
					v.ai5 = 0
				end
			elseif v.speedY >= 0 then
				data.frame = 5
			end
		else
			data.frame = 0
		end
	elseif data.state == ST_CROUCH then
		data.frame = 1
	elseif data.state == ST_JUMP then
		if not NPC.config[v.id].doesFlutter then
			if v.speedY < 0 then
				if v.ai5 <= NPC.config[v.id].framespeed * 1 then
					data.frame = 3
				elseif v.ai5 > NPC.config[v.id].framespeed * 1 and v.ai5 <= NPC.config[v.id].framespeed * 2 then
					data.frame = 4
				elseif v.ai5 > NPC.config[v.id].framespeed * 2 then
					v.ai5 = 0
				end
			elseif v.speedY >= 0 and data.fluttering == false then
				data.frame = 5
			end
		else
			if v.speedY < 0 then
				data.frame = 4
			elseif data.flutterTimer > 0 and data.fluttering == true then
				if v.ai5 <= NPC.config[v.id].framespeed * 1 then
					data.frame = 3
				elseif v.ai5 > NPC.config[v.id].framespeed * 1 and v.ai5 <= NPC.config[v.id].framespeed * 2 then
					data.frame = 4
				elseif v.ai5 > NPC.config[v.id].framespeed * 2 then
					v.ai5 = 0
				end
			else
				data.frame = 5
			end
		end
	end
end

function skipReturn(v)
	local data = v.data
	if not data.homeSet and v.collidesBlockBottom then
		data.homeX = v.x
		data.homeY = v.y
		data.homeSet = true
	end
	if (v.x > data.homeX + 32 or v.x < data.homeX - 32) and data.homeSet then
		data.canJump = false
	else
		data.canJump = true
	end
	if data.state == ST_IDLE and (v.x > data.homeX + 6 or v.x < data.homeX - 6) and data.homeSet then
		data.skipMove = true
		v.ai2 = v.ai2 + 1
		--Move left or right back to start position
		if v.x < data.homeX - 4 then
			if v.speedX < 2.5 then
				v.speedX = v.speedX + 0.1
			else 
				v.speedX = v.speedX - 0.1
			end
		elseif v.x > data.homeX + 4 then
			if v.speedX > -2.5 then
				v.speedX = v.speedX - 0.1
			else
				v.speedX = v.speedX + 0.1
			end
		end
		--Jump over walls to get back to start position, if necessary
		if (v.collidesBlockLeft or v.collidesBlockRight) and v.collidesBlockBottom and v.ai4 <= 2 and v.ai3 == 0 and v.ai2 > 30 then
			v.ai4 = v.ai4 + 1
			v.ai2 = 0
			data.lockDirection = v.direction
		elseif (v.ai4 >= 3 and v.ai4 <= 4) and v.collidesBlockBottom and v.ai3 == 0 and v.ai2 > 30 then
			v.speedY = NPC.config[v.id].jumpHeight * 0.7
			v.ai3 = 1
			v.ai2 = 0
		elseif v.ai4 == 5 and v.collidesBlockBottom and v.ai3 == 0 then
			v.speedY = -8
			v.ai3 = 1
			v.ai2 = 0
		elseif v.ai4 > 5 and v.collidesBlockBottom and v.ai3 == 0 then
			--If unable to return to start position, set new start position
			if v.y > data.homeY + 90 then
				v.speedX = 0
				v.speedY = 0
				data.homeSet = false
			end
			v.ai4 = 0
			v.ai2 = 0
		elseif v.ai3 == 1 then
			v.direction = data.lockDirection
			v.speedX = 2 * data.lockDirection
			if v.collidesBlockBottom then
				v.ai3 = 0
				v.ai2 = 0
				v.ai4 = v.ai4 + 1
			end
		end
	else
		data.skipMove = false
		v.speedX = 0
	end
end

function squeaks.onTickNPC(v)
	if player:isGroundTouching() then
		for _,block in ipairs(Block.getIntersecting(player.x, player.y, player.x + player.width, player.y + player.height + 16)) do
			if block.id == 742 or block.id == 743 then
				pJumpCheck = false
			else
				pJumpCheck = true
			end
		end
	else
		pJumpCheck = false
	end
	if player:mem(0x176, FIELD_WORD) > 0 then
		pJumpCheck = true
	end
end

function squeaks.onTickEndNPC(v)
    if Defines.levelFreeze then return end

	local data = v.data
	if NPC.config[v.id].isSkip and data.lockDirection == nil then
		data.lockDirection = 0
	end

	squeaks.frameCount = NPC.config[v.id].frames
	
    if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138, FIELD_WORD) > 0 then
        v.data.state = 0
        v.data.timer = 0
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 0,
			frames = squeaks.frameCount
		})
		return
    end
	
	if data.dontMove == nil then
        data.dontMove = v.dontMove
        data.timer = 0
    end
	
	if data.canJump == nil then
		data.canJump = true
	end
	
	if NPC.config[v.id].doesFlutter then
		if data.fluttering == nil then
			data.fluttering = false
		end
		if data.flutterTimer == nil then
			data.flutterTimer = 0
		end
	end
	
	if not data.animOverride then -- put 'animOverride = true' in your NPC settings if you want to override this animation control for whatever reason
		squeakAnim(v)
	end
	
	if NPC.config[v.id].isSkip then -- put 'isSkip = true' in your NPC settings if you want it to behave like SM3DW Skipsqueaks
		if data.homeX == nil then
			data.homeX = 0
		elseif data.homeY == nil then
			data.homeY = 0
		elseif data.homeSet == nil then
			data.homeSet = false
		elseif data.skipMove == nil then
			data.skipMove = false
		end
		skipReturn(v)
	end
	
    if data.state == ST_IDLE then
		if not NPC.config[v.id].isSkip then
			v.speedX = 2 * v.direction
		elseif NPC.config[v.id].isSkip and not data.skipMove then
			v.speedX = 0
		end
        if v.collidesBlockBottom and pJumpCheck and data.canJump then
            if player.keys.jump == KEYS_PRESSED or player.keys.altJump == KEYS_PRESSED then
                data.state = ST_CROUCH
            end
        end
    elseif data.state == ST_CROUCH then
        data.timer = data.timer + 1
		v.speedX = 0
        if data.timer == 12 then
            v.speedY = NPC.config[v.id].jumpHeight
            if not NPC.config[v.id].isSkip then
				v.speedX = 2 * v.direction
			end
            data.state = ST_JUMP
			if data.flutterTimer then
				data.flutterTimer = 0
			end
			v.ai5 = 0
            data.timer = 0
        end
    elseif data.state == ST_JUMP then
		if v.speedY >= 0.01 and NPC.config[v.id].doesFlutter and data.fluttering == false then
				data.flutterTimer = 40
				data.fluttering = true
		end
		if v.collidesBlockBottom then
			v.speedX = 0
			data.state = ST_IDLE
			v.ai5 = 0
			if data.fluttering then
				data.fluttering = false
			end
		end
		if v.collidesBlockUp then
			if v.speedY < 0 then
				v.speedY = v.speedY * -1
			end
		end
	end
	if data.flutterTimer then
		if data.flutterTimer > 0 then
			data.flutterTimer = data.flutterTimer - 1
			v.speedY = 0
			if data.flutterTimer >= 39 then
				SFX.play(flutterSound)
			end
		end
	end
		-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = squeaks.frameCount
	});
end

return squeaks