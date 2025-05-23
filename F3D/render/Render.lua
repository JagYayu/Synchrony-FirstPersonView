local F3DCamera = require "F3D.necro3d.Camera"
local F3DFrustum = require "F3D.necro3d.Frustum"
local F3DMainCamera = require "F3D.camera.Main"
local F3DMatrix = require "F3D.necro3d.Matrix"
local F3DRender = {}
local F3DVector = require "F3D.necro3d.Vector"

local Enum = require "system.utils.Enum"
local GFX = require "system.gfx.GFX"
local LJBuffer = require "system.utils.serial.LJBuffer"
local OrderedSelector = require "system.events.OrderedSelector"
local Render = require "necro.render.Render"
local Settings = require "necro.config.Settings"
local Tick = require "necro.cycles.Tick"
local UI = require "necro.render.UI"
local Utilities = require "system.utils.Utilities"
local VertexBuffer = require "system.gfx.VertexBuffer"

local floor = math.floor
local invTS = 1 / Render.TILE_SIZE
local type = type

F3DRender.Buffer = Render.Buffer.extend("F3D_Buffer", Enum.entry(17.1, { transform = Render.Transform.NONE }))
table.sort(Render.Buffer.valueList)

local vertexAttributes = {
	[0] = 0,
	x = {},
	y = {},
	z = {},
	color = {},
	tx = {},
	ty = {},
	zOrder = {},
	anim = {},
}
--- @type F3DMatrix
local viewportMatrix
--- @type F3DMatrix
local projectionMatrix
--- @type F3DMatrix
local viewMatrix
--- @type F3DMatrix
local transformationMatrix
local frustum = F3DFrustum.new()
local ppu = 1

_G.GroupRender = Settings.overridable.group {
	id = "render",
	name = "Renderer",
	order = 500,
}
_G.SettingViewDistance = Settings.overridable.number {
	id = "render.viewDistance",
	name = "View distance",
	order = 501,
	default = 24,
	format = function(v)
		local t = v .. "m"
		if v > 50 then
			t = t .. " (low perf)"
		end
		return t
	end,
	sliderMinimum = 4,
	sliderMaximum = 50,
}
_G.SettingMinimumQuadCount = Settings.overridable.table {
	name = "Minimum quadrilateral count",
	order = 503,
	default = {},
	visibility = Settings.Visibility.HIDDEN,
}
_G.SettingPPU = Settings.overridable.number {
	id = "render.ppu",
	name = "Pixel per unit",
	order = 504,
	visibility = Settings.Visibility.ADVANCED,
	setter = function(v)
		ppu = v
		return ppu
	end,
	default = 24,
	sliderMaximum = 100,
	sliderMinimum = 1,
}

do
	LoadPPU = Tick.delay(function()
		ppu = SettingPPU
	end)
	LoadPPU()
end

F3DRender.ZOrder = Enum.immutable {
	Effect = .25,
	TextLabel = .24,
	HealthBar = .23,
	Attachment = .22,
	Character = .21,
	EffectBack = .20,
	Shadow = .05,
	TextGround = .04,
	Trapdoor = .03,
	Decal = .02,
	Wall = .01,
	Wire = -1.40,
	Floor = -1.41,
}
local a = math.sqrt(2)

function F3DRender.getViewportMatrix()
	return viewportMatrix
end

function F3DRender.getProjectionMatrix()
	return projectionMatrix
end

function F3DRender.getViewMatrix()
	return viewMatrix
end

function F3DRender.getTransformationMatrix()
	return transformationMatrix
end

function F3DRender.getFrustum()
	return frustum
end

--- @warn Do not modify the return table, for internal use only!
function F3DRender.getVertexAttributes()
	return vertexAttributes
end

function F3DRender.getPPU()
	return ppu
end

do -- F3DRender.getTextAttributes
	local et = Utilities.newTable(17, 0)
	local function encodeDrawArgs(p)
		et[01] = p.text or nil
		et[02] = p.alignX or nil
		et[03] = p.alignY or nil
		et[04] = p.size or nil
		et[05] = p.opacity or nil
		et[06] = p.fillColor or nil
		et[07] = p.outlineColor or nil
		et[08] = p.outlineThickness or nil
		et[09] = p.shadowColor or nil
		et[10] = p.spacingX or nil
		et[11] = p.spacingY or nil
		et[12] = p.maxWidth or nil
		et[13] = p.maxHeight or nil
		et[14] = p.wordWrap or nil
		et[15] = p.maxLines or nil
		et[16] = p.anim or nil
		et[17] = p.useCache or nil
		return LJBuffer.encode(et)
	end

	F3DRender.BufferTextTesting = VertexBuffer.new()

	local metatable = { __mode = "k" }
	local textVertAttributes = setmetatable({}, metatable)

	--- @warn: Parameter `font` should better be a reused table instead of a temporarily table, recommend passing `UI.Font.<string>`.
	--- @param drawArgs table
	--- @param font table?
	--- @return integer[] tx
	--- @return integer[] ty
	--- @return number[] x
	--- @return number[] y
	--- @return Color[] col
	function F3DRender.getTextAttributes(drawArgs, font)
		if type(font) ~= "table" then
			font = UI.Font.MEDIUM
		end

		local bufArgs = encodeDrawArgs(drawArgs)

		textVertAttributes[font] = textVertAttributes[font] or {}
		local va = textVertAttributes[font][bufArgs]
		if va == nil then
			local tva = {
				color = {},
				tx = {},
				ty = {},
				x = {},
				y = {},
				zOrder = {},
			}

			local buffer = F3DRender.BufferTextTesting

			drawArgs.buffer = buffer
			drawArgs.font = font
			drawArgs.x = 0
			drawArgs.y = 0
			UI.drawText(drawArgs)
			buffer.read(0, buffer.getQuadCount(), tva)

			local tx = {}
			local ty = {}
			local x = {}
			local y = {}
			local col = {}
			for i = 1, #tva.zOrder do
				local j = (i - 1) * 4
				col[#col + 1] = tva.color[j + 1]
				col[#col + 1] = tva.color[j + 2]
				col[#col + 1] = tva.color[j + 3]
				col[#col + 1] = tva.color[j + 4]
				tx[#tx + 1] = tva.tx[j + 1]
				tx[#tx + 1] = tva.tx[j + 2]
				tx[#tx + 1] = tva.tx[j + 3]
				tx[#tx + 1] = tva.tx[j + 4]
				ty[#ty + 1] = tva.ty[j + 1]
				ty[#ty + 1] = tva.ty[j + 2]
				ty[#ty + 1] = tva.ty[j + 3]
				ty[#ty + 1] = tva.ty[j + 4]
				x[#x + 1] = -tva.x[j + 1] * invTS
				x[#x + 1] = -tva.x[j + 2] * invTS
				x[#x + 1] = -tva.x[j + 3] * invTS
				x[#x + 1] = -tva.x[j + 4] * invTS
				y[#y + 1] = -tva.y[j + 1] * invTS
				y[#y + 1] = -tva.y[j + 2] * invTS
				y[#y + 1] = -tva.y[j + 3] * invTS
				y[#y + 1] = -tva.y[j + 4] * invTS
			end
			va = setmetatable({ tx, ty, x, y, col }, metatable)
			textVertAttributes[font][bufArgs] = va

			buffer.clear()
		end

		return va[1], va[2], va[3], va[4], va[5]
	end
end

--- @param tx integer
--- @param ty integer
--- @return number x
--- @return number z
function F3DRender.getTileCenter(tx, ty)
	return tx, -ty
end

function F3DRender.getTileAt(x, z)
	return floor(x + .5), floor(.5 - z)
end

local renderingMatricesSelectorFire = OrderedSelector.new(event.F3D_renderingMatrices, {
	"viewport",
	"screenShake",
	"projection",
	"view",
	"transformation",
	"frustum",
}).fire

event.F3D_renderingMatrices.add("viewport", "viewport", function(ev)
	local w, h = GFX.getSize()
	ev.viewportMatrix = F3DMatrix.new()
		:scale(-w / 2, -h / 2, 1)
		:translate(w / 2, h / 2, 0)
end)

event.F3D_renderingMatrices.add("projection", "projection", function(ev)
	local camera = F3DMainCamera.getCurrent()
	ev.projectionMatrix = ev.projectionMatrix:perspective(
		camera[F3DCamera.Field.Near],
		camera[F3DCamera.Field.Far],
		camera[F3DCamera.Field.FieldOfView],
		camera[F3DCamera.Field.AspectRatio])
end)

event.F3D_renderingMatrices.add("view", "view", function(ev)
	local camera = F3DMainCamera.getCurrent()
	local cameraX = camera[F3DCamera.Field.X] * ppu
	local cameraY = camera[F3DCamera.Field.Y] * ppu
	local cameraZ = camera[F3DCamera.Field.Z] * ppu
	local dx, dy, dz = camera:getDirection()
	local pitch, yaw, roll = camera:getRotation()
	ev.viewMatrix = ev.viewMatrix
		:lookAt(cameraX, cameraY, cameraZ, dx, dy, dz, F3DMatrix.static():reset():rotate(pitch, yaw, roll)(F3DVector.up()))
		:scale(-1, 1, 1)
end)

event.F3D_renderingMatrices.add("transformation", "transformation", function(ev)
	ev.transformationMatrix = ev.transformationMatrix
		:multiply(ev.viewportMatrix)
		:multiply(ev.projectionMatrix)
		:multiply(ev.viewMatrix)
end)

event.F3D_renderingMatrices.add("frustum", "frustum", function(ev)
	if frustum then
		frustum:set(F3DMatrix.new():multiply(ev.projectionMatrix):multiply(ev.viewMatrix):scale(-ppu, ppu, ppu))
	end
end)

event.renderUI.add("updateRenderingParameters", {
	order = "initializeBuffers",
	sequence = 1,
}, function()
	local ev = {
		viewportMatrix = F3DMatrix.new(),
		projectionMatrix = F3DMatrix.new(),
		viewMatrix = F3DMatrix.new(),
		transformationMatrix = F3DMatrix.new(),
	}
	renderingMatricesSelectorFire(ev)
	viewportMatrix = ev.viewportMatrix
	projectionMatrix = ev.projectionMatrix
	viewMatrix = ev.viewMatrix
	transformationMatrix = ev.transformationMatrix
end)

local expectedQuadCount = 1024

event.tick.add("updateExpectedQuadCount", "renderPartial", function()
	local prev = vertexAttributes[0]

	if expectedQuadCount < prev * .25 then
		expectedQuadCount = math.floor(prev * .5)
	else
		expectedQuadCount = math.max(expectedQuadCount, prev)
	end
end)

event.renderUI.add("initializeRenderBuffers", {
	order = "initializeBuffers",
	sequence = 2,
}, function()
	local buffer = Render.getBuffer(F3DRender.Buffer)

	buffer.clear()
	buffer.setTransform(transformationMatrix)

	local draw = buffer.draw
	local drawArgs = { rect = { 0, 0, 0, 0 } }
	for _ = 1, expectedQuadCount do
		draw(drawArgs)
	end

	vertexAttributes[0] = 0
	Utilities.clearTable(vertexAttributes.anim)
	Utilities.clearTable(vertexAttributes.color)
	Utilities.clearTable(vertexAttributes.x)
	Utilities.clearTable(vertexAttributes.y)
	Utilities.clearTable(vertexAttributes.z)
	Utilities.clearTable(vertexAttributes.tx)
	Utilities.clearTable(vertexAttributes.ty)
	Utilities.clearTable(vertexAttributes.zOrder)
end)

event.renderUI.add("finalizeRenderBuffers", {
	order = "finalizeBuffers",
	sequence = -1,
}, function()
	Render.getBuffer(F3DRender.Buffer).write(0, vertexAttributes[0], vertexAttributes)
end)

return F3DRender
