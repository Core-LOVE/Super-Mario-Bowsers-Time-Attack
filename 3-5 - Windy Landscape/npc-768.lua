local np = {}
local npcManager = require("npcManager")
local imagic = require("imagic")
local c = NPC.config[NPC_ID]

npcManager.registerHarmTypes(NPC_ID, {HARM_TYPE_LAVA, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_SWORD}, {})

function np.onInitAPI()
	npcManager.registerEvent(NPC_ID, np, "onDrawNPC")
	npcManager.registerEvent(NPC_ID, np, "onTickEndNPC")	
end

local COLLISION_SIDE_NONE    = 0
local COLLISION_SIDE_TOP     = 1
local COLLISION_SIDE_RIGHT   = 2
local COLLISION_SIDE_BOTTOM  = 3
local COLLISION_SIDE_LEFT    = 4
local COLLISION_SIDE_UNKNOWN = 5

local function side(Loc1, Loc2, leniencyForTop)
    leniencyForTop = leniencyForTop or 0
    
    if(Loc1.y + Loc1.height - Loc1.speedY <= Loc2.y - Loc2.speedY + leniencyForTop) then
        return COLLISION_SIDE_TOP
    elseif(Loc1.x - Loc1.speedX >= Loc2.x + Loc2.width - Loc2.speedX) then
        return COLLISION_SIDE_RIGHT
    elseif(Loc1.x + Loc1.width - Loc1.speedX <= Loc2.x - Loc2.speedX) then
        return COLLISION_SIDE_LEFT
    elseif(Loc1.y - Loc1.speedY > Loc2.y + Loc2.height - Loc2.speedY - 0.1) then
        return COLLISION_SIDE_BOTTOM
    else
        return COLLISION_SIDE_UNKNOWN
	end
end

local function checkCollision(Loc1, Loc2)
    if(Loc1.y + Loc1.height >= Loc2.y) then
        if(Loc1.y <= Loc2.y + Loc2.height) then
            if(Loc1.x <= Loc2.x + Loc2.width) then
                if(Loc1.x + Loc1.width >= Loc2.x) then
					return true
                end
            end
        end
    end
	
	return false
end

local function canComeOut(Loc1, Loc2)
    if(Loc1.x <= Loc2.x + Loc2.width + 32) then
        if(Loc1.x + Loc1.width >= Loc2.x - 32) then
            if(Loc1.y <= Loc2.y + Loc2.height + 300) then
                if(Loc1.y + Loc1.height >= Loc2.y - 300) then   
                    return false
                end
            end
        end
    end
	
	return true
end

local function onSpawn(v)
	v.height = 0
	v.ai1 = c.height
	v.frame = 0
	if v.direction == 1 then v.frame = c.frames end
	v.framecount = 0
	
	v.spawned = true
end

local function onAnimation(n)
	if n.spawned == nil then return end
	
	n.framecount = n.framecount + 1
	if n.framecount >= c.framespeed then
		n.framecount = 0
		n.frame = n.frame + 1
		if n.frame >= c.frames then
			n.frame = 0
		end
	end
end

local function killIt(v)
	Effect.spawn(131, v.x + (c.width / 2) - 16, v.y + c.height / 2)
	v:kill(3)
end

local function comeOut(v)
	local vy = (v.y + v.ai1)
	local vh = v.y + (c.height - v.ai1)
	
	if v.direction == 1 then
		local vy = v.y + (c.height - v.ai1)
		local vh = v.y + v.ai1
	end
	
	for _,p in ipairs(Player.getIntersecting(v.x, vy, v.x + v.width, vh)) do
		if side(v,p) == COLLISION_SIDE_BOTTOM and v.direction == -1 then
			SFX.play(2)
			Effect.spawn(75, p.x + p.width / 2 - 16, p.y + p.height / 2 - 16)
			p:mem(0x11C,FIELD_WORD,-1)
			if p.keys.jump or p.keys.altJump then
				p.speedY = -8.4
			else
				p.speedY = -5.3
			end
			p.y = vy - p.height - 1
		elseif (side(v,p) ~= COLLISION_SIDE_BOTTOM and p.y > vy) or v.direction == 1 then
			p:harm()
		end
	end
	
	for _,n in ipairs(NPC.getIntersecting(v.x - 16, vy - 16, v.x + v.width + 16, vh + 16)) do
		if n.id == 13 or n.id == 171 or n.id == 292 or n.id == 291 or n.id == 266 or (n:mem(0x136, FIELD_BOOL) and n.id ~= 265) or n:mem(0x12C, FIELD_WORD) > 0 then
			if n.id ~= 171 and n.id ~= 266 and n.id ~= 292 and not NPC.config[n.id].isshell then
				n:kill(4)
			end
			
			if n:mem(0x12C, FIELD_WORD) > 0 then
				n:kill(4)
			end
			
			killIt(v)
		elseif n.id == 265 then
			SFX.play(9)
			n:kill(4)
			Effect.spawn(131, v.x + (c.width / 2) - 16, v.y + c.height / 2)
			v.width = c.width
			v.height = (c.height - v.ai1)
			v.id = 263
			v.ai1 = NPC_ID
		end
	end
end

function np.onDrawNPC(v)
	if v.spawned == nil then return end
	
	v.animationFrame = -1

	if v.direction == -1 then
		Graphics.drawImageToSceneWP(
			Graphics.sprites.npc[NPC_ID].img,
			v.x + c.gfxoffsetx,
			v.y + c.gfxoffsety + (v.ai1 * -v.direction),
			0,
			c.height * v.frame,
			c.width,
			c.height - v.ai1, 
			-75.0
		)
	else
		imagic.Draw{
			texture = Graphics.sprites.npc[NPC_ID].img, 
			x = v.x + c.gfxoffsetx + (c.width / 2), 
			y = v.y + c.gfxoffsety + (c.height / 2) + (v.ai1 * -v.direction),
	        align=imagic.ALIGN_CENTRE, 		
			width = c.width,
			height = c.height,
			sourceY = c.height * v.frame,
			sourceHeight = c.height,
			rotation = 180, 
			scene = true, 
			priority = -75.0
		}
	end
end

function np.onTickEndNPC(v)
	if v.spawned == nil then
		onSpawn(v)
	end
	onAnimation(v)
	
	if v.ai2 > 48 then
		v.ai2 = v.ai2 + 1
		v.ai1 = v.ai1 - 1
	elseif v.ai2 < 0 then
		v.ai1 = v.ai1 + 1
	end
	
	if v.ai2 <= 48 then
		for k,p in ipairs(Player.get()) do
			if canComeOut(v,p) and checkCollision(v, Camera(k % 2)) then
				v.ai2 = v.ai2 + 1
			end
		end
	end
	
	if v.ai1 < 0 then
		v.ai1 = 0
		v.ai3 = v.ai3 + 1
	elseif v.ai1 > c.height then
		v.ai1 = c.height
	end
	
	if v.ai3 == 5 or v.ai3 == 15 or v.ai3 == 25 then
		local vs = 6
		local hs = 3
		if v.ai3 == 15 then
			vs = 10
			hs = -1
		elseif v.ai3 == 25 then
			vs = 8
			hs = 2
		end
		SFX.play(18)
		local n = NPC.spawn(769, v.x + (v.width / 2) - 16, v.y + 16)
		if v.direction == 1 then
			n.y = v.y + (c.height - 16)
		end
		n.speedY = vs * v.direction
		n.speedX = hs
		v.frame = 1
		v.framecount = 0
	end
	
	if v.ai3 > 80 then
		v.ai3 = 0
		v.ai2 = -c.height - 16
	end
	
	comeOut(v)
end

return np