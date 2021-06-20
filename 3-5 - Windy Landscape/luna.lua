local particles = API.load("particles");

pipeAPI = loadAPI("pipecannon")

pipeAPI.exitspeed = {20}

pipeAPI.SFX = 22

pipeAPI.effect = 10

local effect = particles.Emitter(0, 0, Misc.resolveFile("particles/p_fog.ini"));
effect:AttachToCamera(Camera.get()[1]);
effect:setParam("lifetime", "1:6");
effect:setParam("scale", "1:2");
effect:setParam("speedX", "-500:-1500");
effect:setParam("speedX", "-1500:-2500");
effect:setParam("speedY", "0");
effect:setParam("rotSpeed", "100");
effect:setParam("limit", "2000");
local effect2 = particles.Emitter(0, 0, Misc.resolveFile("particles/p_snow.ini"));
effect2:AttachToCamera(Camera.get()[1]);
effect2:setParam("lifetime", "1:3");
effect2:setParam("scale", "0.2:0.4");
effect2:setParam("speedX", "-500:-1500");
effect:setParam("speedY", "100:200");
effect2:setParam("limit", "2000");

local wind = 0

function onTick()
if player.speedX < -3 and player.section~=3 then
player.speedX = -3
end

if not player.keys.right and player.section~=3 then
wind = wind - 0.1
if wind < -0.5 and player.section~=3  then
wind = -0.5
end
player:mem(0x138, FIELD_FLOAT, wind)
else
if player.speedX > 3 and player.section~=3 then
player.speedX = 3
end
wind = 0
player:mem(0x138, FIELD_FLOAT, 0)
end
end

function onCameraUpdate()
effect:Draw();
effect2:Draw();
end