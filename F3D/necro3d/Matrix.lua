--- @class F3D.Matrix
--- @field [01] number
--- @field [02] number
--- @field [03] number
--- @field [04] number
--- @field [05] number
--- @field [06] number
--- @field [07] number
--- @field [08] number
--- @field [09] number
--- @field [10] number
--- @field [11] number
--- @field [12] number
--- @field [13] number
--- @field [14] number
--- @field [15] number
--- @field [16] number

--- 4x4
--- @class F3DMatrix : F3D.Matrix
local F3DMatrix = {
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, 1, 0,
	0, 0, 0, 1,
}
local R3DVector = require "F3D.necro3d.Vector"

local cos = math.cos
local sin = math.sin
local tan = math.tan
local type = type
local vectorCross = R3DVector.cross
local vectorDot = R3DVector.dot
local vectorMultiply = R3DVector.multiply
local vectorNormalize = R3DVector.normalize
local vectorSub = R3DVector.sub

--- Create and return an identity matrix.
--- @return F3D.Matrix
function F3DMatrix.create()
	return {
		F3DMatrix[01],
		F3DMatrix[02],
		F3DMatrix[03],
		F3DMatrix[04],
		F3DMatrix[05],
		F3DMatrix[06],
		F3DMatrix[07],
		F3DMatrix[08],
		F3DMatrix[09],
		F3DMatrix[10],
		F3DMatrix[11],
		F3DMatrix[12],
		F3DMatrix[13],
		F3DMatrix[14],
		F3DMatrix[15],
		F3DMatrix[16],
	}
end

--- @param self F3D.Matrix
--- @param x integer | 1 | 2 | 3 | 4
--- @param y integer | 1 | 2 | 3 | 4
--- @return number
function F3DMatrix:get(x, y)
	return self[(y - 1) * 4 + x]
end

--- @param self F3D.Matrix
--- @param i integer | 1 | 2 | 3 | 4
--- @return number
--- @return number
--- @return number
--- @return number
function F3DMatrix:getColumn(i)
	return self[i], self[i + 4], self[i + 8], self[i + 12]
end

function F3DMatrix:getRotation()
end

--- @param self F3D.Matrix
--- @param i integer | 1 | 2 | 3 | 4
--- @return number
--- @return number
--- @return number
--- @return number
function F3DMatrix:getRow(i)
	i = i * 4
	return self[i - 3], self[i - 2], self[i - 1], self[i]
end

function F3DMatrix:getScale()
end

function F3DMatrix:getTranslation()
end

--- @param self F3D.Matrix
--- @param x integer | 1 | 2 | 3 | 4
--- @param y integer | 1 | 2 | 3 | 4
--- @param v number
function F3DMatrix:set(x, y, v)
	self[(y - 1) * 4 + x] = v
end

function F3DMatrix:reset()
	self[01] = F3DMatrix[01]
	self[02] = F3DMatrix[02]
	self[03] = F3DMatrix[03]
	self[04] = F3DMatrix[04]
	self[05] = F3DMatrix[05]
	self[06] = F3DMatrix[06]
	self[07] = F3DMatrix[07]
	self[08] = F3DMatrix[08]
	self[09] = F3DMatrix[09]
	self[10] = F3DMatrix[10]
	self[11] = F3DMatrix[11]
	self[12] = F3DMatrix[12]
	self[13] = F3DMatrix[13]
	self[14] = F3DMatrix[14]
	self[15] = F3DMatrix[15]
	self[16] = F3DMatrix[16]
	return self
end

--region Full set functions

--- @param x number @start position x
--- @param y number @start position y
--- @param z number @start position z
--- @param dx number @target position x
--- @param dy number @target position y
--- @param dz number @target position z
--- @param ux number @up direction x
--- @param uy number @up direction y
--- @param uz number @up direction z
function F3DMatrix:lookAt(x, y, z, dx, dy, dz, ux, uy, uz)
	local fx, fy, fz = vectorNormalize(dx, dy, dz)
	local rx, ry, rz = vectorCross(fx, fy, fz, vectorNormalize(ux, uy, uz))
	ux, uy, uz = vectorCross(rx, ry, rz, fx, fy, fz)

	self[01] = rx
	self[05] = ry
	self[09] = rz

	self[02] = ux
	self[06] = uy
	self[10] = uz

	self[03] = -fx
	self[07] = -fy
	self[11] = -fz

	self[13] = -vectorDot(rx, ry, rz, x, y, z)
	self[14] = -vectorDot(ux, uy, uz, x, y, z)
	self[15] = vectorDot(fx, fy, fz, x, y, z)

	self[04] = 0
	self[08] = 0
	self[12] = 0
	self[16] = 1

	return self
end

function F3DMatrix:orthogonal(near, far, left, right, top, bottom)
	self[01] = 2 / (right - left)
	self[02] = 0
	self[03] = 0
	self[04] = -(right + left) / (right - left)

	self[05] = 0
	self[06] = 2 / (top - bottom)
	self[07] = 0
	self[08] = -(top + bottom) / (top - bottom)

	self[09] = 0
	self[10] = 0
	self[11] = -2 / (far - near)
	self[12] = -(far + near) / (far - near)

	self[13] = 0
	self[14] = 0
	self[15] = 0
	self[16] = 1

	return self
end

function F3DMatrix:perspective(near, far, fov, aspect)
	local f = 1 / tan(fov / 2)
	local r = 1 / (near - far)
	self[1] = f / aspect
	self[2] = 0
	self[3] = 0
	self[4] = 0
	self[5] = 0
	self[6] = f
	self[7] = 0
	self[8] = 0
	self[9] = 0
	self[10] = 0
	self[11] = 2 * far * near * r
	self[12] = -1
	self[13] = 0
	self[14] = 0
	self[15] = (far + near) * r
	self[16] = 0
	return self
end

--- @param self F3D.Matrix
--- @param tx number
--- @param ty number
--- @param tz number
--- @param rx number
--- @param ry number
--- @param rz number
--- @param sx number
--- @param sy number
--- @param sz number
--- @return self
function F3DMatrix:trs(tx, ty, tz,
					   rx, ry, rz,
					   sx, sy, sz)
	error("TODO: R3DMatrix:setTRS")
	local a = self
	a[01] = 0
	a[02] = 0
	a[03] = 0
	a[04] = 0
	a[05] = 0
	a[06] = 0
	a[07] = 0
	a[08] = 0
	a[09] = 0
	a[10] = 0
	a[11] = 0
	a[12] = 0
	a[13] = 0
	a[14] = 0
	a[15] = 0
	a[16] = 0
	return a
end

--#endregion

--- @param self F3D.Matrix
--- @return boolean
function F3DMatrix:isIdentity()
	return F3DMatrix.equals(self, F3DMatrix)
end

function F3DMatrix.addImpl()
	-- TODO
end

local matrixAddImpl

function F3DMatrix.add(matrix)
	-- TODO
end

function F3DMatrix:copy()
	return F3DMatrix.setmetatable {
		self[01],
		self[02],
		self[03],
		self[04],
		self[05],
		self[06],
		self[07],
		self[08],
		self[09],
		self[10],
		self[11],
		self[12],
		self[13],
		self[14],
		self[15],
		self[16],
	}
end

function F3DMatrix:equals(matrix)
	return
		self[01] == matrix[01] and
		self[02] == matrix[02] and
		self[03] == matrix[03] and
		self[04] == matrix[04] and
		self[05] == matrix[05] and
		self[06] == matrix[06] and
		self[07] == matrix[07] and
		self[08] == matrix[08] and
		self[09] == matrix[09] and
		self[10] == matrix[10] and
		self[11] == matrix[11] and
		self[12] == matrix[12] and
		self[13] == matrix[13] and
		self[14] == matrix[14] and
		self[15] == matrix[15] and
		self[16] == matrix[16]
end

function F3DMatrix:inverse()
	local m11, m12, m13, m14 = self[01], self[02], self[03], self[04]
	local m21, m22, m23, m24 = self[05], self[06], self[07], self[08]
	local m31, m32, m33, m34 = self[09], self[10], self[11], self[12]
	local m41, m42, m43, m44 = self[13], self[14], self[15], self[16]

	local s1 = m11 * m22 - m21 * m12
	local s2 = m11 * m23 - m21 * m13
	local s3 = m11 * m24 - m21 * m14
	local s4 = m12 * m23 - m22 * m13
	local s5 = m12 * m24 - m22 * m14
	local s6 = m13 * m24 - m23 * m14

	local c6 = m33 * m44 - m43 * m34
	local c5 = m32 * m44 - m42 * m34
	local c4 = m32 * m43 - m42 * m33
	local c3 = m31 * m44 - m41 * m34
	local c2 = m31 * m43 - m41 * m33
	local c1 = m31 * m42 - m41 * m32

	local det = (s1 * c6 - s2 * c5 + s3 * c4) + (s4 * c3 - s5 * c2 + s6 * c1)
	if det == 0 then
		error("Matrix is singular and cannot be inverted.", 2)
	end

	local invDet = 1 / det
	self[01] = (m22 * c6 - m23 * c5 + m24 * c4) * invDet
	self[02] = (-m12 * c6 + m13 * c5 - m14 * c4) * invDet
	self[03] = (m42 * s6 - m43 * s5 + m44 * s4) * invDet
	self[04] = (-m32 * s6 + m33 * s5 - m34 * s4) * invDet
	self[05] = (-m21 * c6 + m23 * c3 - m24 * c2) * invDet
	self[06] = (m11 * c6 - m13 * c3 + m14 * c2) * invDet
	self[07] = (-m41 * s6 + m43 * s3 - m44 * s2) * invDet
	self[08] = (m31 * s6 - m33 * s3 + m34 * s2) * invDet
	self[09] = (m21 * c5 - m22 * c3 + m24 * c1) * invDet
	self[10] = (-m11 * c5 + m12 * c3 - m14 * c1) * invDet
	self[11] = (m41 * s5 - m42 * s3 + m44 * s1) * invDet
	self[12] = (-m31 * s5 + m32 * s3 - m34 * s1) * invDet
	self[13] = (-m21 * c4 + m22 * c2 - m23 * c1) * invDet
	self[14] = (m11 * c4 - m12 * c2 + m13 * c1) * invDet
	self[15] = (-m41 * s4 + m42 * s2 - m43 * s1) * invDet
	self[16] = (m31 * s4 - m32 * s2 + m33 * s1) * invDet
	return self
end

--- @param self F3D.Matrix
--- @param m01 number
--- @param m02 number
--- @param m03 number
--- @param m04 number
--- @param m05 number
--- @param m06 number
--- @param m07 number
--- @param m08 number
--- @param m09 number
--- @param m10 number
--- @param m11 number
--- @param m12 number
--- @param m13 number
--- @param m14 number
--- @param m15 number
--- @param m16 number
--- @return self
function F3DMatrix:multiplyImpl(m01, m02, m03, m04,
								m05, m06, m07, m08,
								m09, m10, m11, m12,
								m13, m14, m15, m16)
	local a = self
	a[01], a[02], a[03], a[04], a[05], a[06], a[07], a[08], a[09], a[10], a[11], a[12], a[13], a[14], a[15], a[16] =
		a[01] * m01 + a[05] * m02 + a[09] * m03 + a[13] * m04,
		a[02] * m01 + a[06] * m02 + a[10] * m03 + a[14] * m04,
		a[03] * m01 + a[07] * m02 + a[11] * m03 + a[15] * m04,
		a[04] * m01 + a[08] * m02 + a[12] * m03 + a[16] * m04,
		a[01] * m05 + a[05] * m06 + a[09] * m07 + a[13] * m08,
		a[02] * m05 + a[06] * m06 + a[10] * m07 + a[14] * m08,
		a[03] * m05 + a[07] * m06 + a[11] * m07 + a[15] * m08,
		a[04] * m05 + a[08] * m06 + a[12] * m07 + a[16] * m08,
		a[01] * m09 + a[05] * m10 + a[09] * m11 + a[13] * m12,
		a[02] * m09 + a[06] * m10 + a[10] * m11 + a[14] * m12,
		a[03] * m09 + a[07] * m10 + a[11] * m11 + a[15] * m12,
		a[04] * m09 + a[08] * m10 + a[12] * m11 + a[16] * m12,
		a[01] * m13 + a[05] * m14 + a[09] * m15 + a[13] * m16,
		a[02] * m13 + a[06] * m14 + a[10] * m15 + a[14] * m16,
		a[03] * m13 + a[07] * m14 + a[11] * m15 + a[15] * m16,
		a[04] * m13 + a[08] * m14 + a[12] * m15 + a[16] * m16
	return a
end

local matrixMultiplyImpl = F3DMatrix.multiplyImpl

--- @param self F3D.Matrix
--- @param matrix F3D.Matrix
--- @return self
function F3DMatrix:multiply(matrix)
	local b = matrix
	return matrixMultiplyImpl(self,
		b[01], b[02], b[03], b[04],
		b[05], b[06], b[07], b[08],
		b[09], b[10], b[11], b[12],
		b[13], b[14], b[15], b[16])
end

--- @param x number
--- @param y number
--- @param z number
--- @param w number?
--- @return number x
--- @return number y
--- @return number z
--- @return number w
function F3DMatrix:multiplyVector(x, y, z, w)
	w = w or 1
	x, y, z, w =
		x * self[01] + y * self[02] + z * self[03] + w * self[04],
		x * self[05] + y * self[06] + z * self[07] + w * self[08],
		x * self[09] + y * self[10] + z * self[11] + w * self[12],
		x * self[13] + y * self[14] + z * self[15] + w * self[16]
	return x, y, z, w
end

--- ```
--- |x1 y1 z1 0|    | x1  x2  x3 0|
--- |x2 y2 z2 0|    | y1  y2  y3 0|
--- |x3 y3 z3 0|    | z1  z2  z3 0|
--- |tx ty yz 1|    |-tx -ty -yz 1|
--- ```
--- @return F3DMatrix
function F3DMatrix:quickInverse()
	local a = self
	local b = F3DMatrix.new()

	b[1] = a[1]
	b[2] = a[5]
	b[3] = a[9]
	b[4] = 0
	b[5] = a[2]
	b[6] = a[6]
	b[7] = a[10]
	b[8] = 0
	b[9] = a[3]
	b[10] = a[7]
	b[11] = a[11]
	b[12] = 0
	b[13] = -(a[13] * b[1] + a[14] * b[5] + a[15] * b[9]);
	b[14] = -(a[13] * b[2] + a[14] * b[6] + a[15] * b[10]);
	b[15] = -(a[13] * b[3] + a[14] * b[7] + a[15] * b[11]);
	b[16] = 1

	for index, value in ipairs(b) do
		a[index] = value
	end

	return a
end

--- Rotate angels along x,y,z axis / pitch,yaw,roll.
--- @param y number
--- @param x number
--- @param z number
function F3DMatrix:rotate(x, y, z)
	local cx = cos(x)
	local sx = sin(x)
	local cy = cos(y)
	local sy = sin(y)
	local cz = cos(z)
	local sz = sin(z)

	self[01] = cx * cy
	self[02] = cx * sy * sz - sx * cz
	self[03] = cx * sy * cz + sx * sz
	self[04] = 0
	self[05] = sx * cy
	self[06] = sx * sy * sz + cx * cz
	self[07] = sx * sy * cz - cx * sz
	self[08] = 0
	self[09] = -sy
	self[10] = cy * sz
	self[11] = cy * cz
	self[12] = 0
	return self
end

--- @param v number @pitch
--- @return self
function F3DMatrix:rotateX(v)
	local c = cos(v)
	local s = sin(v)
	return matrixMultiplyImpl(self,
		1, 0, 0, 0,
		0, c, -s, 0,
		0, s, c, 0,
		0, 0, 0, 1)
end

--- @param v number @yaw
--- @return self
function F3DMatrix:rotateY(v)
	local c = cos(v)
	local s = sin(v)
	return matrixMultiplyImpl(self,
		c, 0, s, 0,
		0, 1, 0, 0,
		-s, 0, c, 0,
		0, 0, 0, 1)
end

--- @param v number @roll
--- @return self
function F3DMatrix:rotateZ(v)
	local c = cos(v)
	local s = sin(v)
	return matrixMultiplyImpl(self,
		c, -s, 0, 0,
		s, c, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1)
end

--- @param self F3D.Matrix
--- @param x number
--- @param y number
--- @param z number
--- @return self
function F3DMatrix:scale(x, y, z)
	return matrixMultiplyImpl(self,
		x, 0, 0, 0,
		0, y, 0, 0,
		0, 0, z, 0,
		0, 0, 0, 1)
end

--- @param self F3D.Matrix
--- @param x number
--- @param y number
--- @param z number
--- @return self
function F3DMatrix:translate(x, y, z)
	self[13] = self[13] + x
	self[14] = self[14] + y
	self[15] = self[15] + z
	return self
end

--- @param self F3D.Matrix
--- @param x number
--- @param y number
--- @param z number
--- @return number x
--- @return number y
--- @return number z
function F3DMatrix:transform(x, y, z)
	local a = self
	local w = x * a[4] + y * a[8] + z * a[12] + a[16]
	x, y, z =
		x * a[1] + y * a[5] + z * a[09] + a[13],
		x * a[2] + y * a[6] + z * a[10] + a[14],
		x * a[3] + y * a[7] + z * a[11] + a[15]
	if w == 0 then
		return x, y, z
	end
	w = 1 / w
	return x * w, y * w, z * w
end

do
	local cache = {
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
	}
	function F3DMatrix:tostring()
		cache[01] = self[01]
		cache[02] = self[02]
		cache[03] = self[03]
		cache[04] = self[04]
		cache[05] = self[05]
		cache[06] = self[06]
		cache[07] = self[07]
		cache[08] = self[08]
		cache[09] = self[09]
		cache[10] = self[10]
		cache[11] = self[11]
		cache[12] = self[12]
		cache[13] = self[13]
		cache[14] = self[14]
		cache[15] = self[15]
		cache[16] = self[16]
		return "{" .. table.concat(cache, ",") .. "}"
	end
end

local function metaAdd()
	-- TODO
end

--- @param a F3D.Matrix
--- @param b F3D.Matrix
local function metaMul(a, b)
	return F3DMatrix.new():multiply(a):multiply(b)
end

--- @type metatable
local metatable = {
	__add = metaAdd,
	__call = F3DMatrix.transform,
	__eq = F3DMatrix.equals,
	__index = F3DMatrix,
	__mul = metaMul,
	__newindex = function()
		error("Attempt to add a new field to transformation matrix!", 2)
	end,
}

--- @param matrix F3D.Matrix
--- @return F3DMatrix
function F3DMatrix.setmetatable(matrix)
	--- @diagnostic disable-next-line: return-type-mismatch
	return setmetatable(matrix, metatable)
end

--- @return F3DMatrix
function F3DMatrix.new()
	--- @diagnostic disable-next-line: return-type-mismatch
	return setmetatable(F3DMatrix.create(), metatable)
end

local static = F3DMatrix.new()
function F3DMatrix.static()
	return static
end

return setmetatable(F3DMatrix, {
	__add = metaAdd,
	__call = F3DMatrix.transform,
	__eq = F3DMatrix.equals,
	__mul = metaMul,
	__tostring = F3DMatrix.tostring,
})
