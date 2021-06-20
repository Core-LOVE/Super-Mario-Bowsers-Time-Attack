pipeAPI = loadAPI("pipecannon")

pipeAPI.exitspeed = {17}

pipeAPI.SFX = 22

pipeAPI.effect = 10

local effect = Particles.Emitter(0, 0, Misc.resolveFile("p_fog.ini"))
effect:AttachToCamera(camera)

function onCameraDraw()
	effect:Draw(-1)
end

function onTickEnd()
	for k,v in ipairs(NPC.get(5)) do
		if v.animationFrame ~= 0 and math.random() >= 0.5 and (v.speedY < 0 and v.speedY > -0.25) then
			local x = v.width + 4
			if v.direction == 1 then
				x = -4
			end
			
			local e = Effect.spawn(74, v.x + x, v.y + v.height - 4)
			e.speedY = -0.1
			e.speedX = v.speedX / 100
		end
	end
	
	for k,v in ipairs(Effect.get(4)) do
		local e = Effect.spawn(751, v.x, v.y + 16)
		e.speedY = v.speedY
		e.speedX = v.speedX
		v.id = 0
	end
end