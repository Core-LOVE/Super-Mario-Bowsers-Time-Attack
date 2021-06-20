local npcManager = require("npcManager")
local rng = require("rng")
local colliders = require("colliders")

local npc = {}
local npc_list = {1,2,71,244,3,379,389,616,618,4,5,6,7,72,73,76,161,303,304,36,307,89,27,466,467,172,173,174,175,176,177,29,390,13,291,265,171,155,165,166,167,162,163,285,286,48,380,431,416,382,383,409,408,77,407,109,110,111,112,113,114,115,116,117,118,119,120,194,154,155,156,157,134,19,20,25,130,131,132,470,471,129,530,374,135,261,144,92,141,139,140,142,145,143,146,241,249,22,202,352,39,262,201,15,86,267,268,617,136,137,9,90,612,611,30,184,186,153,200,280,281,357,368,369,301,426,189,415,296,309,446,448,365,185,26,31,32,457,187,190,125,127,126,128,531,532,623,624,242,243,578,579,54,53,168,472,666,273,59,61,63,65,451,454,452,453,238,158,425,58,35,191,193,433,434,278,279,562,563,375,293,358,164,320,321,311,312,313,314,315,316,317,318,271,195,427,107,403,102,404,405,489,254,250,94,75,101,198,95,98,99,100,148,149,150,228,325,326,327,328,329,330,331,332,182,183,277,264,14,169,170,34}
local hurt_list = {437,295,435,432,540,428,429}
local coin_list = {10,103,33,258,274,138,88,251,252,253,152}
local npcID = NPC_ID

local npcSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 6,
	framestyle = 0,
	framespeed = 5,
	speed = 0.9,
    cliffturn = true,
	npcblock = false,
	
	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,	
    noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = true
}

local config = npcManager.setNpcSettings(npcSettings)
npcManager.registerDefines(npcID, {NPC.HITTABLE})

function npc.onInitAPI()
	npcManager.registerEvent(npcID, npc, "onTickNPC")
end

function npc.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	if data.wheight == nil then data.wheight = 160 end;

	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		return
	end
	
	if not data.initialized then
		v.friendly = true
		v.speedX = config.speed * v.direction
		data.initialized = true
	end
	
    local effect = Animation.spawn(760, v.x + v.width/4, v.y + v.height/75)
	effect.speedY = rng.randomInt(-data.wheight / 20, -data.wheight / 20)
	effect.speedX = rng.randomInt(data.wheight / rng.randomInt(280,180), -data.wheight / rng.randomInt(280,180))
	
	for _,p in ipairs(Player.get()) do
	    if colliders.collide(p, colliders.Box(v.x,v.y-data.wheight,v.width,v.height+data.wheight)) then
		    p.speedY=p.speedY-1
			if p.speedY < -6 then p.speedY = -6 end;
		end
	end
	
	for _,p in ipairs(NPC.get(npc_list)) do
	    if colliders.collide(p, colliders.Box(v.x,v.y-data.wheight,v.width,v.height+data.wheight)) then
		    p.speedY=p.speedY-1
			if p.speedY < -6 then p.speedY = -6 end;
			if p.speedX < 0 or p.speedX > 0 then p.speedX = -2 * p.direction end;
		end
	end
	
	for _,p in ipairs(NPC.get(hurt_list)) do
	    if colliders.collide(p, colliders.Box(v.x,v.y,v.width,v.height)) then
		    Animation.spawn(63, v.x + v.width/2, v.y + v.height/2)
            v:kill()
		end
	end	

	for _,p in ipairs(NPC.get(coin_list)) do
	    if colliders.collide(p, colliders.Box(v.x,v.y-data.wheight,v.width,v.height+data.wheight)) then
		    if p.ai1 == 1 then
		        p.speedY=p.speedY-1
			    if p.speedY < -6 then p.speedY = -6 end;
			    if p.speedX < 0 or p.speedX > 0 then p.speedX = -2 * p.direction end;
			end
		end
	end	
end

return npc