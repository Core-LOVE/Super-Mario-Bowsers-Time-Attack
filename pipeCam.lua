local pipeCam = {}

function pipeCam.onInitAPI()
	registerEvent(pipeCam, "onCameraUpdate", "onCameraUpdate", true)
end

local dest = {}
local hist = {}
local camera = {}
local onAnim = false
pipeCam.speed = 10

function inside(x,y)
  local section = Section(player.section).boundary
  if x < section.top and x > section.bottom and y < section.right and y > section.left then
    return true
  end
  return false
end

function pipeCam.onCameraUpdate()
  camera.x = Camera.get()[1].x
  camera.y = Camera.get()[1].y
  if player:mem(0x124,FIELD_DFLOAT) ~= 0 and player:mem(0x122,FIELD_WORD) and player.section == hist.section then
    dest.x = Camera.get()[1].x
    dest.y = Camera.get()[1].y
    camera.x = hist.x
    camera.y = hist.y
    onAnim = true
    Misc.pause()
  end

  if onAnim then
    if camera.x < dest.x then
      camera.x = camera.x + pipeCam.speed
    elseif camera.x > dest.x then
      camera.x = camera.x - pipeCam.speed
    end
    if camera.y < dest.y then
      camera.y = camera.y + pipeCam.speed
    elseif camera.y > dest.y then
      camera.y = camera.y - pipeCam.speed
    end
    if math.abs(camera.x - dest.x) < pipeCam.speed then
      camera.x = dest.x
    end
    if math.abs(camera.y - dest.y) < pipeCam.speed then
      camera.y = dest.y
    end
    if camera.x == dest.x and camera.y == dest.y then
      onAnim = false
      Misc.unpause()
    end
    Camera.get()[1].x = camera.x
    Camera.get()[1].y = camera.y
  end
  hist.x = camera.x
  hist.y = camera.y
  hist.section = player.section
end

return pipeCam
