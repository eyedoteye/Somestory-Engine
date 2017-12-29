require "tlz"

easer = {}
easer.instance = {}
easer.size = 0
easer.capacity = 100
easer.freeIndexes = {}
easer.index = 0
easer.methods = {}

function easer.new(self,v0,v1,time,flags)
	local speed = 1
	local loop = nil
	local method = "linear"
	if(flags)then
		speed = flags.speed or speed
		loop = flags.loop or loop
		method = flags.method or method
	end
	
	local index = self.index
	if(index == self.capacity) then
		index = table.remove(self.freeIndexes)
	else
		index = index + 1
		self.index = index
	end
	
	self.instance[index] = {}
	local i = self.instance[index]
	i.method = method
	i.time = time
	i.t = 0
	i.v0 = v0
	i.v1 = v1
	i.speed = speed
	i.loop = loop
	i._dir = 1
	
	self.size = self.size + 1
	if self.size > self.capacity then
		self.capacity = self.capacity * 2
	end
	
	return index
end

function easer.update(self,dt)
	for _,v in pairs(self.instance) do
		v.t = v.t + dt * v.speed * v._dir
		if(v.loop == "linear")then
			v.t = v.t % v.time
		elseif(v.loop == "alternate")then
			if(v.t > v.time)then
				v.t = v.time - (v.t - v.time)
				v._dir = -v._dir
			elseif(v.t < 0) then
				v.t = -v.t
				v._dir = -v._dir
			end
		else
			v.t = math.min(math.max(v.t,0),v.time)
		end
	end
end
	
function easer.get(self,index)
	local i = self.instance[index]
	return self.methods[i.method](i)
end

function easer.getPos(self,index,pos)
	local i = self.instance[index]
	
	return i.t / i.time
end

function easer.setPos(self,index,pos)
	local i = self.instance[index]
	
	i.t = i.time * pos
	
	return self:get(index)
end

function easer.retire(self,index)
	tlz.clearTable(self.instance[index])
	self.instance[index] = nil
	table.insert(self.freeIndexes,index)
end

function easer.debugString(self)
	local s = "---easer---"
		.. "\n size: " .. self.size
		.. "\n capacity: " .. self.capacity
		.. "\n index: " .. self.index
		.. "\n freeIndexes:"
	local i = 0
	for _, v in pairs(self.freeIndexes) do
		s = s .. " " .. v
		i = i + 1
	end
	if(i == 0)then
		s = s .. " nil"
	end

	for k, v in pairs(self.instance) do
		s = s .. "\n instance#" .. k
			.. "\n  t: " .. v.t
			.. "\n  time: " .. v.time
			.. "\n  v0: " .. v.v0
			.. "\n  v1: " .. v.v1
			.. "\n  method: " .. v.method
			.. "\n  speed: " .. v.speed
			.. "\n  loop: " .. (v.loop or "nil")
			.. "\n  _dir: " .. v._dir
	end
	
	return s .. "\n"
end

function easer.scale(self,v0,vt,v1,method)
	local method = method or "linear"
  vt = math.max(v0,vt)
  vt = math.min(vt,v1)
	return self.methods[method]({t = vt - v0, time = (v1 - v0), v0 = 0, v1 = 1})
end

function easer.rescale(self,r,method)
	local method = method or "linear"
	return self.methods[method]({t = r, time = 1, v0 = 0, v1 = 1})
end

function easer.methods.linear(i)
	return (i.t / i.time) * (i.v1 - i.v0) + i.v0
end

function easer.methods.inCubic(i)
	return (i.t / i.time) ^ 3 * (i.v1 - i.v0) + i.v0 
end