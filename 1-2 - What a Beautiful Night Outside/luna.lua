local lamps = {}
local imagic = require 'imagic'
	
function isColliding(a,b)
   if ((b.x >= a.x + a.width) or
	   (b.x + b.width <= a.x) or
	   (b.y >= a.y + a.height) or
	   (b.y + b.height <= a.y)) then
		  return false 
   else return true
	   end
end
	
local function spawn_lamp(v)
	local o = {}
	
	o.img = Graphics.loadImage('lamp.png')
	o.x = v.x + 40
	o.y = v.y + 34
	o.width = o.img.width
	o.height = o.img.height
	
	o.rot = 0
	o.rot_direction = 0
	
	o.time = 0
	o.light = NPC.spawn(674, v.x + 40, v.y + 34, player.section)
	
	if o.light.data._basegame.light then
		local data = o.light.data._basegame.light
		
		data.color = Color.fromHexRGB(0xFFF4BF)
		data.brightness = 2
	end
	
	table.insert(lamps, o)
	return o
end

function onStart()
    for k,v in ipairs(BGO.get(6)) do
		spawn_lamp(v)
	end
end

function onCameraDraw()
	for i = 1, #lamps do
		local v = lamps[i]
		
		if v then
			local r = math.sin(v.time / 10) * (v.rot * v.rot_direction)
			local l = v.light.data._basegame.light
			
			if l then
				l.dir = vector.down2:rotate(r)
				local b = BGO(i)
				v.light.x = v.x
				v.light.y = v.y
			end
			
			if isColliding(v, camera) then
				if v.rot <= 0 then
					if v.time ~= 0 then
						v.time = 0
					end
					
					if isColliding(v, player) then
						if player.speedX == 0 then
							player.speedX = 1
						end
						
						v.rot = math.abs(player.speedX * 12)
						v.rot_direction = math.sign(player.speedX)
						player.speedX = -player.speedX
					end
				elseif v.rot > 0 then
					v.rot = v.rot - 0.5
					
					v.time = v.time + 1
				end
				
				imagic.draw{
					texture = v.img,
						
					x = v.x + v.width / 2,
					y = v.y,
					scene = true,
						
					align = imagic.ALIGN_TOPCENTRE,
					
					priority = -25,
					rotation = r,
				}
			end
		end
	end
end