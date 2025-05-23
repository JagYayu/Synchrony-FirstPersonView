--- @class F3D.Quaternion
--- @field [0] number w
--- @field [1] number x
--- @field [2] number y
--- @field [3] number z

--- @class F3DQuaternion : F3D.Quaternion
local F3DQuaternion = {
	[0] = 1,
	0,
	0,
	0,
}
local F3DVector = require "F3D.necro3d.Vector"
local F3DUtility = require "F3D.necro3d.Utility"

local acos = math.acos
local cos = math.cos
local copySign = F3DUtility.copySign
local setmetatable = setmetatable
local sin = math.sin
local sqrt = math.sqrt
local hpi = math.pi / 2
local vectorCross = F3DVector.cross
local vectorDot = F3DVector.dot

local static

function F3DQuaternion.static()
	return static
end

function F3DQuaternion:add(quaternion)
	self[0] = self[0] + quaternion[0]
	self[1] = self[1] + quaternion[1]
	self[2] = self[2] + quaternion[2]
	self[3] = self[3] + quaternion[3]
	return self
end

function F3DQuaternion:conjugate()
	self[1] = -self[1]
	self[2] = -self[2]
	self[3] = -self[3]
	return self
end

function F3DQuaternion:copy()
	return F3DQuaternion.new(self[1], self[2], self[3], self[0])
end

function F3DQuaternion:dot(quaternion)
	return self[0] * quaternion[0] + self[1] * quaternion[1] + self[2] * quaternion[2] + self[3] * quaternion[3]
end

function F3DQuaternion:getW()
	return self[0]
end

function F3DQuaternion:getX()
	return self[1]
end

function F3DQuaternion:getY()
	return self[2]
end

function F3DQuaternion:getZ()
	return self[3]
end

function F3DQuaternion:length()
	local w = self[0]
	local x = self[1]
	local y = self[2]
	local z = self[3]
	return sqrt(w * w + x * x + y * y + z * z)
end

function F3DQuaternion:normalize()
	local len = self:length()
	return len == 0 and self or self:scale(1 / len)
end

function F3DQuaternion:multiply(quaternion)
	self[0], self[1], self[2], self[3] =
		self[0] * quaternion[0] - self[1] * quaternion[1] - self[2] * quaternion[2] - self[3] * quaternion[3],
		self[0] * quaternion[1] + self[1] * quaternion[0] + self[2] * quaternion[3] - self[3] * quaternion[2],
		self[0] * quaternion[2] - self[1] * quaternion[3] + self[2] * quaternion[0] + self[3] * quaternion[1],
		self[0] * quaternion[3] + self[1] * quaternion[2] - self[2] * quaternion[1] + self[3] * quaternion[0]
	return self
end

function F3DQuaternion:rotate(x, y, z)
end

function F3DQuaternion:scale(s)
	self[1] = self[1] * s
	self[2] = self[2] * s
	self[3] = self[3] * s
	return self
end

function F3DQuaternion:setW(v)
	self[0] = v
end

function F3DQuaternion:setX(v)
	self[1] = v
end

function F3DQuaternion:setY(v)
	self[2] = v
end

function F3DQuaternion:setZ(v)
	self[3] = v
end

--- @param quaternion F3DQuaternion
--- @param t any
--- @return F3DQuaternion
function F3DQuaternion:slerp(quaternion, t)
	local cos_theta = self:dot(quaternion:normalize())
	local sign
	if cos_theta < 0 then
		cos_theta = -cos_theta
		sign = -1
	else
		sign = 1
	end

	local c1, c2
	if cos_theta > 1 then
		c1 = 1 - t
		c2 = t
	else
		local theta = acos(cos_theta)
		local sin_theta = sin(theta)
		local t_theta = t * theta
		local inv_sin_theta = 1 / sin_theta
		c1 = sin(theta - t_theta) * inv_sin_theta
		c2 = sin(t_theta) * inv_sin_theta
	end
	c2 = c2 * -sign

	return F3DQuaternion.new(
		self[0] * c1 + quaternion[0] * c2,
		self[1] * c1 + quaternion[1] * c2,
		self[2] * c1 + quaternion[2] * c2,
		self[3] * c1 + quaternion[3] * c2)
end

function F3DQuaternion:squareLength()
	local w = self[0]
	local x = self[1]
	local y = self[2]
	local z = self[3]
	return w * w + x * x + y * y + z * z
end

function F3DQuaternion:sub(quaternion)
	self[1] = self[1] - quaternion[1]
	self[2] = self[2] - quaternion[2]
	self[3] = self[3] - quaternion[3]
	self[0] = self[0] - quaternion[0]
	return self
end

function F3DQuaternion:toEuler()
	local sp = 2 * (self[0] * self[2] - self[3] * self[1])
	local pitch = math.abs(sp) >= 1 and copySign(hpi, sp) or math.asin(sp)

	local sycp = 2 * (self[0] * self[3] + self[1] * self[2])
	local cycp = 1 - 2 * (self[2] * self[2] + self[3] * self[3])
	local yaw = math.atan2(sycp, cycp)

	local srcp = 2 * (self[0] * self[1] + self[2] * self[3])
	local crcp = 1 - 2 * (self[1] * self[1] + self[2] * self[2]);
	local roll = math.atan2(srcp, crcp);

	return pitch, yaw, roll
end

function F3DQuaternion.create(x, y, z, w)
	x = x or F3DQuaternion[1]
	y = y or F3DQuaternion[2]
	z = z or F3DQuaternion[3]
	return {
		[0] = w or F3DQuaternion[0],
		x,
		y,
		z,
	}
end

local metatable = {
	__add = function(self, quaternion)
		return self:copy():add(quaternion)
	end,
	__index = F3DQuaternion,
	__sub = function(self, quaternion)
		return self:copy():sub(quaternion)
	end,
	__tostring = function(self)
		return ("%f, %f, %f, %f"):format(self[1], self[2], self[3], self[0])
	end,
}

function F3DQuaternion.setmetatable(t)
	return setmetatable(t, metatable)
end

--- @return F3DQuaternion
function F3DQuaternion.new(x, y, z, w)
	return F3DQuaternion.setmetatable(F3DQuaternion.create(x, y, z, w))
end

--- @return F3DQuaternion
function F3DQuaternion.newEuler(pitch, yaw, roll)
	local cr = cos(roll * .5)
	local sr = sin(roll * .5)
	local cy = cos(yaw * .5)
	local sy = sin(yaw * .5)
	local cp = cos(pitch * .5)
	local sp = sin(pitch * .5)

	return F3DQuaternion.new(
		cy * cp * sr - sy * sp * cr,
		sy * cp * sr + cy * sp * cr,
		sy * cp * cr - cy * sp * sr,
		cy * cp * cr + sy * sp * sr)
end

--- @diagnostic disable-next-line: redefined-local
static = F3DQuaternion.new()

return F3DQuaternion
