local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local fireball = {}
local npcID = NPC_ID

local fireballSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 16,
	height = 16,
	
	frames = 3,
	framestyle = 0,
	framespeed = 4,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false,
	nohurt = false,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi = true,
	nowaterphysics = false,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	ignorethrownnpcs = true,
}

npcManager.setNpcSettings(fireballSettings)
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})


local function homeIn(v,playerObj)
	local config = NPC.config[v.id]

	local distance = vector(
		(playerObj.x+(playerObj.width /2))-(v.x+(v.width /2)),
		(playerObj.y+(playerObj.height/2))-(v.y+(v.height/2))
	)


	v.speedX = 3*math.sign(distance.x)
	v.speedY = math.clamp((distance:normalise().y)*3,-2,2)*config.speed
end


function fireball.onInitAPI()
	npcManager.registerEvent(npcID,fireball,"onTickNPC")
end

function fireball.onTickNPC(v)
	if Defines.levelFreeze then return end
	
		if v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockBottom or v.collidesBlockTop then
		v:kill(9)
                Animation.spawn(10,v.x,v.y-12)
	end

        for k,b in ipairs(NPC.getIntersecting(v.x - 2, v.y - 2, v.x + v.width + 2, v.y + v.height + 2)) do
        if b.id ~= 753 and b ~= v and b.id ~= NPC_ID then
        v:kill(9)
        Effect.spawn(10, v.x, v.y - 12)
        end
        end

	local data = v.data
	if v.despawnTimer <= 0 then
		data.hasStartedHoming = nil
		return
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then return end
	
	if not data.hasStartedHoming then
		local playerObj = npcutils.getNearestPlayer(v)

		if playerObj ~= nil then
			data.hasStartedHoming = true
			homeIn(v,playerObj)
		end
	end
end


return fireball