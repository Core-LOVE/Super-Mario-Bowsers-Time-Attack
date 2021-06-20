local shop = require 'shop'

local fireflower = shop.item('Fire Flower', Graphics.sprites.npc[14].img, "What a nice flower!", 20, function()
local c = mem(0x00B2C5AC,FIELD_FLOAT)
c = c - 20
mem(0x00B2C5AC,FIELD_FLOAT, c)

player.reservePowerup = 14
end)

local supermushroom = shop.item('Super Mushroom', Graphics.sprites.npc[9].img, "Interesting shroom...", 15, function()
local c = mem(0x00B2C5AC,FIELD_FLOAT)
c = c - 15
mem(0x00B2C5AC,FIELD_FLOAT, c)

player.reservePowerup = 9
end)

local leaf = shop.item('Leaf', Graphics.sprites.npc[34].img, "This leaf will let you fly!", 30, function()
local c = mem(0x00B2C5AC,FIELD_FLOAT)
c = c - 30
mem(0x00B2C5AC,FIELD_FLOAT, c)

player.reservePowerup = 34
end)


local iceflower = shop.item('Ice Flower', Graphics.sprites.npc[264].img, "Brrrr... cold...", 30, function()
local c = mem(0x00B2C5AC,FIELD_FLOAT)
c = c - 30
mem(0x00B2C5AC,FIELD_FLOAT, c)

player.reservePowerup = 264
end)

local tanookisuit = shop.item('Tanooki Suit', Graphics.sprites.npc[169].img, "Like a leaf, but more useful.", 70, function()
local c = mem(0x00B2C5AC,FIELD_FLOAT)
c = c - 70
mem(0x00B2C5AC,FIELD_FLOAT, c)

player.reservePowerup = 169
end)

local hammersuit = shop.item('Hammer Suit', Graphics.sprites.npc[170].img, "An extremely powerful weapon.", 99, function()
local c = mem(0x00B2C5AC,FIELD_FLOAT)
c = c - 99
mem(0x00B2C5AC,FIELD_FLOAT, c)

player.reservePowerup = 170
end)

local starman = shop.item('Starman', Graphics.sprites.npc[1000].img, "This might be helpful.", 30, function()
local c = mem(0x00B2C5AC,FIELD_FLOAT)
c = c - 30
mem(0x00B2C5AC,FIELD_FLOAT, c)

player.reservePowerup = 1000
end)

function onMessageBox(e, m, v, n)
if n.id == 94 then
shop({
supermushroom,
fireflower,
leaf,
iceflower,
tanookisuit,
hammersuit,
starman
}, mem(0x00B2C5AC,FIELD_FLOAT))

e.cancelled = true
end
end