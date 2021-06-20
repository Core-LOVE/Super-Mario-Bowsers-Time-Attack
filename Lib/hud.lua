local hud = {}
hud.lives = {}
hud.lives[1] = {
	img = Graphics.loadImageResolved("Lib/hud/mario.png"),
	x = 48,
	y = 24,
}
hud.score = {
	img = Graphics.loadImageResolved("Lib/hud/score.png"),
	x = 800 - (96 + 48),
	y = 24,
}
hud.box = {
	img = Graphics.loadImageResolved("Lib/hud/box.png"),
	x = 400 - 18,
	y = 24,
}

hud.x = Graphics.loadImageResolved("Lib/hud/x.png")
hud.numbers = Graphics.loadImageResolved("Lib/hud/numbers.png")

local function draw_numbers(s, x, y)
	x = x or 0
	y = y or 0
	x = x - 16
	
	s = tostring(s)
	
	for i = 1, #s do
		local n = s:sub(i, i)
		
		x = x + 16
		
		Graphics.drawImageWP(
			hud.numbers,
			x,
			y,
			16 * n,
			0,
			16,
			18,
			5
		)
	end
end

local function draw_box()
	local v = hud.box
	
	Graphics.drawImageWP(v.img, v.x, v.y, 5)
	
	if player.reservePowerup > 0 then
		local c = NPC.config[player.reservePowerup]
		
		local x = (c.width / 2) - 18
		local y = (c.height / 2) - 18
		
		Graphics.drawImageWP(Graphics.sprites.npc[player.reservePowerup].img, v.x - x, v.y - y, 4)
	end
end

local function draw_lives()
	local v = hud.lives[1]
	Graphics.drawImageWP(v.img, v.x, v.y, 5)
	Graphics.drawImageWP(hud.x, v.x + 30, v.y + 2, 5)
	draw_numbers(mem(0x00B2C5AC, FIELD_FLOAT), v.x + 48, v.y)
end

local function draw_score()
	local v = hud.score
	
	Graphics.drawImageWP(v.img, v.x, v.y, 5)
	draw_numbers(SaveData._basegame.hud.score, v.x, v.y + 16)
end

function hud.draw()
	draw_lives()
	draw_score()
	draw_box()
end

Graphics.overrideHUD(hud.draw)
return hud