--[[

    rooms.lua (v1.2)
    by MrDoubleA


    Thanks to Enjl#6208 on Discord for a bit of help on making respawning NPCs actually work
    Thanks to Rednaxela#0380 on Discord for providing a handy function for getting the custom music path and help on resetting events
    Thanks to madeline#4345 on Discord, Chipss#9594 on Discord and Wiimeiser on the SMBX Forums for reporting bugs


    TO DO:
    - Fix oddly spawning reserve items?

    - DONE | Add support for timer.lua
    - DONE | Add optional automatic checkpoints on loading a new section
    - DONE | Add optional resetting of star coins
    - DONE | Fix cross-section respawning
    - DONE | Fix the "collectibles respawn" option (needs to be re-added since the quick respawn reset got overhauled)
    - DONE | Better support for starman and mega mushroom
    - DONE | Add auto-playing music through lua
    - DONE | Find why p-switches break blocks (and fix it maybe)
    - DONE | Find better way to make snake blocks hitting terminuses work? (currently has to overwrite the snake block's drawing function which is ehh)

]]

-- Load a bunch of necessary libraries
local configFileReader = require("configfilereader") -- (used for parsing music.ini files)
local checkpoints      = require("checkpoints")

local switch           = require("blocks/ai/synced")
local megashroom       = require("npcs/ai/megashroom")
local starman          = require("npcs/ai/starman")

local rooms = {}

-- Declare constants
rooms.TRANSITION_TYPE_NONE     = 0
rooms.TRANSITION_TYPE_CONSTANT = 1
rooms.TRANSITION_TYPE_SMOOTH   = 2

rooms.RESPAWN_EFFECT_FADE          = 0
rooms.RESPAWN_EFFECT_MOSAIC        = 1
rooms.RESPAWN_EFFECT_DIAMOND       = 2
rooms.RESPAWN_EFFECT_DIAMOND_SWEEP = 3

rooms.CAMERA_STATE_NORMAL     = 0
rooms.CAMERA_STATE_TRANSITION = 1



rooms.rooms = {}

rooms.currentRoomIndex = nil
rooms.enteredRoomPos = nil
rooms.spawnPosition = nil

rooms.hasSavedClasses = false

rooms.cameraInfo = {
    state = rooms.CAMERA_STATE_NORMAL,
    startPos = nil,transitionPos = nil,
}

rooms.respawnTimer = nil
rooms.resetTimer = 0

-- Map of NPC IDs that aren't affected by the reset. Should contain any checkpoints.
rooms.npcRespawnExceptions = {[192] = true,[400] = true,[430] = true}

local currentlyPlayingMusic
local vanillaMusicPaths = {}
local possibleMusicIniPaths = {getSMBXPath(),Misc.episodePath(),Misc.levelPath()}

local colBox = Colliders.Box(0,0,0,0)

-- Memory offsets because me no like big number (:
local PSWITCH_TIMER_ADDR   = 0x00B2C62C
local STOPWATCH_TIMER_ADDR = 0x00B2C62E

local GM_SIZABLE_LIST_ADDR = mem(0xB2BED8, FIELD_DWORD)
local GM_SIZABLE_COUNT_ADDR = 0xB2BEE4

local function tableMultiInsert(tbl,tbl2)
    for _,v in ipairs(tbl2) do
        table.insert(tbl,v)
    end
    return tbl
end

local function boundCamToRoom(room)
    return math.clamp(camera.x,room.collider.x,room.collider.x+room.collider.width-camera.width),math.clamp(camera.y,room.collider.y,room.collider.y+room.collider.height-camera.height)
end

local function getMusicPathForSection(section) -- thanks to Rednaxela#0380 on Discord for providing this handy function!
    local customMusicPathsTbl = mem(0xB257B8, FIELD_DWORD)
    return mem(customMusicPathsTbl + section*4, FIELD_STRING)
end

local NEW_EVENT = mem(0xB2D6E8,FIELD_DWORD)
local NEW_EVENT_DELAY = mem(0xB2D704,FIELD_DWORD)
local NEW_EVENT_NUM = 0xB2D710

local EVENTS_ADDR = mem(0x00B2C6CC,FIELD_DWORD)
local EVENTS_STRUCT_SIZE = 0x588

local MAX_EVENTS = 255

local function resetEvents()
    -- Reset event timers (huge thanks to Rednaxela for helping on this!)
    for i=0,mem(NEW_EVENT_NUM,FIELD_WORD)-1 do
        mem(NEW_EVENT_DELAY+(i*0x02),FIELD_WORD,0)
    end

    mem(NEW_EVENT_NUM,FIELD_WORD,0)

    -- Trigger autostart events
    for idx=0,MAX_EVENTS-1 do
        local name = mem(EVENTS_ADDR+(idx*EVENTS_STRUCT_SIZE)+0x04,FIELD_STRING)

        if #name == 0 then break end

        local isAutoStart = mem(EVENTS_ADDR+(idx*EVENTS_STRUCT_SIZE)+0x586,FIELD_BOOL)

        if name == "Level - Start" or isAutoStart then -- If it set to autostart or is the level start event, trigger
            triggerEvent(name)
        end
    end
end

local function blockSpawnWithSizeableOrdering(...)
    local v = Block.spawn(...)

    if Block.config[v.id] and Block.config[v.id].sizeable then -- If this block is a sizeable
        -- Block.spawn puts sizeables at the very top of the block array, so we need some additional sorting
        local sizeableCount = mem(GM_SIZABLE_COUNT_ADDR,FIELD_WORD)

        for idx=0,sizeableCount-2 do -- Go through the sizeable array
            local w = Block(mem(GM_SIZABLE_LIST_ADDR+(idx*0x02),FIELD_WORD)) -- Get the block itself

            if w and w.isValid and w.y > v.y then -- If this block is higher than the spawned block
                for idx2=sizeableCount-1,idx+1,-1 do -- Move everything up one index
                    mem(GM_SIZABLE_LIST_ADDR+(idx2*0x02),FIELD_WORD,mem(GM_SIZABLE_LIST_ADDR+((idx2-1)*0x02),FIELD_WORD))
                end
                mem(GM_SIZABLE_LIST_ADDR+(idx*0x02),FIELD_WORD,v.idx) -- Insert this block into the sizeable array

                break
            end
        end
    end

    return v
end



local function updateSpawnPosition()
    rooms.spawnPosition = rooms.spawnPosition or {}

    rooms.spawnPosition.x = player.x+(player.width/2)
    rooms.spawnPosition.y = player.y+(player.height )
    rooms.spawnPosition.section = player.section

    rooms.spawnPosition.direction = player.direction

    rooms.spawnPosition.checkpoint = nil
end

-- copy of configFileReader.parseWithHeaders from configFileReader by Horikawa Otane, but outputs the header name as "_header" rather than "name".
local function parseWithHeaders(path, defaultheaders, enums, allowranges, keephex)
	local data = {};
	local headers = {};
	local index = nil;
	local headerless = {};
	for v in io.lines(path) do
		if(v ~= nil) then
			local header = string.match(v, "^%s*%[(.+)%]%s*$");
			if(header) then
				if(data[header] == nil and defaultheaders[header] == nil) then
					data[header] = {};
					table.insert(headers, header);
				end
				if(defaultheaders[header]) then
					index = nil;
				else
					index = header;
				end
			elseif(index ~= nil and data[index] ~= nil) then
				table.insert(data[index], v);
			else
				table.insert(headerless, v);
			end
		end
	end
	local layers = {}
	for _,h in ipairs(headers) do
		local l = configFileReader.dataParse(data[h], enums, allowranges, keephex);
		l._header = l._header or h;
		table.insert(layers, l);
	end
	
	return layers, configFileReader.dataParse(headerless, enums, allowranges, keephex);
end

local buffer = Graphics.CaptureBuffer(800,600)

local mosaicShader = Shader()
mosaicShader:compileFromFile(nil,Misc.multiResolveFile("fuzzy_pixel.frag","shaders/npc/fuzzy_pixel.frag"))

function rooms.mosaicEffect(level,priority)
    buffer:captureAt(priority or 0)

    Graphics.drawScreen{
        texture = buffer,
        shader = mosaicShader,
        priority = priority or 0,
        uniforms = {pxSize = {camera.width/level,camera.height/level}}
    }
end

-- rooms.warpToRoom(room,respawnPointIndex)
-- OR
-- rooms.warpToRoom(room,respawnPointX,respawnPointY)

function rooms.warpToRoom(room,x,y)
    if type(room) == "number" then
        room = rooms.rooms[room]
    end
    if not room then error("Invalid room to warp to.") end

    local foundCount = 0
    local c

    for _,v in ipairs(BGO.getIntersecting(room.collider.x,room.collider.y,room.collider.x+room.collider.width,room.collider.y+room.collider.height)) do
        if rooms.respawnBGODirections[v.id] then
            if not y then
                foundCount = foundCount + 1

                if foundCount == x then
                    c = v
                    break
                end
            elseif not c or (math.abs(x-(v.x+(v.width/2)))+math.abs(y-(v.y+(v.width/2)))) < (math.abs(x-(c.x+(c.width/2)))+math.abs(y-(c.y+(c.width/2)))) then
                c = v
            end
        end
    end

    if c then
        player.x = (c.x+(c.width/2))-(player.width/2)
        player.y = (c.y+c.height-player.height)

        player.direction = rooms.respawnBGODirections[c.id]
        player.section = room.section

        return
    end
end


--[[

    So, in case you want to make your own thing to go into this table for whatever reason, here's a little bit of documentation on what each field does.

    name          (string)    How it's internally referred as in the "savedClasses" table, and how you refer to it when using rooms.restoreClass.
    get           (function)  A function which should return a table of all the objects in the class, like, say, NPC.get.
    
    saveFields    (table)     List of fields to be saved and restored. Can either be a string (with the field's name) or a table (of a memory offset and memory type).
    extraSave     (function)  A function which is run after saving all fields. The first argument is the object and the second argument is the table of fields already saved.
    extraRestore  (function)  A function which is run after restoring all fields. The first argument is the object and the second argument is the table of fields already saved.
    
    remove        (function)  A function which should remove the object in the first argument.
    create        (function)  A function which should create an object based on the fields in the first argument.

]]
rooms.classesToSave = {
    -- Classes that tend to shift around a lot (so therefore deletes everything and spawns new ones when resetting)
    {
        name = "Block",get = Block.get,getByIndex = Block,
        saveFields = {
            "layerName","contentID","isHidden","slippery","width","height","id","speedX","speedY","x","y",{0x5A,FIELD_BOOL},{0x5C,FIELD_BOOL},
            {0x0C,FIELD_STRING},{0x10,FIELD_STRING},{0x14,FIELD_STRING}, -- Event names
        },
        extraSave    = (function(v,fields) fields.data = table.deepclone(v.data) end),
        extraRestore = (function(v,fields) v.data = table.deepclone(fields.data) end),

        remove = (function(v) v:delete() end),
        create = (function(fields) return blockSpawnWithSizeableOrdering(fields.id,fields.x,fields.y) end),
    },
    {
        name = "NPC",get = NPC.get,getByIndex = NPC,
        saveFields = {
            "x","y","spawnX","spawnY","width","height","spawnWidth","spawnHeight","speedX","speedY","spawnSpeedX","spawnSpeedY",
            "direction","spawnDirection","layerName","id","spawnId","ai1","ai2","ai3","ai4","ai5","spawnAi1","spawnAi2","isHidden","section",
            "msg","attachedLayerName","activateEventName","deathEventName","noMoreObjInLayer","talkEventName","legacyBoss","friendly","dontMove",
            "isGenerator","generatorInterval","generatorTimer","generatorDirection","generatorType", -- Generator related stuff
        },
        extraSave    = (function(v,fields) fields.extraSettings = v.data._settings end),
        extraRestore = (function(v,fields) v.data._settings = fields.extraSettings end),
        
        remove = (function(v)
            if rooms.npcRespawnExceptions[v.id] or (NPC.COLLECTIBLE_MAP[v.id] and not rooms.collectiblesRespawn) then return end -- Don't do this for any exceptions

            v.isGenerator,v.deathEventName,v.animationFrame = false,"",-1 -- Thanks for coming up with this solution, Rednaxela (:
            v:kill(HARM_TYPE_OFFSCREEN)
        end),
        create = (function(fields)
            if rooms.npcRespawnExceptions[fields.id] or (NPC.COLLECTIBLE_MAP[fields.id] and not rooms.collectiblesRespawn) then return end -- Don't do this for any exceptions
            
            local v = NPC.spawn(fields.id,fields.spawnX,fields.spawnY,fields.section,fields.spawnId > 0,false)
            v.despawnTimer = 1 -- Initially spawned NPCs also seem to do this?

            return v
        end),
    },

    -- Classes that tend to be static (so therefore the old properties are just put back when resetting)
    {
        name = "BGO",get = BGO.get,getByIndex = BGO,
        saveFields = {"layerName","isHidden","id","x","y","width","height","speedX","speedY"},
    },
    {
        name = "Liquid",get = Liquid.get,getByIndex = Liquid,
        saveFields = {"layerName","isHidden","isQuicksand","x","y","width","height","speedX","speedY"},
    },
    {
        name = "Warp",get = Warp.get,getByIndex = Warp,
        saveFields = {
            "layerName","isHidden","locked","allowItems","noYoshi","starsRequired",
            "warpType","levelFilename","warpNumber","toOtherLevel","fromOtherLevel","worldMapX","worldMapY",
            "entranceX","entranceY","entranceWidth","entranceHeight","entranceSpeedX","entranceSpeedY","entranceDirection",
            "exitX","exitY","exitWidth","exitHeight","entranceSpeedX","entranceSpeedY","exitDirection",
        },
    },
    {
        name = "Layer",get = Layer.get,getByIndex = Layer,
        saveFields = {"name","isHidden","speedX","speedY"},
    },
}

rooms.savedClasses = {}


function rooms.saveClass(class)
    -- If no class is provided, save all classes
    if class == nil then
        for _,c in ipairs(rooms.classesToSave) do
            rooms.saveClass(c.name)
        end
        return
    end

    -- Convert name to the actual class
    if type(class) ~= "table" then
        for _,c in ipairs(rooms.classesToSave) do
            if c.name == class then
                class = c
                break
            end
        end
    end

    -- Create a table for this class
    rooms.savedClasses[class.name] = {}

    -- Go through all objects in this class
    for _,v in ipairs(class.get()) do
        local fields = {}

        if class.saveFields then
            -- Save fields, if they exist
            for _,w in ipairs(class.saveFields) do
                if type(w) == "table" then -- For memory offsets
                    fields[w[1]] = v:mem(w[1],w[2])
                else
                    fields[w] = v[w]
                end
            end
        end

        if class.extraSave then
            class.extraSave(v,fields)
        end

        table.insert(rooms.savedClasses[class.name],fields)
    end

    rooms.hasSavedClasses = true
end

function rooms.restoreClass(class)
    -- If no class is provided, restore all classes
    if class == nil then
        for _,c in ipairs(rooms.classesToSave) do
            rooms.restoreClass(c.name)
        end
        return
    end

    if not rooms.savedClasses[class] then return end -- Don't attempt to restore it if it hasn't been saved yet

    -- Convert name to the actual class
    if type(class) ~= "table" then
        for _,c in ipairs(rooms.classesToSave) do
            if c.name == class then
                class = c
                break
            end
        end
    end

    -- Remove all
    if class.remove and class.get then
        -- This needs to be a backwards for loop due to the weird way that blocks are spawned into free slots
        local list = class.get()

        for k=#list,1,-1 do
            class.remove(list[k])
        end
    end

    -- Restore all
    if class.create and class.saveFields or not class.remove and not class.create and class.getByIndex then
        for index,fields in ipairs(rooms.savedClasses[class.name]) do
            local v
            if class.create then
                v = class.create(fields)
            elseif class.getByIndex then
                v = class.getByIndex(index-1)
            end

            if v and (v.isValid == nil or v.isValid) then
                for _,w in ipairs(class.saveFields) do
                    if type(w) == "table" then -- For memory offsets
                        v:mem(w[1],w[2],fields[w[1]])
                    else
                        v[w] = fields[w]
                    end
                end
                if class.extraRestore then
                    class.extraRestore(v,fields)
                end
            end
        end
    end
end

function rooms.reset(fromRespawn)
    -- Reset p-switch
    if rooms.blocksReset and mem(PSWITCH_TIMER_ADDR,FIELD_DWORD) > 0 then
        Misc.doPSwitch(false)
    elseif rooms.blocksReset then
        Misc.doPSwitchRaw(false)
    end

    -- Reset stopwatch
    mem(STOPWATCH_TIMER_ADDR,FIELD_WORD,0)
    Defines.levelFreeze = false

    -- Reset timed events and re-trigger autostart ones
    resetEvents()

    -- Reset the classes (may be worth removing the blocksReset option?)
    rooms.restoreClass("NPC")
    rooms.restoreClass("BGO")

    rooms.restoreClass("Liquid")
    rooms.restoreClass("Warp")

    rooms.restoreClass("Layer")

    if rooms.blocksReset then
        rooms.restoreClass("Block")
    end

    -- Remove effects
    for _,v in ipairs(Effect.get()) do
        v.x,v.y,v.speedX,v.speedY,v.timer = 0,0,0,0,0

        if v.kill then
            v:kill()
        end
    end

    if switch.state then switch.toggle() end -- Reset synced switches

    if fromRespawn then -- Things which shouldn't reset on room transition
        -- Reset star coins
        if rooms.starCoinsReset then
            local starCoinData = SaveData._basegame.starcoin[Level.filename()] or {}

            for k,v in ipairs(starCoinData) do
                if v == 3 then
                    starCoinData[k] = 0
                end
            end
        end

        -- Reset timer
        if Timer and Level.settings.timer and Level.settings.timer.enable then
            Timer.activate(Level.settings.timer.time)
        end

        -- Reset mega mushroom and starman
        megashroom.StopMega(w,false)
        starman.stop(w)
    end

    EventManager.callEvent("onReset",not not fromRespawn)
end

function rooms.onInitAPI()
    registerEvent(rooms,"onTick")
    registerEvent(rooms,"onStart")
    registerEvent(rooms,"onCameraUpdate")

    registerEvent(rooms,"onDraw")
    registerEvent(rooms,"onInputUpdate")

    registerEvent(rooms,"onCheckpoint")
end

function rooms.onCheckpoint()
    if rooms.spawnPosition then
        rooms.spawnPosition.checkpoint = checkpoints.getActive()
    end
end

function rooms.onStart()
    -- Convert quicksand to rooms
    for _,v in ipairs(Liquid.get()) do
        if v.layerName == (rooms.roomLayerName or "Rooms") then
            local w = {collider = Colliders.Box(v.x,v.y,v.width,v.height),section = nil}

            if w.collider.height == 608 then
                -- Make it smaller to fit the size of the screen in case it's 608 pixels tall.
                w.collider.y = w.collider.y + 8
                w.collider.height = 600
            end

            if w.collider:collide(player) then
                rooms.currentRoomIndex = #rooms.rooms+1
                rooms.enteredRoomPos = {player.x+(player.width/2),player.y+(player.height/2)}
            end

            -- Find section of room
            for _,x in ipairs(Section.get()) do
                local b = x.boundary
                colBox.x,colBox.y = b.left,b.top
                colBox.width,colBox.height = b.right-b.left,b.bottom-b.top

                if w.collider:collide(colBox) then
                    w.section = x.idx
                    break
                end
            end
            if not w.section then error("Could not find appropriate section for room.") end

            table.insert(rooms.rooms,w)
        end
    end

    -- Hide the rooms layer
    local l = Layer.get(rooms.roomLayerName or "Rooms")
    if l then
        l:hide(false)
    end

    if rooms.quickRespawn then
        -- If quick respawn is active, replace death sound effect
        if not rooms.deathSoundEffect then
            Audio.sounds[8].muted = true
        elseif type(rooms.deathSoundEffect) == "number" then
            Audio.sounds[8].sfx = Audio.sounds[rooms.deathSoundEffect].sfx
        elseif type(rooms.deathSoundEffect) == "string" then
            Audio.sounds[8].sfx = SFX.open(Misc.resolveFile(rooms.deathSoundEffect))
        else
            Audio.sounds[8].sfx = rooms.deathSoundEffect
        end

        if not rooms.dontPlayMusicThroughLua then
            Audio.SeizeStream(-1)
        end
    end

    -- Get music paths for vanilla music
    for k,v in ipairs(possibleMusicIniPaths) do
        local musicIniFile = io.open(v.. "\\music.ini","r") -- Get the music.ini file if it exists

        if musicIniFile then
            musicIniFile:close() -- We were only seeing if it exists, so we can close it straight away

            for _,w in ipairs(parseWithHeaders(v.. "\\music.ini",{})) do
                if w._header and w.file then
                    vanillaMusicPaths[w._header] = v.. "\\".. w.file
                end
            end
        end
    end
    

    updateSpawnPosition()
end

function rooms.onTick()
    -- Save classes (this is done after onStart so custom stuff has already been initiated)
    if not rooms.hasSavedClasses then
        rooms.saveClass()
    end

    local collided

    for k,v in ipairs(rooms.rooms) do
        if v.collider:collide(player) then
            if collided then
                collided = nil
                break
            else
                collided = k
            end
        end
    end

    if collided and collided ~= rooms.currentRoomIndex then
        if rooms.resetOnEnteringRoom then
            rooms.reset(false)
        end

        if rooms.transitionType ~= rooms.TRANSITION_TYPE_NONE and not rooms.respawnTimer and (not rooms.rooms[rooms.currentRoomIndex] or rooms.rooms[collided].section == rooms.rooms[rooms.currentRoomIndex].section) then
            rooms.cameraInfo.state = rooms.CAMERA_STATE_TRANSITION

            if rooms.rooms[rooms.currentRoomIndex] then
                rooms.cameraInfo.startPos = {boundCamToRoom(rooms.rooms[rooms.currentRoomIndex])}
                rooms.cameraInfo.transitionPos = {boundCamToRoom(rooms.rooms[rooms.currentRoomIndex])}
            else
                rooms.cameraInfo.startPos = {camera.x,camera.y}
                rooms.cameraInfo.transitionPos = {camera.x,camera.y}
            end

            if rooms.jumpUpOnTransition then
                colBox.x = rooms.rooms[collided].collider.x
                colBox.y = rooms.rooms[collided].collider.y+rooms.rooms[collided].collider.height-24
                colBox.width = rooms.rooms[collided].collider.width
                colBox.height = 24

                if colBox:collide(player) then
                    player.speedY = -10
                end
            end

            Misc.pause()
        end

        rooms.currentRoomIndex = collided
        rooms.enteredRoomPos = {player.x+(player.width/2),player.y+(player.height/2)}
    end

    if rooms.quickRespawn then
        if rooms.checkpointOnEnterSection and rooms.spawnPosition and rooms.spawnPosition.section ~= player.section and (player.forcedState == 0 and player.deathTimer == 0 and not player:mem(0x13C,FIELD_BOOL)) then
            updateSpawnPosition()
        end

        if player.deathTimer > 0 and not rooms.respawnTimer then
            if rooms.deathEarthquake > 0 then
                Defines.earthquake = rooms.deathEarthquake
            end

            rooms.respawnTimer = 0

            Level.winState(0)

            if rooms.pauseOnRespawn then
                Misc.pause()
            end
        end
    end
end

local finished = false

function rooms.onDraw()
    if rooms.quickRespawn and not rooms.dontPlayMusicThroughLua then
        local currentMusic
        
        if player.hasStarman or player.isMega then
            currentMusic = nil
        elseif mem(STOPWATCH_TIMER_ADDR,FIELD_WORD) > 0 then -- Stopwatch music
            currentMusic = vanillaMusicPaths["special-music-2"]
        elseif mem(PSWITCH_TIMER_ADDR,FIELD_WORD) > 0 then -- P-switch music
            currentMusic = vanillaMusicPaths["special-music-1"]
        elseif player.sectionObj.musicID == 24 then -- Custom music
            currentMusic = Misc.episodePath().. getMusicPathForSection(player.section)
        elseif player.sectionObj.musicID > 0 then -- Vanilla music
            currentMusic = vanillaMusicPaths["level-music-".. tostring(player.sectionObj.musicID)]
        else
            currentMusic = nil
        end

        if currentMusic ~= currentlyPlayingMusic or (Audio.MusicIsPlaying() == not currentMusic) then
            if currentMusic then
                Audio.MusicOpen(currentMusic)
                Audio.MusicPlay()
            else
                Audio.MusicStop()
            end

            currentlyPlayingMusic = currentMusic
        end

        if Level.winState() == 0 then
            if Audio.MusicIsPaused() then
                Audio.MusicResume()
                Audio.MusicVolume(0)
            end

            if Audio.MusicVolume() < 64 then
                Audio.MusicVolume(math.min(64,Audio.MusicVolume() + 1))
            end
        elseif not Audio.MusicIsPaused() then
            Audio.MusicPause()
        end
    end

    if rooms.respawnTimer then
        local canReset = false
        finished = false

        local out = (rooms.resetTimer-rooms.respawnBlankTime)

        if rooms.respawnEffect == rooms.RESPAWN_EFFECT_FADE or rooms.respawnEffect == rooms.RESPAWN_EFFECT_MOSAIC then
            local o,m

            if rooms.respawnEffect == rooms.RESPAWN_EFFECT_FADE then
                if out > 0 then
                    o = (1-(out/16))
                else
                    o = (rooms.respawnTimer/16)
                end
            elseif rooms.respawnEffect == rooms.RESPAWN_EFFECT_MOSAIC then
                if out > 0 then
                    o = (1-(out/32))
                    m = (48-(out*2))
                else
                    o = (rooms.respawnTimer/32)
                    m = (rooms.respawnTimer*1.75)
                end
            end

            if o and o > 0 then
                Graphics.drawBox{
                    x = 0,y = 0,width = camera.width,height = camera.height,
                    color = Color.black.. o,priority = 5,
                }
            end
            if m and m > 1 then
                rooms.mosaicEffect(m,-54)
            end

            if o >= 1 then
                canReset = true
            elseif o <= 0 and out > 0 then
                finished = true
            end
        elseif rooms.respawnEffect == rooms.RESPAWN_EFFECT_DIAMOND then
            local s

            if out > 0 then
                s = (math.max(camera.width,camera.height)-(out*24))
            else
                s = (rooms.respawnTimer*24)
            end

            if s and s > 0 then
                Graphics.glDraw{
                    vertexCoords = {
                        (camera.width/2)  ,(camera.height/2)-s,
                        (camera.width/2)+s,(camera.height/2)  ,
                        (camera.width/2)  ,(camera.height/2)+s,
                        (camera.width/2)-s,(camera.height/2)  ,
                        (camera.width/2)  ,(camera.height/2)-s,
                    },
                    color = Color.black,primitive = Graphics.GL_TRIANGLE_STRIP,priority = 5,
                }
            end

            if s >= math.max(camera.width,camera.height) then
                canReset = true
            elseif s <= 0 and out > 0 then
                finished = true
            end
        elseif rooms.respawnEffect == rooms.RESPAWN_EFFECT_DIAMOND_SWEEP then
            local width,height = 20,20

            local horCount = math.ceil(camera.width /width )
            local verCount = math.ceil(camera.height/height)

            local doneAll,renderedNone = true,true

            local vertexCoords = {}

            for x=0,horCount-1 do
                for y=0,verCount-1 do
                    local xPosition = (camera.width /2)-((horCount*width )/2)+(x*width )+(width /2)
                    local yPosition = (camera.height/2)-((verCount*height)/2)+(y*height)+(height/2)

                    local currentWidth,currentHeight
                    if out > 0 then
                        currentWidth  = math.max(0,(width *2)-(((out*48)-((x+y)*12))/horCount))
                        currentHeight = math.max(0,(height*2)-(((out*48)-((x+y)*12))/verCount))
                    else
                        currentWidth  = math.clamp((((rooms.respawnTimer*48)-((x+y)*12))/horCount),0,width *2)
                        currentHeight = math.clamp((((rooms.respawnTimer*48)-((x+y)*12))/verCount),0,height*2)
                    end

                    if currentWidth > 0 and currentHeight > 0 then
                        tableMultiInsert(vertexCoords,{
                            xPosition-(currentWidth/2),yPosition                  ,
                            xPosition                 ,yPosition-(currentHeight/2),
                            xPosition+(currentWidth/2),yPosition                  ,
                            xPosition-(currentWidth/2),yPosition                  ,
                            xPosition                 ,yPosition+(currentHeight/2),
                            xPosition+(currentWidth/2),yPosition                  ,
                        })

                        renderedNone = false
                    end

                    if currentWidth < width*2 or currentHeight < height*2 then
                        doneAll = false
                    end
                end
            end

            Graphics.glDraw{vertexCoords = vertexCoords,color = Color.black,priority = 5}

            if out > 0 and renderedNone then
                finished = true
            elseif doneAll then
                canReset = true
            end
        end

        rooms.respawnTimer = rooms.respawnTimer + 1

        if canReset or rooms.resetTimer > 0 then
            rooms.resetTimer = (rooms.resetTimer or 0) + 1
        end

        if rooms.resetTimer == math.floor(rooms.respawnBlankTime/2)-1 then
            EventManager.callEvent("onRespawnReset") -- (onRespawnReset is now "deprecated")
        elseif rooms.resetTimer == math.floor(rooms.respawnBlankTime/2) then
            -- Reset player
            if rooms.rooms[rooms.currentRoomIndex] and not rooms.neverUseRespawnBGOs then
                rooms.warpToRoom(rooms.currentRoomIndex,rooms.enteredRoomPos[1],rooms.enteredRoomPos[2])
            elseif rooms.spawnPosition then
                local cp = rooms.spawnPosition.checkpoint

                if cp then
                    player.x = ((cp.x   )-(player.width/2))
                    player.y = ((cp.y+32)-(player.height ))
                    player.section = cp.section

                    player.direction = rooms.spawnPosition.direction -- Checkpoint objects don't have direction fields
                else
                    player.x = (rooms.spawnPosition.x-(player.width/2))
                    player.y = (rooms.spawnPosition.y-(player.height ))
                    player.section = rooms.spawnPosition.section

                    player.direction = rooms.spawnPosition.direction
                end
            else
                error("Failed to find valid respawn point.")
            end

            player.speedX,player.speedY = 0,0
            player:mem(0x50,FIELD_BOOL,false)
            player:mem(0x140,FIELD_WORD,0)
            player:mem(0x11C,FIELD_WORD,0)

            player.deathTimer = 0
            player.forcedState = 0

            -- Reset everything else
            rooms.reset(true)
        end

        -- Stop the death timer from progressing further
        if player.deathTimer > 0 then
            player.deathTimer = 1
        end
    end
end

function rooms.onInputUpdate() -- Unpausing should be done from onInputUpdate, apparently, so here we are.
    if rooms.respawnTimer then
        if finished then
            finished = false
    
            player.deathTimer = 0
    
            rooms.respawnTimer = nil
            rooms.resetTimer = 0
    
            if rooms.pauseOnRespawn then
                Misc.unpause()
            end
        elseif rooms.resetTimer > 0 and rooms.resetTimer == math.floor(rooms.respawnBlankTime/2)-2 and rooms.pauseOnRespawn then
            Misc.unpause()
        elseif rooms.resetTimer > 0 and rooms.resetTimer == math.floor(rooms.respawnBlankTime/2)+1 and rooms.pauseOnRespawn then
            Misc.pause()
        end
    end
end

function rooms.onCameraUpdate()
    local currentRoom = rooms.rooms[rooms.currentRoomIndex]

    if currentRoom then
        if rooms.cameraInfo.state == rooms.CAMERA_STATE_NORMAL then
            camera.x,camera.y = boundCamToRoom(currentRoom)
        elseif rooms.cameraInfo.state == rooms.CAMERA_STATE_TRANSITION then
            local goal = {boundCamToRoom(currentRoom)}

            if rooms.transitionType == rooms.TRANSITION_TYPE_CONSTANT or rooms.transitionType == rooms.TRANSITION_TYPE_SMOOTH then
                for i=1,2 do
                    local speed
                    if rooms.transitionType == rooms.TRANSITION_TYPE_CONSTANT then
                        speed = ((goal[i]-rooms.cameraInfo.startPos[i])*rooms.transitionSpeeds[rooms.transitionType])
                    elseif rooms.transitionType == rooms.TRANSITION_TYPE_SMOOTH then
                        speed = ((goal[i]-rooms.cameraInfo.transitionPos[i])*rooms.transitionSpeeds[rooms.transitionType])
                    end

                    if rooms.cameraInfo.transitionPos[i] > goal[i] then
                        rooms.cameraInfo.transitionPos[i] = math.max(goal[i],rooms.cameraInfo.transitionPos[i]+speed)
                    elseif rooms.cameraInfo.transitionPos[i] < goal[i] then
                        rooms.cameraInfo.transitionPos[i] = math.min(goal[i],rooms.cameraInfo.transitionPos[i]+speed)
                    end
                end
            end

            camera.x,camera.y = rooms.cameraInfo.transitionPos[1],rooms.cameraInfo.transitionPos[2]

            if (math.abs(goal[1]-rooms.cameraInfo.transitionPos[1])+math.abs(goal[2]-rooms.cameraInfo.transitionPos[2])) < 2 then
                rooms.cameraInfo.state = rooms.CAMERA_STATE_NORMAL

                rooms.cameraInfo.startPos,rooms.cameraInfo.transitionPos = nil,nil

                Misc.unpause()

                EventManager.callEvent("onRoomEnter",rooms.currentRoomIndex)
            end
        end
    end
end



---- SETTINGS BEYOND HERE ----

-- Quick respawn related stuff --

-- Quick respawn, like in Celeste.
rooms.quickRespawn = false
-- Whether or not collectibles (coins, mushrooms, 1-ups, etc) respawn after dying (only affects quick respawn).
rooms.collectiblesRespawn = false
-- Whether or not blocks reset themselves and the p-switch effect resets after dying (only affects quick respawn).
rooms.blocksReset = false
-- Whether or not non-saved star coins will reset after dying (only affects quick respawn).
rooms.starCoinsReset = false
-- Whether or not to create a pseudo "checkpoint" on entering a different section.
rooms.checkpointOnEnterSection = false
-- Whether or not everything is reset on entering a room.
rooms.resetOnEnteringRoom = false

-- Sound effect to be played upon death. Set to nil for none, a number for a vanilla sound effect (see https://wohlsoft.ru/pgewiki/SFX_list_(SMBX64) for a list of IDs) or a string for a file.
rooms.deathSoundEffect = 38
-- How big the "earthquake" effect is upon death. Set to 0 for none.
rooms.deathEarthquake = 0
-- Whether or not the game is paused during the respawn transition.
rooms.pauseOnRespawn = false

-- The type of effect during the quick respawn transition. It can be "rooms.RESPAWN_EFFECT_FADE", "rooms.RESPAWN_EFFECT_MOSAIC", "rooms.RESPAWN_EFFECT_DIAMOND" or "rooms.RESPAWN_EFFECT_DIAMOND_SWEEP".
rooms.respawnEffect = rooms.RESPAWN_EFFECT_MOSAIC
-- How long the screen is "blank" during the respawn transition. Should be at least 6 to work properly.
rooms.respawnBlankTime = 16

-- When using quick respawn, music will be played via lua. However, this can cause problems with other music played through lua, so you can enable this option to disable the automatic music playing.
rooms.dontPlayMusicThroughLua = false

-- When enabled, the respawn BGOs inside a room won't be used.
rooms.neverUseRespawnBGOs = false
-- The direction that the player will face upon respawning on the BGO.
rooms.respawnBGODirections = {[851] = DIR_RIGHT,[852] = DIR_LEFT}


-- Room transition related stuff --

-- The type of effect used to transition between rooms. It can be "rooms.TRANSITION_TYPE_NONE", "rooms.TRANSITION_TYPE_CONSTANT" or "rooms.TRANSITION_TYPE_SMOOTH".
rooms.transitionType = rooms.TRANSITION_TYPE_SMOOTH
-- The speed of each room transition effect.
rooms.transitionSpeeds = {
    [rooms.TRANSITION_TYPE_CONSTANT] = 0.03,
    [rooms.TRANSITION_TYPE_SMOOTH]   = 0.125,
}
-- Whether or not to give the player upwards force when entering a room from the bottom.
rooms.jumpUpOnTransition = true


-- The name of the layer which rooms should be placed on.
rooms.roomLayerName = "Rooms"


return rooms