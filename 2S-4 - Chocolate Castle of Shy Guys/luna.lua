function onTick()
for k,v in ipairs(NPC.get(163)) do
v:transform(19)
end
end

local spawnzones = require("local_spawnzones")