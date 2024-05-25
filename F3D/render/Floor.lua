local F3DCamera = require "F3D.Camera"
local F3DFloorRenderer = {}
local F3DUtility = require "F3D.Utility"

local Array = require "system.utils.Array"
local Color = require "system.utils.Color"
local EnumSelector = require "system.events.EnumSelector"
local ObjectMap = require "necro.game.object.Map"
local OrderedSelector = require "system.events.OrderedSelector"
local RenderTimestep = require "necro.render.RenderTimestep"
local Settings = require "necro.config.Settings"
local Tile = require "necro.game.tile.Tile"
local TileRenderer = require "necro.render.level.TileRenderer"
local UI = require "necro.render.UI"
local Utilities = require "system.utils.Utilities"

local fade = Color.fade
local floor = math.floor
local getBitmapPixel = F3DUtility.getBitmapPixel
local getTileBrightnessFactorCached = F3DUtility.getTileBrightnessFactorCached
local max = math.max
local reduceCoordinates = Tile.reduceCoordinates
local type = type

_G.SettingGroupFloor = Settings.overridable.group {
	id = "render.floor",
	name = "Floor renderer",
	order = 102,
}

SettingFloorSampleX = Settings.overridable.percent {
	id = "render.floor.sampleX",
	name = "Sample x",
	default = .25,
}

SettingFloorSampleY = Settings.overridable.percent {
	id = "render.floor.sampleY",
	name = "Sample y",
	default = .5,
}

SettingFloorFallbackRenderer = Settings.overridable.choice {
	id = "render.floor.fallback",
	name = "Fallback renderer",
	default = 0,
	choices = {
		{
			name = "Disable",
			value = 0,
		},
		{
			name = "Enable",
			value = 1,
		},
		{
			name = "Force enable",
			value = 2,
		},
	}
}

SettingFloorClearCacheInterval = Settings.overridable.number {
	id = "render.floor.clearCacheInterval",
	name = "Clear texture cache interval",
	default = .1,
	step = .05,
	smoothStep = .01,
	minimum = 0,
	sliderMaximum = 1,
	format = function(value)
		return tostring(value * 100) .. "ms"
	end,
}

local loadFloorTextureSelectorFire = OrderedSelector.new(event.F3D_loadFloorTexture, {
	"load",
	"named",
	"cover",
}).fire

local function loadCustomFloorTexture(ev)
	local arg = ev.info.F3D_customFloor
	if type(ev.info.F3D_customFloor) ~= "table" then
		return
	end

	-- TODO
	for i = 1, #arg do
		-- local entry = shiftTable[i]
		--
		-- if checkFloorShiftEntry(variant, entry.vision, fvVision) and checkFloorShiftEntry(variant, entry.disco, fvGrooveChain) and checkFloorShiftEntry(variant, entry.beat, fvBeatParity) and checkFloorShiftEntry(variant, entry.position, fvPositionParity) then
		-- 	local shift = entry.shift or {}
		--
		-- 	return shift[1] or 0, shift[2] or 0
		-- end
	end
end

local function loadDanceFloorTexture(ev)
	-- F3D_floor
	-- true: use `tileInfo.texture`
	-- 'string': use `string` texture
	-- 'table': ...
	local arg = ev.info.F3D_floor
	if arg == true then
		return ev.info.texture
	elseif type(arg) == "string" then
		return arg
	elseif type(arg) ~= "table" then
		return
	end

	if type(arg) == "string" then
		return arg
	elseif type(arg) == "table" then
		local beat = TileRenderer.getCurrentBeat() % 2 == 0
		local pos = (ev.x + ev.y) % 2 == 1

		if TileRenderer.isGrooveChainActive() then
			if pos then
				return arg[beat and 5 or 4]
			else
				return arg[beat and 1 or 6]
			end
		else
			if pos then
				return arg[beat and 3 or 1]
			else
				return arg[beat and 4 or 2]
			end
		end
	end
end

event.F3D_loadFloorTexture.add("load", "load", function(ev)
	ev.texture = loadCustomFloorTexture(ev) or loadDanceFloorTexture(ev)
end)

event.F3D_loadFloorTexture.add("cover", "cover", function(ev)
	if not ev.texture or ev.info.F3D_floorUncoverable then
		return
	end

	-- for _, entity in ipairs(ObjectMap.allWithComponent(ev.x, ev.y, "F3D_spriteCoverFloor")) do
	--	entity.F3D_spriteCoverFloor.texture
	-- end
end)

local loadNamedFloorTextureSelectorFire = EnumSelector.new(event.F3D_loadNamedFloorTexture).fire

event.F3D_loadFloorTexture.add("named", "named", function(ev)
	loadNamedFloorTextureSelectorFire(ev, ev.info.name)
end)

function F3DFloorRenderer.loadFloorTexture(x, y)
	--- @class Event.F3D_loadFloorTexture
	--- @field info Tile.Info
	--- @field x integer
	--- @field y integer
	--- @field texture string?
	local ev = {
		info = Tile.getInfo(x, y),
		x = x,
		y = y,
		texture = nil,
	}
	loadFloorTextureSelectorFire(ev)
	return ev.texture
end

local floorTexturesCache = {}

function F3DFloorRenderer.getFloorTextureCached(x, y)
	local i = reduceCoordinates(x, y)
	if i then
		if floorTexturesCache[i] == nil then
			floorTexturesCache[i] = F3DFloorRenderer.loadFloorTexture(x, y) or false
		end

		return floorTexturesCache[i]
	end
end

local getFloorTextureCached = F3DFloorRenderer.getFloorTextureCached

local clearCacheInterval = 0
event.render.add("clearFloorTexturesCache", "endLegacyGraphics", function()
	clearCacheInterval = clearCacheInterval + RenderTimestep.getDeltaTime()
	if clearCacheInterval > SettingFloorClearCacheInterval then
		clearCacheInterval = 0
		floorTexturesCache = {}
	end
end)

function F3DFloorRenderer.render(camera, buffer, rect, framebuffer, pixelArray, frameWidth, frameHeight)
	if not framebuffer.isValid() then
		return
	end

	local cameraX = camera[F3DCamera.Field.PositionX]
	local cameraY = camera[F3DCamera.Field.PositionY]
	local cameraZ = camera[F3DCamera.Field.PositionZ]
	local cameraDirX = camera[F3DCamera.Field.DirectionX]
	local cameraDirY = camera[F3DCamera.Field.DirectionY]
	local cameraPlaneX = camera[F3DCamera.Field.PlaneX]
	local cameraPlaneY = camera[F3DCamera.Field.PlaneY]
	local cameraPitch = camera[F3DCamera.Field.Pitch]

	for py = frameHeight - 1, max(0, frameHeight / 2 + cameraPitch * frameHeight / 2), -1 do
		local rayDirX = cameraDirX - cameraPlaneX
		local rayDirY = cameraDirY - cameraPlaneY

		local rowDistance
		do
			local z = cameraZ * frameHeight
			local p = py - (cameraPitch + 1) * frameHeight / 2
			rowDistance = z / p
		end

		local stepX = rowDistance * (cameraDirX + cameraPlaneX - rayDirX) / frameWidth
		local stepY = rowDistance * (cameraDirY + cameraPlaneY - rayDirY) / frameWidth

		local rayX = cameraX + rowDistance * rayDirX
		local rayY = cameraY + rowDistance * rayDirY

		local pixelOffset = py * frameWidth
		for px = 0, frameWidth - 1 do
			local texture = getFloorTextureCached(floor(rayX), floor(rayY))
			if texture then
				local color = getBitmapPixel(texture, rayX - floor(rayX), rayY - floor(rayY))
				if color then
					local factor = getTileBrightnessFactorCached(floor(rayX), floor(rayY))
					if factor == 1 then
						pixelArray[pixelOffset + px] = color
					elseif factor ~= 0 then
						pixelArray[pixelOffset + px] = fade(color, factor)
					else
						pixelArray[pixelOffset + px] = 0
					end
				else
					pixelArray[pixelOffset + px] = 0
				end
			else
				pixelArray[pixelOffset + px] = 0
			end

			rayX = rayX + stepX
			rayY = rayY + stepY
		end
	end

	if framebuffer.update(pixelArray, 0, 0, frameWidth, frameHeight) then
		buffer.draw {
			texture = framebuffer,
			texRect = { 0, 0, frameWidth, frameHeight },
			rect = rect,
			z = -1e9,
		}

		return true
	end

	return false
end

function F3DFloorRenderer.renderFallback(camera, buffer, rect, floorSampleX, floorSampleY)
end

FloorBuffers = {}

local presentFramebuffer, Framebuffer = pcall(require, "system.game.Framebuffer")
FramebufferWarned = false

--- @param ev Event.F3D_renderViewport
event.F3D_renderViewport.add("renderFloors", "floor", function(ev)
	local floorSampleX = ev.floorSampleX or SettingFloorSampleX
	local floorSampleY = ev.floorSampleY or SettingFloorSampleY

	if SettingFloorFallbackRenderer == 2 then
		F3DFloorRenderer.renderFallback(ev.camera, ev.buffer, ev.rect, floorSampleX, floorSampleY)
	elseif presentFramebuffer then
		local frameWidth = floor(ev.rect[3] * floorSampleX)
		local frameHeight = floor(ev.rect[4] * floorSampleY)
		local floorBuffer = FloorBuffers[ev.camera]

		if not floorBuffer then
			floorBuffer = {
				framebuffer = Framebuffer.new(frameWidth, frameHeight),
				pixelArray = Array.new(Array.Type.UINT32, frameWidth * frameHeight),
				width = frameWidth,
				height = frameHeight,
			}
			FloorBuffers[ev.camera] = floorBuffer
		end

		if floorBuffer.width ~= frameWidth or floorBuffer.height ~= frameHeight then
			floorBuffer.width = frameWidth
			floorBuffer.height = frameHeight
			floorBuffer.framebuffer.resize(frameWidth, frameHeight)
			floorBuffer.pixelArray = Array.new(Array.Type.UINT32, frameWidth * frameHeight)
		end

		if not F3DFloorRenderer.render(ev.camera, ev.buffer, ev.rect,
				floorBuffer.framebuffer, floorBuffer.pixelArray, frameWidth, frameHeight) then
			if not FramebufferWarned then
				FramebufferWarned = true
				local warning = "Framebuffer invalid or update failed, pending to recreate a new one!"
				log.warn(warning)
				print(warning)
			end

			FloorBuffers[ev.camera] = nil
		end
	elseif SettingFloorFallbackRenderer == 1 then
		F3DFloorRenderer.renderFallback(ev.camera, ev.buffer, ev.rect, floorSampleX, floorSampleY)
	elseif not presentFramebuffer and type(Framebuffer) == "string" then
		UI.drawText {
			text = Framebuffer,
			font = UI.Font.LARGE,
			fillColor = Color.RED,
			outlineColor = Color.BLACK,
			alignX = .5,
			alignY = .5,
			x = ev.rect[1] + ev.rect[3] * .5,
			y = ev.rect[2] + ev.rect[4] * .75,
		}
	end
end)

return F3DFloorRenderer
