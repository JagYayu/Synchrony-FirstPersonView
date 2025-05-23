--- @class F3DMesh : F3D.Mesh
local F3DMesh = {}
local F3DUtility = require "F3D.necro3d.Utility"

local FileIO = require "system.game.FileIO"
local Utilities = require "system.utils.Utilities"

local arrayFind = Utilities.arrayFind
local clearTable = Utilities.clearTable
local setmetatable = setmetatable
local splitString = F3DUtility.splitString
local tonumber = tonumber
--- @type fun(narray: integer, nhash: integer): table
local newTable = Utilities.newTable

--- 3D Mesh
--- @warn Do not modify elements inside table directly. Use module functions instead.
--- @class F3D.Mesh
--- @field [1] number[] @Vertices: 3 numbers as 1 group, represents a vertex.
--- @field [2] number[] @UVs
--- @field [3] number[] @Normals: 3 numbers as 1 group, represents a vertex normal vectors.
--- @field [4] integer[] @Triangle vertices: 3 vertex index as 1 group, represents a triangle.
--- @field [5] integer[] @Triangle normals.

--- @return F3D.Mesh
function F3DMesh.create()
	return {
		{},
		{},
		{},
		{},
		{},
		{},
	}
end

local function toNumberOr0(e)
	return tonumber(e) or 0
end

--- @param str string
--- @return table
function F3DMesh.createFromObj(str)
	local requiredBytes = {
		[("f"):byte()] = true,
		[("v"):byte()] = true,
	}

	--- @type { x: number, y: number, z: number }[]
	local vList = {}
	--- @type { u: number, v: number, w: number }[]
	local vtList = {}
	--- @type { x: number, y: number, z: number }[]
	local vnList = {}
	--- @type { v: number, vt: number, vn: number }[][]
	local fList = {}

	--- @type string[]
	local li = {}
	---  @type string[]
	local lif = {}
	for _, line in ipairs(splitString(str, "\n")) do
		if not requiredBytes[line:byte()] then
			goto continue
		end

		clearTable(li)
		splitString(line, " ", li)
		local k = li[1]
		if k == "v" then
			vList = vList or {}
			vList[#vList + 1] = {
				x = toNumberOr0(li[2]),
				y = toNumberOr0(li[3]),
				z = toNumberOr0(li[4]),
			}
		elseif k == "vt" then
			vtList = vtList or {}
			vtList[#vtList + 1] = {
				u = toNumberOr0(li[2]),
				v = toNumberOr0(li[3]),
				w = toNumberOr0(li[4]),
			}
		elseif k == "vn" then
			vnList = vnList or {}
			vnList[#vnList + 1] = {
				x = toNumberOr0(li[2]),
				y = toNumberOr0(li[3]),
				z = toNumberOr0(li[4]),
			}
		elseif k == "f" then
			fList = fList or {}
			fList[#fList + 1] = {}
			local f = fList[#fList]

			for i = 2, math.huge do
				local e = li[i]
				if not e then
					break
				end

				clearTable(lif)
				splitString(e, "/", lif)
				f[i - 1] = {
					v = toNumberOr0(lif[1]),
					vt = toNumberOr0(lif[2]),
					vn = toNumberOr0(lif[3]),
				}
			end
		end

		::continue::
	end

	local vertices = {}
	local uvs = {}
	local normals = {}
	local quadVertices = {}
	local quadTextures = {}
	local quadNormals = {}

	for _, v in ipairs(vList) do
		vertices[#vertices + 1] = v.x
		vertices[#vertices + 1] = v.y
		vertices[#vertices + 1] = v.z
	end

	for _, vn in ipairs(vnList) do
		normals[#normals + 1] = vn.x
		normals[#normals + 1] = vn.y
		normals[#normals + 1] = vn.z
	end

	for _, f in ipairs(fList) do
		local fe1 = f[1]
		local fe2 = f[2]
		local fe3 = f[3]
		local fe4 = f[4]

		if fe4 then
			quadVertices[#quadVertices + 1] = fe1.v
			quadVertices[#quadVertices + 1] = fe2.v
			quadVertices[#quadVertices + 1] = fe4.v
			quadVertices[#quadVertices + 1] = fe3.v

			quadTextures[#quadTextures + 1] = fe1.vt
			quadTextures[#quadTextures + 1] = fe4.vt
			quadTextures[#quadTextures + 1] = fe2.vt
			quadTextures[#quadTextures + 1] = fe3.vt

			quadNormals[#quadNormals + 1] = fe1.vn
			quadNormals[#quadNormals + 1] = fe4.vn
			quadNormals[#quadNormals + 1] = fe2.vn
			quadNormals[#quadNormals + 1] = fe3.vn
		else
			fe4 = fe3
			quadVertices[#quadVertices + 1] = fe1.v
			quadVertices[#quadVertices + 1] = fe2.v
			quadVertices[#quadVertices + 1] = fe3.v
			quadVertices[#quadVertices + 1] = fe4.v

			quadTextures[#quadTextures + 1] = fe1.vt
			quadTextures[#quadTextures + 1] = fe2.vt
			quadTextures[#quadTextures + 1] = fe3.vt
			quadTextures[#quadTextures + 1] = fe4.vt

			quadNormals[#quadNormals + 1] = fe1.vn
			quadNormals[#quadNormals + 1] = fe2.vn
			quadNormals[#quadNormals + 1] = fe3.vn
			quadNormals[#quadNormals + 1] = fe4.vn
		end
	end

	return {
		vertices,
		uvs,
		normals,
		quadVertices,
		quadTextures,
		quadNormals,
	}
end

--- @param path string
--- @return F3D.Mesh? mesh
function F3DMesh.createFromObjFile(path)
	local str = FileIO.readFileToString(path)
	if str then
		return F3DMesh.createFromObj(str)
	end
end

--- @param vertexCount integer
--- @return F3DMesh mesh
function F3DMesh.new(vertexCount)
	return F3DMesh.setmetatable(F3DMesh.create())
end

function F3DMesh:getSize()
	return self[0]
end

--- @param v integer
--- @return boolean shrink
function F3DMesh:setSize(v)
	-- TODO
	return false
end

--@region Vertices operations

--- @param self F3D.Mesh
--- @param i integer
--- @return number? x
--- @return number y
--- @return number z
function F3DMesh:getVertex(i)
	i = i * 3
	local vertices = self[1]
	return vertices[i - 2], vertices[i - 1], vertices[i]
end

--- @param self F3D.Mesh
--- @param i integer
--- @param x number
--- @param y number
--- @param z number
function F3DMesh:setVertex(i, x, y, z)
	local vertices = self[1]

	i = i * 3
	if i > #vertices + 1 then
		-- Fill all skipped elements to 0
		for j = #vertices * 3 + 1, i - 3 do
			vertices[j] = 0
		end
	end

	vertices[i - 2] = x
	vertices[i - 1] = y
	vertices[i] = z
end

local function iterateVerticesImpl(arg)
	local vertices = arg[1]
	local i = arg[2]
	if i < #vertices then
		arg[2] = i + 3
		return vertices[i + 1], vertices[i + 2], vertices[i + 3]
	end
end

local iterateVerticesArg = {}
--- @param self F3D.Mesh
function F3DMesh:iterateVertices()
	iterateVerticesArg[1] = self[1]
	iterateVerticesArg[2] = 0
	return iterateVerticesImpl, iterateVerticesArg
end

--#endregion

--#region Faces operations

--- @param func fun(vx1: number, vy1: number, vz1: number, tx1: number, ty1: number, vx2: number, vy2: number, vz2: number, tx2: number, ty2: number, vx3: number, vy3: number, vz1: number, tx3: number, ty3: number, vx4: number, vy4: number, vz1: number, tx4: number, ty4: number)
function F3DMesh:foreachQuads(func)
	local vertices = self[1]
	local textures = self[2]
	local normals = self[3]
	local quadVertices = self[4]
	local quadTextures = self[5]
	local quadNormals = self[6]

	for i = 0, #quadVertices - 3, 4 do
		local i1 = quadVertices[i + 1]
		local i2 = quadVertices[i + 2]
		local i3 = quadVertices[i + 3]
		local i4 = quadVertices[i + 4]
		local vx1 = vertices[i1 * 3 - 2]
		local vy1 = vertices[i1 * 3 - 1]
		local vz1 = vertices[i1 * 3]
		local vx2 = vertices[i2 * 3 - 2]
		local vy2 = vertices[i2 * 3 - 1]
		local vz2 = vertices[i2 * 3]
		local vx3 = vertices[i3 * 3 - 2]
		local vy3 = vertices[i3 * 3 - 1]
		local vz3 = vertices[i3 * 3]
		local vx4 = vertices[i4 * 3 - 2]
		local vy4 = vertices[i4 * 3 - 1]
		local vz4 = vertices[i4 * 3]

		i1 = quadTextures[i + 1]
		i2 = quadTextures[i + 2]
		i3 = quadTextures[i + 3]
		i4 = quadTextures[i + 4]
		local tx1 = textures[i1 * 3 - 2]
		local ty1 = textures[i1 * 3 - 1]
		local tx2 = textures[i2 * 3 - 2]
		local ty2 = textures[i2 * 3 - 1]
		local tx3 = textures[i3 * 3 - 2]
		local ty3 = textures[i3 * 3 - 1]
		local tx4 = textures[i4 * 4 - 2]
		local ty4 = textures[i4 * 4 - 1]

		func(vx1, vy1, vz1, tx1, ty1,
			vx2, vy2, vz2, tx2, ty2,
			vx3, vy3, vz3, tx3, ty3,
			vx4, vy4, vz4, tx4, ty4)
	end
end

--#endregion

local metatable = {
	__index = F3DMesh,
}

--- @param mesh F3D.Mesh
--- @return F3DMesh
function F3DMesh.setmetatable(mesh)
	--- @diagnostic disable-next-line: return-type-mismatch
	return setmetatable(mesh, metatable)
end

function F3DMesh.newFromObj(obj)
	return F3DMesh.setmetatable(F3DMesh.createFromObj(obj))
end

function F3DMesh.newFromObjFile(path)
	local obj = F3DMesh.createFromObjFile(path)
	return obj and F3DMesh.setmetatable(obj)
end

return F3DMesh
