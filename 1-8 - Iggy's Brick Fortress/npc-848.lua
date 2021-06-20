local npc = {}

function npc.onInitAPI()
	local npcManager = require "npcManager"
	
	npcManager.registerEvent(NPC_ID, npc, "onCameraDrawNPC")
	npcManager.registerEvent(NPC_ID, npc, "onTickEndNPC")
end

function npc.onTickEndNPC(v)
	local data = v.data
	
	if not data.init then
		data.sprite = Sprite{texture = Graphics.sprites.npc[NPC_ID].img, x = v.x, y = v.y, frames = 10, pivot = Sprite.align.CENTRE, texpivot = Sprite.align.CENTRE}
		data.reflection = Sprite{texture = Graphics.sprites.npc[NPC_ID].img, x = v.x, y = v.y, frames = 10, pivot = Sprite.align.CENTRE, texpivot = Sprite.align.CENTRE}
		data.frame = 1
		data.frametimer = 0
		
		data.init = true
	end
	
	data.frametimer = (data.frametimer + 1)
	if data.frametimer >= NPC.config[NPC_ID].framespeed then
		data.frame = data.frame + 1
		data.frametimer = 0
		if data.frame > 8 then
			data.frame = 1
		end
	elseif data.frametimer < 0 then
		data.frame = data.frame - 1
		data.frametimer = 8
		if data.frame <= 0 then
			data.frame = 8
		end
	end
		
	data.sprite:rotate(v.speedX / 1.5)
	
	data.sprite.x = v.x + v.width / 2
	data.sprite.y = v.y	+ v.height / 2
	
	data.reflection.x = v.x + v.width / 2
	data.reflection.y = v.y	+ v.height / 2
	
	if data.gravity then
		v.speedY = v.speedY + data.gravity
	end
	
	v.animationFrame = -1
end

function npc.onCameraDrawNPC(v)
	local data = v.data
	if not data.init then return end
	
	data.sprite:draw{sceneCoords = true, frame = data.frame, priority = -5}
	data.reflection:draw{sceneCoords = true, frame = 9, priority = -4}
	data.reflection:draw{sceneCoords = true, frame = 10, priority = -4}
end

return npc