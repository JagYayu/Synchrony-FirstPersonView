if true then
	return
end

local F3DCamera = require "F3D.necro3d.Camera"
local F3DMatrix = require "F3D.necro3d.Matrix"
local F3DPlayerCamera = require "F3D.PlayerCamera"
local F3DVector = require "F3D.necro3d.Vector"
local F3DViewport = {}

local Camera = require "necro.render.Camera"
local Color = require "system.utils.Color"
local Enum = require "system.utils.Enum"
local GameWindow = require "necro.config.GameWindow"
local GFX = require "system.gfx.GFX"
local LocalCoop = require "necro.client.LocalCoop"
local OrderedSelector = require "system.events.OrderedSelector"
local Render = require "necro.render.Render"
local Settings = require "necro.config.Settings"
local Tick = require "necro.cycles.Tick"
local TransformationMatrix = require "system.gfx.TransformationMatrix"
local Utilities = require "system.utils.Utilities"

local clearTable = Utilities.clearTable
local getImageGeometry = GFX.getImageGeometry
local type = type
local vectorMagnitude = F3DVector.magnitude

_G.SettingGroupViewport = Settings.overridable.group {
	id = "viewport",
	name = "Viewport",
}

SettingViewportEnable = Settings.overridable.bool {
	id = "viewport.enable",
	name = "Enable",
	default = true,
}

SettingViewportRectangles = Settings.overridable.table {
	id = "viewport.rectangles",
	name = "Rectangles",
	default = {
		{
			{ 0, 0, 1, 1 }
		},
		{
			{ 0, 0,  1, .5 },
			{ 0, .5, 1, 1 },
		},
		{
			{ 0,  0,  .5, .5 },
			{ .5, 0,  1,  .5 },
			{ 0,  .5, 1,  1 },
		},
		{
			{ 0,  0,  .5, .5 },
			{ .5, 0,  1,  .5 },
			{ 0,  .5, .5, 1 },
			{ .5, .5, 1,  1 },
		},
	},
	visibility = Settings.Visibility.ADVANCED,
}

SettingViewportMaximum = Settings.overridable.number {
	id = "viewport.maximum",
	name = "Local viewport number",
	default = 4,
	minimum = 0,
	sliderMaximum = 16,
}

local buffers = {}
for i = 1, (SettingViewportMaximum or 1) do
	buffers[i] = Render.getBuffer(Render.Buffer.extend("F3D_Viewport" .. i, Enum.entry(17 + .01 * i, {
		transform = Render.Transform.Camera, -- Render.Transform.UI,
	})))
end
table.sort(Render.Buffer.valueList)

function F3DViewport.getBuffers()
	return buffers
end

ReloadScriptsToUpdateViewportBufferNumber = true
event.ecsSchemaReloaded.add("reloadScriptsToUpdateViewportBufferNumber", "snapshots", function()
	if ReloadScriptsToUpdateViewportBufferNumber then
		ReloadScriptsToUpdateViewportBufferNumber = false
		require "necro.config.i18n.Translation".reload()
	end
end)

local renderViewportSelectorFire = OrderedSelector.new(event.F3D_renderViewport, {
	"begin",
	"clippingRect",
	"transform",
	"overlay",
	"screenShake",
	"tiles",
	"floor",
	"wall",
	"objects",
	"particles",
	"worldLabels",
	"healthBars",
	"swipes",
	"flyaways",
	"end",
}).fire

--- @param ev Event.F3D_renderViewport
event.F3D_renderViewport.add("clippingRect", "clippingRect", function(ev)
	-- local w, h = GFX.getSize()
	-- local rect1 = w * ev.rect[1]
	-- local rect2 = h * ev.rect[2]
	-- local rect3 = w * (ev.rect[3] - ev.rect[1])
	-- local rect4 = h * (ev.rect[4] - ev.rect[2])
	-- ev.buffer.setClippingRect(rect1, rect2, rect3, rect4)
end)

--- @type integer
local vertexIndex = 0
--- @type VertexBuffer.AttributeMap
local vertices = {
	anim = {},
	x = {},
	y = {},
	z = {},
	color = {},
	tx = {},
	ty = {},
	zOrder = {},
}
local animList = vertices.anim
local colorList = vertices.color
local xList = vertices.x
local yList = vertices.y
local zList = vertices.z
local txList = vertices.tx
local tyList = vertices.ty
local zOrderList = vertices.zOrder

local function renderViewport(buffer, camera, localPlayerNumber, playerID, rect)
	local cameraX, cameraY, cameraZ = camera:getPosition()
	do
		local dx, dy, dz = camera:getDirection()
		local pitch, yaw, roll = camera:getRotation()
		local w, h = GFX.getSize()

		-- 相机矩阵
		local matView = F3DMatrix.new()
			:translate(cameraX, cameraY, cameraZ)
			:lookAt(cameraX, cameraY, cameraZ, dx, dy, dz,
				F3DMatrix.static():reset():rotate(pitch, yaw, roll)(F3DVector.up()))
			:scale(-1, 1, 1)

		-- 投影矩阵
		local matProjection = F3DMatrix.new()
			--	:orthogonal(.01, 1000, 0, 1920, 0, 1080)
			:perspective(
				.1,
				1000,
				camera[F3DCamera.Field.FieldOfView],
				camera[F3DCamera.Field.AspectRatio])

		-- 视口缩放矩阵
		local matCam = F3DMatrix.new()
			:scale(w / 2, h / 2, 1)
			:translate(w / 2 + 0, h / 2 + 10, 0)

		-- 结合后的矩阵
		local mat = F3DMatrix.new()
			:multiply(matCam)
			:multiply(matProjection)
			:multiply(matView)
		-- print(mat)

		buffer.setTransform(mat)
	end

	do
		local drawArgs = { rect = { 0, 0, 0, 0 } }
		local draw = buffer.draw
		for _ = 1, 2 ^ 12 do
			draw(drawArgs)
		end
	end
	vertexIndex = 0
	clearTable(animList)
	clearTable(colorList)
	clearTable(xList)
	clearTable(yList)
	clearTable(zList)
	clearTable(txList)
	clearTable(tyList)
	clearTable(zOrderList)

	--- @param x number
	--- @param y number
	--- @param z number
	--- @param w integer
	--- @param h integer
	--- @param t string
	--- @param tx integer
	--- @param ty integer
	--- @param tw integer
	--- @param th integer
	--- @param c Color
	--- @param a VertexAnimation.ID
	local function drawPlaneY(x, y, z, w, h, t, tx, ty, tw, th, c, a)
		local i1 = vertexIndex * 4 + 1
		local i2 = i1 + 1
		local i3 = i2 + 1
		local i4 = i3 + 1
		vertexIndex = vertexIndex + 1

		animList[vertexIndex] = a

		c = -1 --c or -1
		colorList[i1] = c
		colorList[i2] = c
		colorList[i3] = c
		colorList[i4] = c

		do
			local geom = getImageGeometry(t)
			local geomX = geom.x
			local geomY = geom.y

			txList[i1] = geomX + tx
			txList[i2] = geomX + tx + tw
			txList[i3] = geomX + tx
			txList[i4] = geomX + tx + tw

			tyList[i1] = geomY + ty
			tyList[i2] = geomY + ty
			tyList[i3] = geomY + ty + th
			tyList[i4] = geomY + ty + th
		end

		xList[i1] = x
		xList[i2] = x + w
		xList[i3] = x
		xList[i4] = x + w

		yList[i1] = y
		yList[i2] = y
		yList[i3] = y
		yList[i4] = y

		zList[i1] = z
		zList[i2] = z
		zList[i3] = z + h
		zList[i4] = z + h

		zOrderList[vertexIndex] = -vectorMagnitude(x + w * .5 - cameraX, y - cameraY, z + h * .5 - cameraZ)
	end

	--- @class Event.F3D_renderViewport
	--- @field buffer VertexBuffer
	--- @field camera F3DCamera
	--- @field rect Rectangle
	--- @field playerID Player.ID
	--- @field debugTimes? table
	local ev = {
		buffer = --Render.getBuffer(Render.Buffer.UI_BEAT_BARS),
			buffer,
		camera = camera,
		localPlayerNumber = localPlayerNumber,
		playerID = playerID,
		rect = rect,
		drawPlaneY = drawPlaneY,
	}
	renderViewportSelectorFire(ev)

	buffer.write(0, vertexIndex, vertices)
end

local animRects = {}

function F3DViewport.renderAll(rectangles)
	local list = {}

	for playerID, camera in Utilities.sortedPairs(F3DPlayerCamera.getAll()) do
		local number = LocalCoop.getCoopPlayerNumber(playerID)
		if number then
			list[#list + 1] = { number, camera, playerID }
		end
	end

	local rects = (rectangles or SettingViewportRectangles)[#list]
	if not rects then
		return
	end

	table.sort(list, function(l, r)
		return l[1] < r[1]
	end)

	for i, t in ipairs(list) do
		local buffer = Render.getBuffer(Render.Buffer.UI_BEAT_BARS) -- buffers[i]
		local rect = buffer and rects[i]
		if rect and type(rect[1]) == "number" and type(rect[2]) == "number" and type(rect[3]) == "number" and type(rect[4]) == "number" then
			renderViewport(buffer, t[2], i, t[3], rect)
		end
	end
end

event.renderUI.add("renderViewports", { order = "initializeBuffers", sequence = 1 }, function()
	if SettingViewportEnable then
		F3DViewport.renderAll()
	end
end)
