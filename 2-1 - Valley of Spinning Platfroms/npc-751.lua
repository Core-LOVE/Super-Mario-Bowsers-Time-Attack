local npcManager = require("npcManager");
local rng = require("rng");

local pokeySMW = {};
local npcID = NPC_ID;
local COOLDOWN_BASE = 64 * 3; -- Cooldown average, default 3 seconds
local timer; -- Static pokey stalking RNG timer to maintain synchronicity among all pokey body parts
local doResetTimer = false; -- Whether to regenerate the pokey stalking timer

npcManager.setNpcSettings ({
    id = npcID,
    gfxheight = 32,
    gfxwidth = 32,
    width = 30,
    height = 32,
    frames = 1,
    framestyle = 1,
	jumphurt = 1,
    nofireball = 1,
	noyoshi = 0,
	npcblocktop = 1,
    score = 2,
    spinjumpsafe = true,
    walkspeed = 1,
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

local function cooldown()
	-- Cooldown variance (25%) and RNG
	return rng.randomInt(COOLDOWN_BASE * .75, COOLDOWN_BASE * 1.25);
end;

function pokeySMW.onInitAPI()
	npcManager.registerEvent(npcID, pokeySMW, "onTickEndNPC");
    registerEvent(pokeySMW, "onNPCHarm");
	registerEvent(pokeySMW, "onTick");
	timer = cooldown();
end;

function pokeySMW.onTickEndNPC(v)
    if Defines.levelFreeze then return; end;

	-- Reference to current instance of pokey
    local data = v.data._basegame;

    if v:mem(0x12A,FIELD_WORD) <= 0 or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
        data.adjacentBelow = nil
        data.adjacentAbove = nil
        return
    end
	
	
	-- Initialize custom data
    if data.collider == nil then
        data.collider = Colliders.Box(0,0,v.width - 4,1);
        data.x = v.x;
        --data.collider:Debug(true);
        data.adjacentBelow = nil
        data.adjacentAbove = nil
    end;
    
    data.collider.x = v.x + 2;
    data.collider.y = v.y + v.height;
    
    -- Ground unit: change direction to "Chase" mario every 5 seconds
    local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
	if timer <= 0 then
		if p.x < v.x + 0.5 * v.width then v.direction = -1; end;
		if p.x > v.x + 0.5 * v.width then v.direction = 1; end;
		doResetTimer = true;
	end;
    
    local cfg = NPC.config[v.id]
	
	--Movement speed
    v.speedX = 0.25 * cfg.walkspeed * v.direction;
    data.x = v.x

    if data.adjacentAbove then
        if data.adjacentAbove.isValid then
            v.animationFrame = 2 * cfg.frames; -- Use faceless texture
        else
            data.adjacentAbove = nil
        end
    end
	
	-- Determine stacked units and remove face
    for k,w in ipairs(Colliders.getColliding{
        a=data.collider,
        btype=Colliders.NPC,
        b={cfg.pokeybody, cfg.pokeyhead},
        filter= function(other)
            if other ~= v and not other.isHidden then
                return true;
            end;
            return false;
        end;}) do
        
        data.x = w.x;
        data.adjacentBelow = w
        w.data._basegame.adjacentAbove = v
        v.id = NPC.config[v.id].pokeyhead
        data.timer = rng.random(0,4)
        break
    end;
end;

function pokeySMW.onNPCHarm(eventObj, v, killReason, culprit) 
	-- Ignore if wrong NPC or valid kill method
    if v.id ~= npcID then return; end;

    if killReason == HARM_TYPE_SPINJUMP then
        eventObj.cancelled = true
        Colliders.bounceResponse(culprit)
        return
    end
    local data = (v).data._basegame
    if data.adjacentAbove and data.adjacentAbove.isValid then
        data.adjacentAbove.data._basegame.adjacentBelow = nil
    end
end;

function pokeySMW.onTick()
	if Defines.levelFreeze then return; end;
	-- Track pokey stalking timer
	timer = timer - 1;
	if doResetTimer then
		timer = cooldown();
		doResetTimer = false;
	end;
end;

return pokeySMW;