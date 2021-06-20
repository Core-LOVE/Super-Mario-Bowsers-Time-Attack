local smwfuzzy = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local config = {
	id = npcID, 
	gfxoffsety = 16, 
	width = 32, 
    height = 32,
    gfxwidth = 64,
    gfxheight = 64,
    frames = 4,
    framespeed = 12,
    framestyle = 0,
    speed = 1,
    noiceball = true,
    nofireball = true,
    noyoshi = true,
	noblockcollision = true,
    jumphurt = true,
    spinjumpSafe = true,
    nogravity = true,

    waittime = 0
}

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_LAVA,
	}, 
	{
		[HARM_TYPE_NPC]=802,
		[HARM_TYPE_PROJECTILE_USED]=802,
		[HARM_TYPE_HELD]=802,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

npcManager.setNpcSettings(config)

local urchinSpeed = 1

function smwfuzzy.onInitAPI()
    npcManager.registerEvent(npcID, smwfuzzy, "onTickEndNPC")

    urchinSpeed = NPC.config[npcID].speed
    NPC.config[npcID].speed = 1
end

local redirector_ids = {
    191, 192, 193, 194, 195, 196, 197, 198, 199, 221
}

local redirectior_map = table.map(redirector_ids)

local function getSpeed(x,y)
    local v = vector(x,y):normalize() * urchinSpeed
    return v.x, v.y
end

local overlapEvents = {
    [191] = function(v)
        v.speedX, v.speedY = getSpeed(0,-1)
    end,
    [192] = function(v)
        v.speedX, v.speedY = getSpeed(0,1)
    end,
    [193] = function(v)
        v.speedX, v.speedY = getSpeed(-1, 0)
    end,
    [194] = function(v)
        v.speedX, v.speedY = getSpeed(1, 0)
    end,
    [195] = function(v)
        v.speedX, v.speedY = getSpeed(-1, -1)
    end,
    [196] = function(v)
        v.speedX, v.speedY = getSpeed(1, -1)
    end,
    [197] = function(v)
        v.speedX, v.speedY = getSpeed(1, 1)
    end,
    [198] = function(v)
        v.speedX, v.speedY = getSpeed(-1, 1)
    end,
    [199] = function(v)
        v.speedX, v.speedY = getSpeed(0,0)
    end,
    [221] = function(v)
        v.speedX, v.speedY = getSpeed(-v.data.last.x,-v.data.last.y)
    end
}

local OVERLAP_NONE = 0
local OVERLAP_NEW = 1

local function overlapCondition(v, terminus)
    local cx, cy, dx, dy = v.x + 0.5 * v.width, v.y + 0.5 * v.height, terminus.x + 0.5 * terminus.width, terminus.y + 0.5 * terminus.height

    local consider =  math.abs(cx - dx) < 8 and math.abs(cy - dy) < 8

    if not consider then return false end

    if v.speedX ~= 0 and v.speedY ~= 0 then
        return ((v.speedX > 0 and cx > dx) or (v.speedX < 0 and cx < dx)) or ((v.speedY > 0 and cy > dy) or (v.speedY < 0 and cy < dy))
    elseif v.speedX ~= 0 then
        return (v.speedX > 0 and cx > dx) or (v.speedX < 0 and cx < dx)
    elseif v.speedY ~= 0 then
        return (v.speedY > 0 and cy > dy) or (v.speedY < 0 and cy < dy)
    else
        return true
    end
end

function smwfuzzy.onTickEndNPC(v)
    if Defines.levelFreeze then return end

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        v.data.overlapping = nil
        return
    end

    if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
        v.data.overlapping = nil
        return
    end

    if v.data.overlapping == nil then
        v.data.overlapping = OVERLAP_NONE
        v.data.timer = nil
        v.data.overlappingID = nil
        v.data._settings.xdir = v.data._settings.xdir or 1
        v.data._settings.ydir = v.data._settings.ydir or 1

        v.data.last = vector(0,0)

        v.speedX, v.speedY = getSpeed(v.data._settings.xdir - 1, v.data._settings.ydir - 1)
    end

    if v.data.timer then
        v.speedX = 0
        v.speedY = 0
        v.data.timer = v.data.timer + 1
        local cfg = NPC.config[v.id]
        if v.data.timer >= cfg.waittime then
            if v.data.overlapping == OVERLAP_NEW then
                v.data.overlapping = OVERLAP_NONE
                overlapEvents[v.data.overlappingID](v)
            end
            v.data.timer = nil
        end
    else
        local bgos = BGO.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)
        local overlappingTerminus = nil
        if v.data.overlappingID then
            overlapEvents[v.data.overlappingID](v)
        else
            v.speedX, v.speedY = getSpeed(v.data._settings.xdir - 1, v.data._settings.ydir - 1)
        end
    
        for k,t in ipairs(bgos) do
            if redirectior_map[t.id] and t.id ~= v.data.overlappingID then
                if overlappingTerminus == nil or overlapCondition(t, overlappingTerminus, v.speedX, v.speedY) then
                    v.data.overlapping = OVERLAP_NEW
                    overlappingTerminus = t
                    break
                end
            end
        end
        if overlappingTerminus then
            if v.data.overlapping == OVERLAP_NEW then
                if overlapCondition(v, overlappingTerminus, v.speedX, v.speedY) then
                    v.data.timer = 0
                    v.data.overlappingID = overlappingTerminus.id
                    v.data.last = vector(v.speedX, v.speedY)
                end
            end
        else
            v.data.overlapping = OVERLAP_NONE
        end
    end
end

return smwfuzzy