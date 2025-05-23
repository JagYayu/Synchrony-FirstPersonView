--- Use left-hand coordinates, similar to DirectX
--- To improve performance, we use 3 numbers (x, y, z) to represent a vector3, at the cost of bad vector3 api.
--- @class F3DVector
local F3DVector = {}

local inf = math.huge
local sqrt = math.sqrt

--- Vector3 addition
--- @param x1 number
--- @param y1 number
--- @param z1 number
--- @param x2 number
--- @param y2 number
--- @param z2 number
--- @return number x
--- @return number y
--- @return number z
function F3DVector.add(x1, y1, z1,
					   x2, y2, z2)
	return x1 + x2, y1 + y2, z1 + z2
end

--- Vector3 cross product
--- @param x1 number
--- @param y1 number
--- @param z1 number
--- @param x2 number
--- @param y2 number
--- @param z2 number
--- @return number x
--- @return number y
--- @return number z
function F3DVector.cross(x1, y1, z1,
						 x2, y2, z2)
	return
		y1 * z2 - z1 * y2,
		z1 * x2 - x1 * z2,
		x1 * y2 - y1 * x2
end

--- Vector3 dot product
function F3DVector.dot(x1, y1, z1,
					   x2, y2, z2)
	return x1 * x2 + y1 * y2 + z1 * z2
end

function F3DVector.magnitude(x, y, z)
	return sqrt(x * x + y * y + z * z)
end

--- Vector3 scalar multiplication
--- @param x number
--- @param y number
--- @param z number
--- @param v number
--- @return number x
--- @return number y
--- @return number z
function F3DVector.multiply(x, y, z, v)
	return x * v, y * v, z * v
end

--- Vector3 calculate normal vector
--- @param x number
--- @param y number
--- @param z number
function F3DVector.normalize(x, y, z)
	local t = 1 / sqrt(x * x + y * y + z * z)
	return x * t, y * t, z * t
end

function F3DVector.squareMagnitude(x, y, z)
	return x * x + y * y + z * z
end

--- Vector3 subtraction
--- @param x1 number
--- @param y1 number
--- @param z1 number
--- @param x2 number
--- @param y2 number
--- @param z2 number
--- @return number x
--- @return number y
--- @return number z
function F3DVector.sub(x1, y1, z1,
					   x2, y2, z2)
	return x1 - x2, y1 - y2, z1 - z2
end

--#region Constant Vectors

--- @return -1 x
--- @return 0 y
--- @return 0 z
function F3DVector.back()
	return -1, 0, 0
end

--- @return 0 x
--- @return -1 y
--- @return 0 z
function F3DVector.down()
	return 0, -1, 0
end

--- @return 1 x
--- @return 0 y
--- @return 0 z
function F3DVector.forward()
	return 1, 0, 0
end

--- @return 0 x
--- @return 0 y
--- @return 1 z
function F3DVector.left()
	return 0, 0, 1
end

--- @return number x
--- @return number y
--- @return number z
function F3DVector.negativeInfinity()
	return -inf, -inf, -inf
end

--- @return 1 x
--- @return 1 y
--- @return 1 z
function F3DVector.one()
	return 1, 1, 1
end

--- @return number x
--- @return number y
--- @return number z
function F3DVector.positiveInfinity()
	return inf, inf, inf
end

--- @return 0 x
--- @return 0 y
--- @return -1 z
function F3DVector.right()
	return 0, 0, -1
end

--- @return 0 x
--- @return 1 y
--- @return 0 z
function F3DVector.up()
	return 0, 1, 0
end

--- @return 0 x
--- @return 0 y
--- @return 0 z
function F3DVector.zero()
	return 0, 0, 0
end

--#endregion

return F3DVector
