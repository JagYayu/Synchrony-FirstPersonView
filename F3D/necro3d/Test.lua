if true then
	return
end

local F3DCamera = require "F3D.necro3d.Camera"
local F3DMesh = require "F3D.necro3d.Mesh"
local F3DMatrix = require "F3D.necro3d.Matrix"
local F3DVector = require "F3D.necro3d.Vector"

local Color = require "system.utils.Color"
local GFX = require "system.gfx.GFX"
local Input = require "system.game.Input"
local Random = require "system.utils.Random"
local Render = require "necro.render.Render"
local RenderTimestep = require "necro.render.RenderTimestep"
local Tick = require "necro.cycles.Tick"
local Timer = require "system.utils.Timer"

local ceil = math.ceil
local cos = math.cos
local darken = Color.darken
local noise2 = Random.noise2
local rgb = Color.rgb
local sin = math.sin
local vectorCross = F3DVector.cross
local vectorDot = F3DVector.dot
local vectorNormalize = F3DVector.normalize

local RenderTransformCamera3D = Render.Transform.extend "F3D_Camera3DTest"
local RenderBufferViewport = Render.Buffer.extend("ViewportTest", {
	transform = RenderTransformCamera3D,
})

local camera = F3DCamera.new()

local bufferID = Render.Buffer.UI_BEAT_BARS
local buffer = Render.getBuffer(bufferID)
local bufferDraw = buffer.draw
local bufferDrawArgs = { rect = { 0, 0, 0, 0 } }
local bufferDrawQuad = buffer.drawQuad
local negative1Third = -1 / 3

local noiseColorCache = {}

local drawTriangleArgs = {
	vertices = { {}, {}, {}, {} },
	texture = "mods/F3D/gfx/Banner.png",
}
local drawTriangle1ArgsVertices = drawTriangleArgs.vertices
local function drawQuad1(i, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, a)
	if not noiseColorCache[i] then
		local r = noise2(i, 0x00, 0xdd) + 0x22
		local g = noise2(i, 0x88, 0xdd) + 0x22
		local b = noise2(i, 0xff, 0xdd) + 0x22
		noiseColorCache[i] = rgb(r, g, b)
	end

	local c = darken(noiseColorCache[i], ceil(a / 255) + .2)

	drawTriangle1ArgsVertices[1].x = x1
	drawTriangle1ArgsVertices[1].y = y1
	drawTriangle1ArgsVertices[1].z = z1
	drawTriangle1ArgsVertices[1].color = c
	drawTriangle1ArgsVertices[2].x = x2
	drawTriangle1ArgsVertices[2].y = y2
	drawTriangle1ArgsVertices[2].z = z2
	drawTriangle1ArgsVertices[2].color = c
	drawTriangle1ArgsVertices[3].x = x3
	drawTriangle1ArgsVertices[3].y = y3
	drawTriangle1ArgsVertices[3].z = z3
	drawTriangle1ArgsVertices[3].color = c
	drawTriangle1ArgsVertices[4].x = x4
	drawTriangle1ArgsVertices[4].y = y4
	drawTriangle1ArgsVertices[4].z = z4
	drawTriangle1ArgsVertices[4].color = c
	drawTriangleArgs.z = (z1 + z2 + z3 + z4) * negative1Third
	bufferDrawQuad(drawTriangleArgs)
end

local axisMesh = F3DMesh.newFromObjFile "mods/F3D/gfx/models/test/axis.obj"

local function drawTriangle2(x1, y1, z1, x2, y2, z2, x3, y3, z3)
	drawTriangle1ArgsVertices[1].x = x1
	drawTriangle1ArgsVertices[1].y = y1
	drawTriangle1ArgsVertices[1].color = -1
	drawTriangle1ArgsVertices[2].x = x2
	drawTriangle1ArgsVertices[2].y = y2
	drawTriangle1ArgsVertices[2].color = -1
	drawTriangle1ArgsVertices[3].x = x3
	drawTriangle1ArgsVertices[3].y = y3
	drawTriangle1ArgsVertices[3].color = -1

	-- local x, y, z = camera:getPosition()
	-- x, y, z = x1 - x, y1 - y, z1 - z
	-- drawTriangleArgs.z = x * x + y * y + z * z

	bufferDrawQuad(drawTriangleArgs)
end

--- @class VertexBuffer.AttributeMap
--- @field x? number[] Vertex X positions
--- @field y? number[] Vertex Y positions
--- @field z? number[] Vertex Z positions (independent of Z-sort order, but initialized to same value)
--- @field color? number[] Vertex colors
--- @field tx? number[] Resolved vertex texture X coordinates (may encode texture atlas ID)
--- @field ty? number[] Resolved vertex texture Y coordinates (may encode texture layer ID)
--- @field anim? integer[] Vertex animation attribute tables
--- @field zOrder? number[] Vertex Z-sort order (only one value per quad)

--- @param mesh F3DMesh
--- @param transformationMatrix? F3DMatrix
local function drawMesh(mesh, transformationMatrix)
	transformationMatrix = transformationMatrix or F3DMatrix.static()

	--- @type VertexBuffer.AttributeMap
	local vertices = {
		x = {},
		y = {},
		z = {},
		color = {},
		tx = {},
		ty = {},
		anim = nil,
		zOrder = {},
	}
	local x = vertices.x
	local y = vertices.y
	local z = vertices.z
	local color = vertices.color
	local tx = vertices.tx
	local ty = vertices.ty
	local zOrder = vertices.zOrder

	local cameraX, cameraY, cameraZ = camera:getPosition()
	local img = GFX.getImageGeometry("ext/entities/armadillo.png") or {}

	local i = 0
	mesh:foreachQuads(function(vx1, vy1, vz1, tx1, ty1,
							   vx2, vy2, vz2, tx2, ty2,
							   vx3, vy3, vz3, tx3, ty3,
							   vx4, vy4, vz4, tx4, ty4)
		vx1, vy1, vz1 = transformationMatrix(vx1, vy1, vz1)
		vx2, vy2, vz2 = transformationMatrix(vx2, vy2, vz2)
		vx3, vy3, vz3 = transformationMatrix(vx3, vy3, vz3)
		vx4, vy4, vz4 = transformationMatrix(vx4, vy4, vz4)
		-- if false then
		-- 	vx1, vy1, vz1 = matCam(vx1, vy1, vz1)
		-- 	vx2, vy2, vz2 = matCam(vx2, vy2, vz2)
		-- 	vx3, vy3, vz3 = matCam(vx3, vy3, vz3)
		-- 	vx4, vy4, vz4 = matCam(vx4, vy4, vz4)
		-- 	vx1, vy1, vz1 = matProj(vx1, vy1, vz1)
		-- 	vx2, vy2, vz2 = matProj(vx2, vy2, vz2)
		-- 	vx3, vy3, vz3 = matProj(vx3, vy3, vz3)
		-- 	vx4, vy4, vz4 = matProj(vx4, vy4, vz4)
		-- 	vx1, vy1, vz1 = matView(vx1, vy1, vz1)
		-- 	vx2, vy2, vz2 = matView(vx2, vy2, vz2)
		-- 	vx3, vy3, vz3 = matView(vx3, vy3, vz3)
		-- 	vx4, vy4, vz4 = matView(vx4, vy4, vz4)
		-- elseif false then
		-- 	vx1, vy1, vz1 = mat(vx1, vy1, vz1)
		-- 	vx2, vy2, vz2 = mat(vx2, vy2, vz2)
		-- 	vx3, vy3, vz3 = mat(vx3, vy3, vz3)
		-- 	vx4, vy4, vz4 = mat(vx4, vy4, vz4)
		-- end

		if not noiseColorCache[i] then
			local r = noise2(i, 0x00, 0xdd) + 0x22
			local g = noise2(i, 0x88, 0xdd) + 0x22
			local b = noise2(i, 0xff, 0xdd) + 0x22
			noiseColorCache[i] = rgb(r, g, b)
		end
		local c = noiseColorCache[i]

		local j = i * 4
		color[j + 1] = c
		color[j + 2] = c
		color[j + 3] = c
		color[j + 4] = c
		tx[j + 1] = img.x + 24
		tx[j + 2] = img.x
		tx[j + 3] = img.x
		tx[j + 4] = img.x + 24
		ty[j + 1] = img.y + 24
		ty[j + 2] = img.y + 24
		ty[j + 3] = img.y
		ty[j + 4] = img.y
		x[j + 1] = vx1
		x[j + 2] = vx2
		x[j + 3] = vx3
		x[j + 4] = vx4
		y[j + 1] = vy1
		y[j + 2] = vy2
		y[j + 3] = vy3
		y[j + 4] = vy4
		z[j + 1] = vz1
		z[j + 2] = vz2
		z[j + 3] = vz3
		z[j + 4] = vz4
		do
			local vx = (vx1 + vx2 + vx3 + vx4) * .25
			local vy = (vy1 + vy2 + vy3 + vy4) * .25
			local vz = (vz1 + vz2 + vz3 + vz4) * .25
			zOrder[i + 1] = -F3DVector.magnitude(
				vx - cameraX,
				vy - cameraY,
				vz - cameraZ)
		end
		-- zOrder[i + 1] = (vz1 - cameraX + vz2 - cameraX + vz3) * negative1Third

		bufferDraw(bufferDrawArgs)
		-- drawQuad1(i,
		-- 	vx1, vy1, vz1,
		-- 	vx2, vy2, vz2,
		-- 	vx3, vy3, vz3,
		-- 	vx4, vy4, vz4,
		-- 	255)
		i = i + 1
	end)

	local j = i * 4
	color[j + 1] = -1
	color[j + 2] = -1
	color[j + 3] = -1
	color[j + 4] = -1
	tx[j + 1] = img.x
	tx[j + 2] = img.x
	tx[j + 3] = img.x + 24
	tx[j + 4] = img.x + 24
	ty[j + 1] = img.y
	ty[j + 2] = img.y + 24
	ty[j + 3] = img.y + 24
	ty[j + 4] = img.y
	x[j + 1] = 0
	x[j + 2] = 0
	x[j + 3] = 1
	x[j + 4] = 1
	y[j + 1] = 0
	y[j + 2] = 1
	y[j + 3] = 1
	y[j + 4] = 0
	z[j + 1] = 1
	z[j + 2] = 1
	z[j + 3] = 1
	z[j + 4] = 1

	bufferDraw(bufferDrawArgs)

	buffer.write(0, i + 1, vertices)
	-- print(vertices)
end

event.renderUI.add("finalizeVertexBuffers1", { order = "finalizeBuffers", sequence = 1 }, function(ev)
end)

event.renderUI.add("test", "renderGame", function()
	if true then
		-- return
	end

	if axisMesh then
		local t = 1 -- Timer.getGlobalTime()
		local mat = F3DMatrix:new()
		-- mat:rotate(t, t * .7, t * .3)
		-- mat:translate(0, 0, 0)

		drawMesh(axisMesh, mat)
	end

	local cameraX, cameraY, cameraZ = camera:getPosition()

	local dx, dy, dz = camera:getDirection()
	local pitch, yaw, roll = camera:getRotation()
	local matCam = F3DMatrix.new()
		:lookAt(cameraX, cameraY, cameraZ, dx, dy, dz,
			F3DMatrix.static():reset():rotate(pitch, yaw, roll)(F3DVector.up()))
		:scale(1, 1, 1)

	local matProj = F3DMatrix.static():reset()
		:perspective(
			camera[F3DCamera.Field.Near],
			camera[F3DCamera.Field.Far],
			camera[F3DCamera.Field.FieldOfView],
			camera[F3DCamera.Field.AspectRatio])

	local w, h = GFX.getSize()
	local matView = F3DMatrix.static():reset()
		:scale(w / 2, h / 2, 1)
		:translate(w / 2, h / 2, 0)

	local mat = F3DMatrix.new()
		:multiply(matView)
		:multiply(matProj)
		:multiply(matCam)
	buffer.setTransform(mat)

	-- print("test", mat:tostring())

	buffer.draw {
		rect = { -100, -100, 200, 200 },
		texture = "ext/entities/armadillo.png",
		texRect = { 0, 0, 24, 24 },
		color = -1,
		angle = 0,
		anim = 0,
	}

	local vertices = {
		x = {},
		y = {},
		z = {},
		color = {},
		tx = {},
		ty = {},
		anim = nil,
		zOrder = {},
	}
	buffer.read(0, 1, vertices)
	local vertexIndex = 0
	local i1 = vertexIndex * 4 + 1
	local i2 = i1 + 1
	local i3 = i2 + 1
	local i4 = i3 + 1
	vertexIndex = vertexIndex + 1

	local s = 1
	local x, y, z, w, h, t, tx, ty, tw, th = -s, -s, 0, s * 2, s * 2, "ext/level/boss_floor_A.png", 1, 1, 24, 24

	-- animList[vertexIndex] = a

	vertices.color[i1] = -1
	vertices.color[i2] = -1
	vertices.color[i3] = -1
	vertices.color[i4] = -1

	do
		local geom = GFX.getImageGeometry(t)
		-- print(geom)
		local geomX = geom.x
		local geomY = geom.y

		vertices.tx[i1] = geomX + tx
		vertices.tx[i2] = geomX + tx + tw
		vertices.tx[i3] = geomX + tx
		vertices.tx[i4] = geomX + tx + tw

		vertices.ty[i1] = geomY + ty
		vertices.ty[i2] = geomY + ty
		vertices.ty[i3] = geomY + ty + th
		vertices.ty[i4] = geomY + ty + th
	end

	vertices.x[i1] = x
	vertices.x[i2] = x + w
	vertices.x[i3] = x
	vertices.x[i4] = x + w

	vertices.y[i1] = y
	vertices.y[i2] = y
	vertices.y[i3] = y
	vertices.y[i4] = y

	vertices.z[i1] = z
	vertices.z[i2] = z
	vertices.z[i3] = z + h
	vertices.z[i4] = z + h

	vertices.zOrder[vertexIndex] = -F3DVector.magnitude(x - cameraX, y - cameraY, z - cameraZ)
	-- for i, y in ipairs(vertices.y) do
	-- 	vertices.y[i] = vertices.z[i]
	-- 	vertices.z[i] = y
	-- end
	buffer.write(0, 1, vertices)
	-- print(vertices)
end)

event.tick.add("moveCamera", "inputControls", function()
	if true then
		return
	end

	local x, y, z = camera:getPosition()
	local pitch, yaw, roll = camera:getRotation()

	local rotateSpeed = .005
	pitch = pitch + (Input.keyDown "R" and rotateSpeed or 0)
	pitch = pitch - (Input.keyDown "F" and rotateSpeed or 0)
	yaw = yaw + (Input.keyDown "Q" and rotateSpeed or 0)
	yaw = yaw - (Input.keyDown "E" and rotateSpeed or 0)
	roll = roll + (Input.keyDown "Z" and rotateSpeed or 0)
	roll = roll - (Input.keyDown "X" and rotateSpeed or 0)

	local moveSpeed = .1 * RenderTimestep.getDeltaTime()
	y = y + (Input.keyDown "Space" and moveSpeed or 0)
	y = y - (Input.keyDown "LShift" and moveSpeed or 0)
	local dx, dy, dz = F3DMatrix.new():rotateY(yaw)(F3DVector.forward())
	if Input.keyDown "W" then
		x = x + dx * moveSpeed
		z = z + dz * moveSpeed
	end
	if Input.keyDown "S" then
		x = x - dx * moveSpeed
		z = z - dz * moveSpeed
	end
	dx, dy, dz = F3DMatrix.new():rotateY(-math.pi / 2)(dx, dy, dz)
	if Input.keyDown "D" then
		x = x + dx * moveSpeed
		z = z + dz * moveSpeed
	end
	if Input.keyDown "A" then
		x = x - dx * moveSpeed
		z = z - dz * moveSpeed
	end

	-- print(math.floor(camera[1] + .5), math.floor(camera[3] + .5))
	camera:setPosition(x, y, z):setRotation(pitch, yaw, roll)
end)

-- event.renderUI.override("renderGame", function()
-- end)
