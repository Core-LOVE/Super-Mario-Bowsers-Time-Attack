local particles = API.load("particles")
local effect = particles.Emitter(0, 0, Misc.resolveFile("p_starfall.ini"))
effect:AttachToCamera(Camera.get()[1])
local effect2 = particles.Emitter(0, 0, Misc.resolveFile("p_snow.ini"))
effect2:AttachToCamera(Camera.get()[1])
local rng = API.load("rng")

function onCameraUpdate()
	if player.section ~= 2 and player.section ~= 3 then
		effect:Draw()
		effect2:Draw()
	end
end