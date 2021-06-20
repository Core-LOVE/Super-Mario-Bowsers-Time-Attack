local p = {}
p.animation = {}

local earthquake = require 'Lib/earthquake'
local animation = require 'Lib/animation'

function p.addCharacter(char, name)
	p[char] = {}
	
	for i = 1, 7 do
		local f = Misc.resolveFile(name .. tostring(i) .. ".png")
		
		if f then
			p[char][i] = Graphics.loadImage(f)
		end
	end
	
	return p[char]
end

function p.onInitAPI()
	registerEvent(p, "onCameraDraw")
	registerEvent(p, "onInputUpdate")
	registerEvent(p, "onBlockHit")
end

function p.onBlockHit(e,v,u,p)
	if p then
		Effect.spawn(73, p.x, p.y - p.height / 2)
		earthquake(0.4, true)
	end
end

do
	local imagic = require 'imagic'
	
	function p.updateChar(v)
	
	end
	
	function p.drawChar(v)
		local img = p[v.character][v.powerup]
		local a = p.animation[v.idx]
		
		local sX = 62 * (a:getFrame() or 0)
		local sY = 62 * a:getState()
		
		if a then
			if v.speedX == 0 then
				sX = 0
			end
			
			local s = math.abs(v.speedX) / 2
			
			if v.speedY == 0 then
				if v.keys.down then
					local duckHeight = v:getCurrentPlayerSetting().hitboxDuckHeight
					local dh = v.height - duckHeight
					v.height = duckHeight
					v.y = v.y + dh
					
					a:setState(1)
					s = 0.5
					v:mem(0x12E, FIELD_BOOL, true)
				else
					if (v.keys.right and v.speedX < 0) or (v.keys.left and v.speedX > 0) then
						a:setState(3)
					else
						a:setState(0)
					end
				end
			else
				if v:mem(0x50, FIELD_BOOL) then
					a:setState(0)
					sX = 0
				elseif v:mem(0x48, FIELD_WORD) ~= 0 or v:mem(0x176, FIELD_WORD) ~= 0 then
					a:setState(0)
				else
					a:setState(2)
					s = 1
				end
			end
			
			a:update(s)
		end
		
		if img then
			v.frame = -51 * v.direction
			
			local x = v.x - 20
			local y = v.y - 18
			
			if v.direction == -1 then
				imagic.draw{
					texture = img,
					
					x = x + 62,
					y = y,
					scene = true,
					
					sourceX = sX,
					sourceY = sY,
					sourceWidth = 62,
					sourceHeight = 62,
					
					priority = -20,
					
					width = -62
				}
			else
				Graphics.drawImageToSceneWP(
					img,
					
					x,
					y,
					
					sX,
					sY,
					
					62,
					62,
					
					-20
				)
			end
		end	
	end
end

function p.updateChar(v)
	if v:mem(0x12E, FIELD_BOOL) then
		v.keys.left = false
		v.keys.right = false
	end
end

function p.onInputUpdate()
	for i = 1, Player.count() do
		local v = Player(i)
		
		if v then
			p.updateChar(v)
		end
	end
end

function p.onCameraDraw()
	for i = 1, Player.count() do
		local v = Player(i)
		
		if v then
			if not p.animation[v.idx] then
				p.animation[v.idx] = animation.new()
				
				local a = p.animation[v.idx]
				
				a:defineState(0, {0,1} )
				a:defineState(1, {0,1, stop = true, framedelay = 10} )	
				a:defineState(2, {0,1, stop = true, framedelay = 12} )
				a:defineState(3, {0} )
				
				a:setState(0)
			end
			
			p.drawChar(v)
		end
	end
end

p.addCharacter(CHARACTER_MARIO, 'mario')
return p