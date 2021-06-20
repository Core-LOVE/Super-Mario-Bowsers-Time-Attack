local npcManager = require("npcManager");
local rng = require("rng");

local pokeySMW = {};
local npcID = NPC_ID;

npcManager.setNpcSettings ({
    id = npcID,
    gfxheight = 32,
    gfxwidth = 32,
    width = 30,
    height = 30,
    frames = 1,
    framestyle = 1,
	jumphurt = 1,
    nofireball = 1,
    nogravity = true,
    noblockcollision = true,
	noyoshi = 0,
	npcblocktop = 1,
    score = 2,
	spinjumpsafe = true,
    pokeybody = 751,
    pokeyhead = 752,
    notcointransformable = true
});
npcManager.registerDefines(npcID, {NPC.HITTABLE});

npcManager.registerHarmTypes(npcID, 
	{HARM_TYPE_FROMBELOW, HARM_TYPE_HELD, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_LAVA, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD}, 
	{
	    [HARM_TYPE_HELD]=npcID,
	    [HARM_TYPE_PROJECTILE_USED]=npcID,
	    [HARM_TYPE_NPC]=npcID,
	    [HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
});

function pokeySMW.onInitAPI()
	npcManager.registerEvent(npcID, pokeySMW, "onTickEndNPC");
    registerEvent(pokeySMW, "onNPCHarm");
end;

function pokeySMW.onTickEndNPC(v)
    if Defines.levelFreeze then return; end;
	
	-- Reference to current instance of pokey
    local data = v.data._basegame;
	
	-- Initialize custom data
    if data.collider == nil then
        data.collider = Colliders.Box(0,0,v.width - 4,1);
        data.x = v.x;
        --data.collider:Debug(true);
        data.adjacentBelow = nil
        data.adjacentAbove = nil
    end;

    if data.timer == nil then
        data.timer = rng.random(0,4)
    end

    local cfg = NPC.config[v.id]

    if data.x == nil or
        data.adjacentBelow == nil or
        (data.adjacentBelow and ((not data.adjacentBelow.isValid) or data.adjacentBelow:mem(0x12A, FIELD_WORD) <= 0 or data.adjacentBelow:mem(0x12C, FIELD_WORD) > 0 or data.adjacentBelow:mem(0x138, FIELD_WORD) > 0)) then
        v.id = cfg.pokeybody
        return
    end
    local lastDataX = data.x
    data.x = data.adjacentBelow.data._basegame.x
    data.timer = data.timer + 0.1
    --Movement speed
    v.speedY = (data.adjacentBelow.y - v.height) - v.y
    v.speedX = (data.x + math.sin(data.timer + 0.1) * 2) - (lastDataX + math.sin(data.timer) * 2);
    v.animationFrame = math.sign(data.x - lastDataX) * 0.5 * cfg.frames + 0.5 * cfg.frames
    if data.adjacentAbove then
        if data.adjacentAbove.isValid then
            v.animationFrame = 2 * cfg.frames; -- Use faceless texture
        else
            data.adjacentAbove = nil
        end
    end
end;

function pokeySMW.onNPCHarm(eventObj, v, killReason, culprit) 
	-- Ignore if wrong NPC or valid kill method
    if v.id ~= npcID then return; end;

    if killReason == HARM_TYPE_SPINJUMP then
        eventObj.cancelled = true
        return
    end

    local data = (v).data._basegame

    if data.adjacentAbove and data.adjacentAbove.isValid then
        data.adjacentAbove.data._basegame.adjacentBelow = nil
    end
end;

return pokeySMW;