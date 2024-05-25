local F3DCamera = require "F3D.Camera"
local F3DViewport = {}

local Enum = require "system.utils.Enum"
local GFX = require "system.gfx.GFX"
local OrderedSelector = require "system.events.OrderedSelector"
local Render = require "necro.render.Render"
local Settings = require "necro.config.Settings"

local CameraFieldMinimumCullingDistance = F3DCamera.Field.MinimumCullingDistance
local CameraFieldPitch = F3DCamera.Field.Pitch
local CameraFieldPositionZ = F3DCamera.Field.PositionZ
local cameraTransformVector = F3DCamera.transformVector

F3DViewport.RenderBuffers = {
	Render.Buffer.extend("F3D_Viewport1", Enum.entry(17.1, { transform = Render.Transform.UI })),
	Render.Buffer.extend("F3D_Viewport2", Enum.entry(17.2, { transform = Render.Transform.UI })),
	Render.Buffer.extend("F3D_Viewport3", Enum.entry(17.3, { transform = Render.Transform.UI })),
	Render.Buffer.extend("F3D_Viewport4", Enum.entry(17.4, { transform = Render.Transform.UI })),
}
-- Sort the buffer value orders for properly rendering.
table.sort(Render.Buffer.valueList)

_G.SettingGroupViewport = Settings.overridable.group {
	id = "viewport",
	name = "Viewport",
	order = 100,
	visibility = Settings.Visibility.HIDDEN,
}

SettingViewportEnable = Settings.overridable.bool {
	id = "viewport.enable",
	name = "Enable",
	default = true,
}

SettingViewportSplits = Settings.overridable.table {
	id = "viewport.splits",
	name = "Splits screen",
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
}

--- @return boolean
function F3DViewport.isEnabled()
	return not not SettingViewportEnable
end

--- @class F3D.Viewport.Rect : Rectangle

--- Convert vector2 to viewport position.
--- Return nil if vector getting culled by camera.
--- @param camera F3D.Camera
--- @param rect F3D.Viewport.Rect
--- @param x number
--- @param y number
--- @return number? px @viewport screen x
--- @return number? py @viewport screen y
--- @return number? tx @transform x
--- @return number? ty @transform y
function F3DViewport.transformVector(camera, rect, x, y)
	x, y = cameraTransformVector(camera, x, y)
	if y > camera[CameraFieldMinimumCullingDistance] then
		return rect[1] + (1 + x / y) * rect[3] / 2,
			rect[2] + rect[4] / 2 + camera[CameraFieldPositionZ] * rect[4] / y + camera[CameraFieldPitch] * rect[4] / 2,
			x,
			y
	end
end

--- @param ev Event.F3D_renderViewport
event.F3D_renderViewport.add("bufferClippingRect", "clippingRect", function(ev)
	ev.buffer.setClippingRect(ev.rect[1], ev.rect[2], ev.rect[3], ev.rect[4])
end)

local renderViewportSelectorFire = OrderedSelector.new(event.F3D_renderViewport, {
	"begin",
	"clippingRect",
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

function F3DViewport.render(playerID, camera, buffer, rect)
	--- @class Event.F3D_renderViewport
	--- @field buffer VertexBuffer
	--- @field camera F3D.Camera
	--- @field playerID Player.ID
	--- @field rect { [1]: number, [2]: number, [3]: number, [4]: number }
	--- @field floorSampleX? number
	--- @field floorSampleY? number
	--- @field objectVisibilities? table<Entity.ID, boolean>
	--- @field wallSample? number
	--- @field debugTimes? table
	local ev = {
		buffer = buffer,
		camera = camera,
		playerID = playerID,
		rect = rect,
	}

	renderViewportSelectorFire(ev)
end

function F3DViewport.renderAll()
	local entries = {}
	for playerID, camera in pairs(F3DCamera.getAll()) do
		entries[#entries + 1] = {
			camera = camera,
			playerID = playerID,
		}
	end

	table.sort(entries, function(l, r)
		return l.playerID < r.playerID
	end)

	local splits = SettingViewportSplits[#entries] or SettingViewportSplits[#SettingViewportSplits]
	if type(splits) ~= "table" then
		return
	end

	local w, h = GFX.getSize()

	for index, entry in ipairs(entries) do
		local buffer = Render.getBuffer(F3DViewport.RenderBuffers[index])
		local split = buffer and splits[index]

		if type(split) == "table"
			and type(split[1]) == "number"
			and type(split[2]) == "number"
			and type(split[3]) == "number"
			and type(split[4]) == "number"
		then
			F3DViewport.render(entry.playerID, entry.camera, buffer, {
				w * split[1],
				h * split[2],
				w * (split[3] - split[1]),
				h * (split[4] - split[2]),
			})
		end
	end
end

event.render.add("renderViewports", "overlayFront", function()
	if SettingViewportEnable then
		F3DViewport.renderAll()
	end
end)

return F3DViewport
