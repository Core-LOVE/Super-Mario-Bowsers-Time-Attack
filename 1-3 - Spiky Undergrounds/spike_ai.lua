--[[

	Written by MrDoubleA
	Please give credit!

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local vectr = require("vectr")



spike = {}

spike.spikeIDs = {}
spike.ballIDs  = {}



function spike.registerSpike(selfID)
	npcManager.registerEvent(selfID,spike,"onTickEndNPC","onTickEndSpike")
	npcManager.registerEvent(selfID,spike,"onDrawNPC","onDrawSpike")
	spike.spikeIDs[selfID] = true
end

function spike.registerBall(selfID)
	npcManager.registerEvent(selfID,spike,"onTickNPC","onTickBall")
	npcManager.registerEvent(selfID,spike,"onDrawNPC","onDrawBall")
	spike.ballIDs[selfID] = true
end

function spike.onInitAPI()
	registerEvent(spike,"onTick")
	registerEvent(spike,"onDraw")
	registerEvent(spike,"onPostNPCKill")
end

local STATE_STANDING = 0
local STATE_THROWING = 1

local cameraColliders = {}

local ballSprite
local fragmentSprite

local colBox = Colliders.Box(0,0,0,0)

-- This function is just to fix   r e d i g i t   issues lol
local function gfxSize(config)
	local gfxwidth  = config.gfxwidth
	if gfxwidth  == 0 then gfxwidth  = config.width  end
	local gfxheight = config.gfxheight
	if gfxheight == 0 then gfxheight = config.height end

	return gfxwidth, gfxheight
end

local function drawBall(id,x,y,frame,priority,rotation)
	local config = NPC.config[id]
	local gfxwidth,gfxheight = gfxSize(config)

	if ballSprite == nil then
		ballSprite = Sprite.box{texture = Graphics.sprites.npc[id].img}
	else
		ballSprite.texture = Graphics.sprites.npc[id].img
	end

	ballSprite.x,ballSprite.y = x,y
	ballSprite.width,ballSprite.height = gfxwidth,gfxheight

	ballSprite.rotation = rotation or 0
	ballSprite.pivot = Sprite.align.CENTRE

	ballSprite.texpivot = Sprite.align.TOPLEFT
	ballSprite.texscale = vector.v2(ballSprite.texture.width,ballSprite.texture.height)
	ballSprite.texposition = vector.v2(-gfxwidth/2,-gfxheight/2)

	ballSprite:draw{priority = priority or -45,sceneCoords = true}
end
spike.drawBall = drawBall

local function getSlopeAngle(v)
	for _,b in ipairs(Block.getIntersecting(v.x,v.y + v.height,v.x + v.width,v.y + v.height + 0.2)) do
		if Block.SLOPE_LR_FLOOR_MAP[b.id] then
			return math.deg(math.atan2(
				(b.y) - (b.y + b.height),
				(b.x + b.width) - (b.x)
			))
		elseif Block.SLOPE_RL_FLOOR_MAP[b.id] then
			return math.deg(math.atan2(
				(b.y + b.height) - (b.y),
				(b.x + b.width) - (b.x)
			))
		end
	end
end



-- Stuff related to spike balls' fragments below



spike.fragments = {}

local function createFragments(id,x,y)
	local config = NPC.config[id]
	local gfxwidth,gfxheight = gfxSize(config)

	for i=1,4 do
		local nX,nY
		if i == 1 or i == 3 then
			nX = x - (gfxwidth / 4)
		else 
			nX = x + (gfxwidth / 4)
		end
		if i == 1 or i == 2 then
			nY = y - (gfxheight / 4)
		else
			nY = y + (gfxheight / 4)
		end

		table.insert(
			spike.fragments,
			{
				id = id,groupIdx = i,
				x = nX,y = nY,
				rotation = 0,
				speedX = RNG.random(-3,3),
				speedY = RNG.random(0,-7),
				collider = Colliders.Box(nX - (gfxwidth / 4),nY - (gfxheight / 4),gfxwidth / 2,gfxheight / 2),
			}
		)
	end
end

function spike.onPostNPCKill(v,killReason)
	if not spike.spikeIDs[v.id] and not spike.ballIDs[v.id] then return end

	local config = NPC.config[v.id]

	if (killReason ~= HARM_TYPE_OFFSCREEN and killReason ~= HARM_TYPE_LAVA) and spike.ballIDs[v.id] then
		createFragments(
			v.id,
			v.x + (v.width / 2) + config.gfxoffsetx,
			v.y + (v.height / 2) + config.gfxoffsety
		)
	elseif (killReason ~= HARM_TYPE_OFFSCREEN and killReason ~= HARM_TYPE_LAVA) and spike.spikeIDs[v.id] and v.data.animationBall then
		if spike.ballIDs[config.throwID] then
			createFragments(
				config.throwID,
				v.x + (v.width / 2) + config.gfxoffsetx,
				(v.y + v.height) + config.gfxoffsety + v.data.animationBall.yOffset - (NPC.config[config.throwID].gfxheight / 2)
			)
		else
			Effect.spawn(10,v.x + (v.width / 2) - 16,v.y + (v.height / 2) - 16)
		end
	end
end

function spike.onTick()
	for _,v in ipairs(Camera.get()) do
		if not cameraColliders[v.idx] then
			cameraColliders[v.idx] = Colliders.Box(0,0,0,0)
		end
		
		cameraColliders[v.idx].x = v.x
		cameraColliders[v.idx].y = v.y
		cameraColliders[v.idx].width = v.width
		cameraColliders[v.idx].height = v.height
	end

	if Defines.levelFreeze then return end

	for k,v in ipairs(spike.fragments) do
		v.speedY = v.speedY + Defines.npc_grav
		if v.speedY > 12 then
			v.speedY = 12
		end

		v.x = v.x + v.speedX
		v.y = v.y + v.speedY

		v.rotation = ((v.rotation + (v.speedX * 6)) % 360)
		
		local gfxwidth,gfxheight = gfxSize(NPC.config[v.id])
		v.collider.x = v.x - (gfxwidth  / 4)
		v.collider.y = v.y - (gfxheight / 4)

		local onCamera = false
		for _,a in ipairs(Camera.get()) do
			if Colliders.collide(cameraColliders[a.idx],v.collider) then
				onCamera = true
				break
			end
		end
		if not onCamera then
			table.remove(spike.fragments,k)
		end
	end
end

function spike.onDraw()
	for _,v in ipairs(spike.fragments) do
		local config = NPC.config[v.id]
		local gfxwidth,gfxheight = gfxSize(config)

		if fragmentSprite == nil then
			fragmentSprite = Sprite.box{texture = Graphics.sprites.npc[v.id].img}
		else
			fragmentSprite.texture = Graphics.sprites.npc[v.id].img
		end

		fragmentSprite.x,fragmentSprite.y = v.x,v.y
		fragmentSprite.width,fragmentSprite.height = (gfxwidth/2),(gfxheight/2)

		fragmentSprite.rotation = v.rotation
		fragmentSprite.pivot = Sprite.align.CENTRE

		fragmentSprite.texpivot = Sprite.align.TOPLEFT
		fragmentSprite.texscale = vector.v2(fragmentSprite.texture.width,fragmentSprite.texture.height)
		fragmentSprite.texposition = vector.v2(
			(-gfxwidth /4)-(((v.groupIdx-1)%2)*(gfxheight/2)),
			(-gfxheight/4)-(math.floor((v.groupIdx-1)/2)*(gfxheight/2))
		)

		fragmentSprite:draw{priority = -5,sceneCoords = true}
	end
end



-- Stuff related to the actual NPCs below



function spike.onTickEndSpike(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.state = nil
		data.timer = nil
		data.animationBall = nil
		return
	end

	local config = NPC.config[v.id]
	local frames = (config.idleFrames + 3)
	if not data.state then
		data.state = STATE_STANDING
		data.timer = 0
		data.animationBall = nil
	end

	-- Animation
	if data.state == STATE_STANDING	then
		v.animationFrame = math.floor(data.timer / config.idleFramespeed) % config.idleFrames
	elseif data.state == STATE_THROWING then
		local b = data.animationBall
		if b and b.speedY >= 0 and b.yOffset >= -v.height then
			v.animationFrame = frames - 1
		elseif b and b.speedY < 0 then
			v.animationFrame = frames - 2
		else
			v.animationFrame = frames - 3
		end
	end
	if config.framestyle >= 1 and v.direction == DIR_RIGHT then
		v.animationFrame = v.animationFrame + frames
	end
	if config.framestyle >= 2 and (v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)) then
		v.animationFrame = v.animationFrame + frames
		if v.direction == DIR_RIGHT then
			v.animationFrame = v.animationFrame + frames
		end
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_STANDING
		data.timer = 0
		data.animationBall = nil
		return
	end

	if data.state == STATE_STANDING then
		data.timer = data.timer + 1
		if data.timer > config.idleTime then
			data.state = STATE_THROWING
			data.timer = 0
		end
	elseif data.state == STATE_THROWING then
		if not data.animationBall then
			data.animationBall = {yOffset = 0,speedY = -5,}
		end
		local b = data.animationBall

		b.speedY = b.speedY + Defines.npc_grav
		if b.speedY > 8 then
			b.speedY = 8
		end
		b.yOffset = b.yOffset + b.speedY

		if b.speedY >= 0 and b.yOffset >= -v.height then
			b.yOffset = -v.height
			b.speedY = 0
			data.timer = data.timer + 1
			if data.timer >= config.holdTime then
				data.state = STATE_STANDING
				data.timer = 0
				local s = NPC.spawn(
					config.throwID,
					v.x + (v.width  / 2),
					v.y - (NPC.config[config.throwID].height / 2) + v.speedY,
					v:mem(0x146,FIELD_WORD),
					false,true
				)
				
				s.direction = v.direction
				s.speedX = (config.throwXSpeed) * v.direction
				s.speedY = -(config.throwYSpeed)
				s.data.rotation = 0
				s.data.bounced = false
				s.friendly = v.friendly
				s:mem(0x136, FIELD_BOOL,true)
				data.animationBall = nil -- Remove animation version of ball

				-- Play throw sound effect
				if config.throwSFX then
					SFX.play(config.throwSFX)
				end
			end
		end
	end
end

function spike.onDrawSpike(v)
	local b = v.data.animationBall
	if v:mem(0x12A, FIELD_WORD) <= 0 or not b then return end

	local config = NPC.config[v.id]
	local bconfig = NPC.config[config.throwID]

	local gfxwidth,gfxheight = gfxSize(bconfig)

	local priority
	if bconfig.priority then
		priority = -16
	else
		priority = -46
	end

	local frame = 0
	if v.direction == DIR_RIGHT and bconfig.framestyle >= 1 then
		frame = bconfig.frames
	end

	drawBall(
		config.throwID,
		(v.x + (v.width / 2)) + bconfig.gfxoffsetx,
		(v.y + v.height) - (gfxheight/2) + b.yOffset + bconfig.gfxoffsety,
		frame,priority,0
	)
end

function spike.onTickBall(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.rotation = nil
		data.bounced = nil
		return
	end
	
	local config = NPC.config[v.id]

	if not data.rotation then
		data.rotation = 0
		data.bounced = v.collidesBlockBottom
		v.speedX = (config.startingSpeed or 2.5) * v.direction
	end

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x138, FIELD_WORD) > 0
	then
		data.rotation = 0
		return
	end

	-- Kill enemies
	if not config.issnowball then
		colBox.x,colBox.y          = v.x+v.speedX,v.y+v.speedY
		colBox.width,colBox.height = v.width,v.height

		local collisions = Colliders.getColliding{
			a = colBox,
			b = NPC.HITTABLE,
			btype = Colliders.NPC,
		}
		local collided = false

		for _,w in ipairs(collisions) do
			if v.idx ~= w.idx then
				w:harm(HARM_TYPE_NPC)
				collided = true
			end
		end

		if collided and config.islarge then
			v:mem(0x120,FIELD_BOOL,false)
		elseif collided then
			v:harm(HARM_TYPE_NPC)
		end
	end
	-- Destroy blocks
	if not config.noblockcollision and v:mem(0x120,FIELD_BOOL) then
		local destroyedBlock = false
		for _,b in ipairs(Block.getIntersecting(v.x + v.speedX,v.y + v.speedY,v.x + v.width + v.speedX,v.y + v.height + v.speedY)) do
			if Block.SOLID_MAP[b.id] and not b.isHidden and not b.layerObj.isHidden then
				if Block.MEGA_SMASH_MAP[b.id] and not config.issnowball then
					b:remove(true)
					destroyedBlock = true
				else
					b:hit()
				end
			end
		end
		
		if not config.islarge or config.issnowball or not destroyedBlock then
			v:kill()
		elseif destroyedBlock then
			v:mem(0x120,FIELD_BOOL,false)
		end
	end

	if config.issnowball then
		for _,p in ipairs(Player.get()) do
			if p.forcedState == 0 and p.deathTimer == 0 and Colliders.collide(v,p) then
				v:kill()
				if (v.x + (v.width / 2)) > (p.x + (p.width / 2)) then
					p.speedX = -2.5
				elseif (v.x + (v.width / 2)) < (p.x + (p.width / 2)) then
					p.speedX = 2.5
				end
				if (v.y + (v.height / 2)) > (p.y + (p.height / 2)) then
					p.speedY = -2.5
				elseif (v.y + (v.height / 2)) < (p.y + (p.height / 2)) then
					p.speedY = 2.5
				end
			end
		end
	end

	v:mem(0x136,FIELD_BOOL,false)
	
	if v.collidesBlockBottom and not data.bounced and v.speedY > -(config.bounceHeight or 4) then
		data.bounced = true
		if not config.bounceHeight or config.bounceHeight > 0 then
			v.speedY = -(config.bounceHeight or 4)
		end
	end

	v.speedX = v.speedX + ((getSlopeAngle(v) or 0) / 896)
	
	if not v.dontMove then
		data.rotation = ((data.rotation or 0) + math.deg((v.speedX*config.speed)/((v.width+v.height)/4)))
	end
end

function spike.onDrawBall(v)
	if v:mem(0x12A, FIELD_WORD) <= 0
	or v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x138, FIELD_WORD) > 0
	then return end

	local data = v.data
	local bconfig = NPC.config[v.id]
	local priority
	if bconfig.priority then
		priority = -15
	else
		priority = -45
	end

	v.animationFrame = -1
	
	drawBall(
		v.id,
		(v.x + (v.width / 2)) + bconfig.gfxoffsetx,
		(v.y + v.height - (bconfig.gfxheight / 2)) + bconfig.gfxoffsety,
		v.animationFrame,priority,data.rotation,bconfig
	)
end

return spike