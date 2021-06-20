local animation = {}

local mt = {
	__index = animation
}

function animation.new()
	local v = {}
	
	v.frame = 0
	v.frametimer = 0
	
	v.name = ""
	
	setmetatable(v, mt)
	return v
end

function animation:defineState(name, t)
	local v = self
	
	v[name] = t
end

function animation:setState(name)
	if self.name ~= name then
		self.frame = 0
		self.frametimer = 0
		self.name = name
	end
end

function animation:getState()
	return self.name
end

function animation:getFrame()
	if self.name == "" or not self[self.name] then 
		return self.frame
	end
	
	return self[self.name][self.frame + 1]
end

function animation:update(timer)
	if self.name == "" or not self[self.name] then return end
	
	local v = self
	local a = self[self.name]
	local f = 0
	
	a.framedelay = a.framedelay or 8
	
	v.frametimer = v.frametimer + (timer or 1)
	if v.frametimer >= a.framedelay then
		if a.stop then
			if v.frame <= #a then
				v.frame = (v.frame + 1)
			end
		else
			v.frame = (v.frame + 1) % #a
		end
	
		v.frametimer = 0

		f = a[v.frame + 1]
	end
	
	return f
end

return animation