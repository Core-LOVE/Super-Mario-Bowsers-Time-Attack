--Sex shop

local shop = {}
shop.items = {}

local function resolveImage(path)
return Graphics.loadImage(Misc.resolveFile(path))
end

shop.coins = 0

shop.opacity = -0.25
shop.background = resolveImage 'shop/background.png'
shop.window = resolveImage 'shop/window.png'
shop.gradient = resolveImage 'shop/gradient.png'

shop.icon1 = resolveImage 'shop/icon1.png'
shop.icon2 = resolveImage 'shop/icon2.png'

shop.coin = resolveImage 'shop/shop1up.png'


shop.active = false


shop.selected = 0
shop.select = 0

shop.keydelay = 0

do

	local v = shop
	
	function shop:show(items, currency)
		v.items = items or {}
		v.coins = currency or 0
		
		Misc.pause()
		SFX.play 'shop/open.wav'
		v.active = true
	end

	function shop:unshow()
		if not v.active or v.keydelay > 0 then return end
		
		if v.select ~= 0 then
			v.select = 0
			
			v.keydelay = 12
			return
		else
			SFX.play 'shop/leave.wav'
			v.active = false
			return
		end
	end

end


function shop.item(name, icon, desc, cost, fun)
	return {
		name = name or "Super Mushroom",
		icon = icon or Graphics.sprites.npc[9].img,
		desc = desc or "OM NOM NOM",
		cost = cost or 10,
		func = fun or nil,
	}
end


do
	local v = shop
	
	local img = v.background
	local img2 = v.window
	
	local alpha = v.opacity 
	
	local x = 0
	local sin = 0
	
	local y = 256
	local a = 4
	
	local function bg()
		if not v.active then
			if alpha > 0 then
				alpha = alpha - 0.05
			end
		end
		
		if alpha < 1 and v.active then
			alpha = alpha + 0.1
		end
		
		Graphics.drawImageWP(v.gradient, 0, 0, alpha, 5)
		
		
		x = (x + 1)
		if x > 800 then
			x = 0
			sin = -sin
		end
		
		sin = sin + 0.1
		
		local s = math.sin(sin) * 32
		
		Graphics.drawImageWP(img, x, s + 300, alpha, 5)
		Graphics.drawImageWP(img, x, s - 300, alpha, 5)
		
		Graphics.drawImageWP(img, x - 800, (-s) + 300, alpha, 5)
		Graphics.drawImageWP(img, x - 800, (-s) - 300, alpha, 5)
	end
	
	local function menu()
		if not v.active then
			if y < 256 then
				y = y + a
			end
			
			if a < 4 then
				a = a + 1
			end
		end
		
		if v.active then
			if a > 0 then
				a = a - 0.1
			end
			
			if y > 0 then
				y = y - (a * 3)
			end
		end
		
		Graphics.drawImageWP(img2, 0, y + 400, alpha, 5)
		
		do
			local vx = 32
			local vy = y + 400
			local s = v.selected + 1
			
			local icn = v.icon1
			local icn2 = v.icon2
			local brlin = 0
			
			for i = 1, 20 do
				local ic = v.items[i]
				
				local a = alpha
				if v.select ~= 0 and s ~= i then
					a = alpha - 0.75
				end
			
				if ic == nil then return end
				
				
				vx = vx + 52
				
				brlin = brlin + 1
				if brlin > 12 then
					vx = 32 + 52
					vy = vy + 52
					brlin = 0
				end
				
				Graphics.drawImageWP(icn, vx, vy + 52, a, 5)
				Graphics.drawImageWP(ic.icon, vx + 2, vy + 52 + 2, 0, 0, 32, 32, a, 5)
				
				if s == i then
					Graphics.drawImageWP(icn2, vx - 3, vy + 52 - 3, alpha, 5)
				end
			end
		end
	end
	
	do
		local ix = 0
		local ac = 16
		local sl = v.selected + 1
		
		local textplus = require 'textplus'
		
		local line = resolveImage 'shop/line.png'
		
		
		local function description()
			if not v.active then 
				if ix ~= 0 then
					ix = 0
				end
				
				if ac < 16 then
					ac = ac + 1
				end
				
				return
			end
			
			if ac > 0 then
				ac = ac - 0.5
			end
			
			ix = ix + (ac / 2.5)
			
			if sl ~= v.selected + 1 then
				ix = 0
				ac = 16
				sl = v.selected + 1
			end
			
			local i = v.items[v.selected + 1]
			
			local t = {
				x = {[1] = ix - 32},
				y = {[1] = 96, [2] = (ix * 1.5) - 96, [3] = (ix * 1.5) - 64},
				scale = {[2] = 1.75},
				col = {[2] = Color.fromHexRGB(0x00FFFF)},
				text = {[2] = "Description:", [3] = i.desc}
			}
			
			for nm = 1, 3 do
				textplus.print{
					x = t.x[nm] or 320,
					y = t.y[nm] or 96,
					text = t.text[nm] or i.name,
					priority = 6,
					color = t.col[nm] or Color.white,
					xscale = t.scale[nm] or 2,
					yscale = t.scale[nm] or 2,
				}	
			end
			
			Graphics.drawImageWP(i.icon, ix - 32, 96 + 42, 0, 0, 32, 32, 6)
			
			Graphics.drawImageWP(v.coin, ix - 32, 96 + (42 + 48), 0, 0, 32, 32, 6)
			Graphics.drawImageWP(v.coin, ix - 32 - 48, 96 - 64, 0, 0, 32, 32, 6)
			
			textplus.print{
				x = ix - 56,
				y = 96 - 64,
				text = "x " .. tostring(v.coins),
				priority = 6,
				xscale = 2,
				yscale = 1.75
			}	
			
			
			local c = {[1] = Color.black}
			
			for n = 1,2 do
				local lx = 1.5
				local ly = 1.5
				
				local cl = Color.white
				
				if i.cost > v.coins then
					cl = Color.red
				end
				
				if n == 2 then lx, ly = 0, 0 end
				
				textplus.print{
					x =ix - 8 + lx,
					y = 96 + (42 + 46) + ly,
					text = "x " .. i.cost,
					priority = 6,
					xscale = 2,
					yscale = 2,
					color = c[n] or cl
				}	
			end
			
			local st = v.coins .. " - " .. i.cost .. " = " .. (v.coins - i.cost)
			if i.cost > v.coins then
				st = i.cost .. " - " .. v.coins .. " = " .. (i.cost - v.coins)
			end
			
			textplus.print{
				x =ix - 16,
				y = 96 + (42 + 64),
				text = st,
				priority = 6,
				xscale = 1.75,
				yscale = 1.75,
				color = Color.fromHexRGB(0x00FFFF)
			}	
			
			Graphics.drawImageWP(line, ix - (400 / 3), ix - 150, 6)
		end
		
		
		function shop.onCameraDraw()
			bg()
			menu()
			description()
			
			v.opacity = alpha
		end
	end
end


do
	local v = shop
	
	function shop.onInputUpdate()
		local p = player.keys
		
		if not v.active then
			if v.opacity <= 0 then
				Misc.unpause()
			end
			
			return
		end
		
		if v.keydelay <= 0 and v.active and v.select == 0 then
			if p.left then
				
				v.selected = v.selected - 1
				if v.selected < 0 then
					v.selected = #v.items - 1
				end
				
				SFX.play 'shop/select.wav'
				v.keydelay = 12
			elseif p.right then
				v.selected = (v.selected + 1) % #v.items
				
				SFX.play 'shop/select.wav'
				v.keydelay = 12
			end
			
			if p.jump and v.items[v.selected + 1].cost <= v.coins then
				v.select = 1
				
				SFX.play 'shop/enter.wav'
				v.keydelay = 16
			end
		elseif v.keydelay > 0 and v.active then
			v.keydelay = v.keydelay - 1
		end
		
		if v.select == 1 and v.keydelay <= 0 then
			if p.run then
				v.select = 0
				
				v.keydelay = 12
			elseif p.jump then
				v.select = 0
				
				if type(v.items[v.selected + 1].func) == 'function' then
					v.items[v.selected + 1].func()
				end
				
				v.coins = v.coins - v.items[v.selected + 1].cost
				
				SFX.play 'shop/buy.wav'
				v.keydelay = 12
			end
		end
		
		if (player.rawKeys.pause == KEY_PRESSED or p.run == KEY_PRESSED) and shop.active then
			shop:unshow()
		end
	end
end

function shop.onInitAPI()
	registerEvent(shop, "onCameraDraw")
	registerEvent(shop, "onInputUpdate")
end

setmetatable(shop, {__call = function(self, t, c)
	return self:show(t, c)
end})
return shop