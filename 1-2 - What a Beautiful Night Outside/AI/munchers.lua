local munchers = {}
local npcManager = require("npcManager")

local muncherIDs = {}

function munchers.register(id)
    npcManager.registerEvent(id, munchers, "onTickEndNPC")
    muncherIDs[id] = true
end

local generousHitbox = Colliders.Box(0,0,0,0)

function munchers.onInitAPI()
    registerEvent(munchers, "onTickEnd")
    registerEvent(munchers, "onNPCHarm")
end

local powEffect

function munchers.onNPCHarm(e, n, r, c)
    if n.id == 241 and r ~= 9 and r ~= HARM_TYPE_LAVA then
        powEffect = true
        return
    end

    if not muncherIDs[n.id] then return end
    if r ~= HARM_TYPE_FROMBELOW then return end
    if c and not powEffect then
        e.cancelled = true
    end

    if e.cancelled and n.speedY >= 0 then
        n.speedY = -4
        SFX.play(2)
    end
end

function munchers.onTickEnd()
    generousHitbox.x = player.x + player.speedX
    generousHitbox.y = player.y + 8 + player.speedY
    generousHitbox.width = player.width
    generousHitbox.height = player.height - 10
    powEffect = false
end

local function liftOthers(v)
	for k,w in ipairs(NPC.getIntersecting(v.x, v.y - 2, v.x + v.width, v.y)) do
        if w ~= v then
            local cfg = NPC.config[w.id]
            if (NPC.HITTABLE_MAP[v.id] or NPC.POWERUP_MAP[v.id]) and not (cfg.nogravity or cfg.noblockcollision) then
                w.speedY = v.speedY
                liftOthers(w)
            end
		end
	end
end

function munchers.onTickEndNPC(v)
    if Defines.levelFreeze then return end

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        return
    end

    if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
        return
    end

    if v.data.prevY == nil then
        v.data.prevY = v.y
    end
    if player.mount == 0 and Colliders.speedCollide(generousHitbox, v) then
        player:harm()
    end
    if v.speedY <= 0 then
        liftOthers(v)
    end
    if v.data.prevY ~= v.y then
        for _, w in ipairs(NPC.getIntersecting(v.x + 2, v.y + v.speedY, v.x + v.width - 2, v.y + v.height + v.speedY + 2)) do
            if NPC.HITTABLE_MAP[w.id] and ((v.data.prevY > v.y and w.y < v.y) or (v.data.prevY < v.y and w.y > v.y)) then
                if math.abs(v.speedY) > math.abs(w.speedY) then
                    w:harm(4)
                end
            end
        end
    end
    --[[
    for _, w in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
        if (w.id == 155 or w.id == 156 or w.id == 157) and w ~= v.__ref then
            if not (w.y > v.y + v.height) then
                if not (w.y + w.height < v.y) then
                    if not (w.x > v.x + v.width) then
                        if not (w.x + w.width < v.x) then
                            w.y = v.y - w.height
                        end
                    end
                end
            end
        end
    end
    ]]
    v.data.prevY = v.y
    v:mem(0x12A, FIELD_WORD, 500)
end

return munchers