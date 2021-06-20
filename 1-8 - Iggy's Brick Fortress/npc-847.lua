local npc = {time = 0}

function npc.onInitAPI()
	local npcManager = require "npcManager"
	
	npcManager.registerEvent(NPC_ID, npc, "onTickEndNPC")
	registerEvent(npc, "onCameraUpdate")
end

do
	local function spawn(v)
		if not v.data.init then
			v.data.cos = 0
			
			v.data.y = 32
			v.data.hurt = 0
			v.data.hp = 0
			
			v.data.ball = NPC.spawn(848, v.x + 16, v.y + v.height, v.section)
			v.data.ball.data.cos = 0
			v.data.ball.data.sin = 0
			
			v.data.init = true
		end
	end
	
	local function ball(v)
		local b = v.data.ball
		
		if b == nil or not b.isValid then return end
		
		local data = b.data
		local d = v.data
		
		data.cos = data.cos + 0.025
		data.sin = data.sin - 0.050
		
		b.speedX = (math.cos(data.cos) * 4) + v.speedX
		b.speedY = (math.sin(data.sin) * 4) + v.speedY
		
		for i = -1,1,0.5 do
			local c
			if i ~= 0 then
				c = Color.gray
			end
			
			Graphics.drawLine{
				x1 = v.x + v.width / 2 + i, 
				y1 = v.y + v.height / 2 + i, 
				x2 = b.x + b.width / 2 + i, 
				y2 = b.y + b.height / 2 + i, 
				sceneCoords = true, 
				priority = -84,
				color = c or Color.white
			}
		end
		
		if data.frametimer then
			data.frametimer = data.frametimer + ( (math.sin(data.sin) * 2) )
		end
	end
	
	local function harm(p, v)
		if v.data.hurt >= 0 and p.deathTimer <= 0 then 
                        SFX.play(39)
			Effect.spawn(73, p.x, p.y)
			Effect.spawn(76, v.x + v.width / 2, v.y + 16)
			p.speedX = -p.speedX
			p.speedY = -p.speedY
			p:mem(0x11C, FIELD_WORD, -1)
			
			Defines.earthquake = 8
			
			Misc.pause()
			npc.time = 8
			
			v.data.hp = v.data.hp + 1
			
			if v.data.hp == 5 then
				Effect.spawn(847, v.x, v.y)
				
				local b = v.data.ball
				b.speedX = 8 * -p.direction
				b.speedY = -12
				b.data.gravity = 0.3
				
				v:kill(9)
				
				return
			end
			
			v.data.hurt = -96
		end
	end
	
	function npc.onTickEndNPC(v)
		if player.section ~= 4 then 
			v:mem(0x12A, FIELD_WORD, 180)
			v.speedX = 0
			v.speedY = 0
			
			return 
		end
		
		spawn(v)
		ball(v)
		
		local data = v.data
		
		if data.y > 0 then
			data.y = data.y - 1
			v.speedY = (data.y)		
		elseif data.y <= 0 then
			data.cos = data.cos + 0.01 + (data.hp / 100)
			v.speedX = math.cos(data.cos) * (2.5 + (data.hp * 2))
		end
			
		for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			harm(p, v)
		end
		
		if data.hurt < 0 then
			if math.random(0, 32) > 16 then
				if v.direction == -1 then
					v.animationFrame = 4
				else
					v.animationFrame = 5
				end
				
				v.animationTimer = 4
			end
			
			data.hurt = v.data.hurt + 1
		end
		
		if data.hp == 3 then
			if math.random(0, 16) > 12 then
				local e = Effect.spawn(250, v.x + math.random(0, v.width), v.y + 48)
				e.speedY = math.random(4,8) * -1
				e.speedX = math.random(-1,1)
			end
		end
		
		v.animationTimer = v.animationTimer + math.abs(v.speedX)
	end
end

function npc.onCameraUpdate()
	if npc.time > 1 then
		npc.time = npc.time - 1
	elseif npc.time == 1 and Misc.isPaused() then
		Misc.unpause()
		npc.time = 0
	end
end

return npc