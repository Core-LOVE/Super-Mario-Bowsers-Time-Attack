local autoscroll = require("autoscroll")
function onLoadSection0()
    autoscroll.scrollRight(0.7)
end
function onLoadSection1()
end

function onTick()
for k,v in ipairs(NPC.get(269)) do
v:transform(210)
end
end