--- @class F3D.Frustum

--- @class F3DFrustum : F3D.Frustum
local F3DFrustum = {}
local F3DMatrix = require "F3D.necro3d.Matrix"

local Utilities = require "system.utils.Utilities"

--- @param matrix F3D.Matrix
--- @return F3D.Frustum
function F3DFrustum.create(matrix)
	local planes = Utilities.newTable(6, 0)
	F3DFrustum.set(planes, matrix or F3DMatrix)
	return planes
end

function F3DFrustum:isInside(x, y, z)
	for i = 1, 6 do
		local plane = self[i]
		if plane[1] * x + plane[2] * y + plane[3] * z + plane[4] < 0 then
			return false
		end
	end
	return true
end

function F3DFrustum:set(matrix)
	-- Far
	self[1] = {
		matrix[4] - matrix[3],
		matrix[8] - matrix[7],
		matrix[12] - matrix[11],
		matrix[16] - matrix[15],
	}
	-- Right
	self[2] = {
		matrix[4] - matrix[1],
		matrix[8] - matrix[5],
		matrix[12] - matrix[9],
		matrix[16] - matrix[13],
	}
	-- Left
	self[3] = {
		matrix[4] + matrix[1],
		matrix[8] + matrix[5],
		matrix[12] + matrix[9],
		matrix[16] + matrix[13],
	}
	-- Top
	self[4] = {
		matrix[4] - matrix[2],
		matrix[8] - matrix[6],
		matrix[12] - matrix[10],
		matrix[16] - matrix[14],
	}
	-- Bottom
	self[5] = {
		matrix[4] + matrix[2],
		matrix[8] + matrix[6],
		matrix[12] + matrix[10],
		matrix[16] + matrix[14],
	}
	-- Near
	self[6] = {
		matrix[4] + matrix[3],
		matrix[8] + matrix[7],
		matrix[12] + matrix[11],
		matrix[16] + matrix[15],
	}

	for _, plane in ipairs(self) do
		local length = math.sqrt(plane[1] ^ 2 + plane[2] ^ 2 + plane[3] ^ 2)
		plane[1] = plane[1] / length
		plane[2] = plane[2] / length
		plane[3] = plane[3] / length
		plane[4] = plane[4] / length
	end
end

--- @type metatable
local metatable = {
	__index = F3DFrustum,
}

--- @param frustumPlanes F3D.Frustum
--- @return F3DFrustum
function F3DFrustum.setmetatable(frustumPlanes)
	--- @diagnostic disable-next-line: return-type-mismatch
	return setmetatable(frustumPlanes, metatable)
end

--- @return F3DFrustum
function F3DFrustum.new(matrix)
	--- @diagnostic disable-next-line: return-type-mismatch
	return F3DFrustum.setmetatable(F3DFrustum.create(matrix))
end

return F3DFrustum
