local F3DCamera = require "F3D.Camera"
local F3DWallRenderer = {}
local F3DUtility = require "F3D.Utility"

local AnimationTimer = require "necro.render.AnimationTimer"
local Color = require "system.utils.Color"
local OrderedSelector = require "system.events.OrderedSelector"
local Random = require "system.utils.Random"
local RenderTimestep = require "necro.render.RenderTimestep"
local Settings = require "necro.config.Settings"
local Tile = require "necro.game.tile.Tile"
local TileTypes = require "necro.game.tile.TileTypes"
local Utilities = require "system.utils.Utilities"
local VertexAnimation = require "system.gfx.VertexAnimation"

local abs = math.abs
local getTileBrightnessFactorCached = F3DUtility.getTileBrightnessFactorCached
local getTileID = Tile.get
local getTileInfo = Tile.getInfo
local floor = math.floor
local gray = Color.gray
local lineLineIntersect = F3DUtility.lineLineIntersect
local noise3 = Random.noise3
local reduceCoordinates = Tile.reduceCoordinates
local sqrt = math.sqrt
local squareDistance = Utilities.squareDistance
local threshold3 = Random.threshold3
local type = type

_G.SettingGroupWall = Settings.overridable.group {
	id = "render.wall",
	name = "Wall renderer",
	order = 101,
}

SettingWallSample = Settings.overridable.percent {
	id = "render.wall.sample",
	name = "Sample factor",
	default = 1,
}

SettingWallGrayNS = Settings.overridable.percent {
	id = "render.wall.grayNS",
	name = "NS wall gray factor",
	default = .7,
}

SettingWallGrayEW = Settings.overridable.percent {
	id = "render.wall.grayEW",
	name = "NS wall gray factor",
	default = 1,
}

SettingWallClearCacheInterval = Settings.overridable.number {
	id = "render.wall.clearCacheInterval",
	name = "Clear visual cache interval",
	default = .1,
	step = .05,
	smoothStep = .01,
	minimum = 0,
	sliderMaximum = 1,
	format = function(value)
		return tostring(value * 100) .. "ms"
	end,
}

local wallVisuals = {}

local function generateWallVisualTable(wall)
	local textures = wall.F3D_wall or wall.texture
	if type(textures) == "string" then
		textures = { textures }
	elseif type(textures) ~= "table" then
		return
	end

	local variants = {}
	local variations = wall.variations or {}
	local commonCount = variations.commonCount or 1
	local rareCount = variations.rareCount or 0
	local rareFrequency = variations.rareFrequency or 0

	for variant = 0, commonCount + rareCount - 1 do
		local size = wall.size or { 24, 24 }
		local shift = wall.shift or { 0, 0 }
		local varShift = (variations.shift or 24) * variant

		variants[variant + 1] = {
			width = size[1],
			height = size[2],
			shiftX = shift[1] + varShift,
			shiftY = shift[2],
		}
	end

	return {
		commonCount = commonCount,
		rareCount = rareCount,
		rareFrequency = rareFrequency,
		variants = variants,
		textures = textures,
		wallHeight = wall.F3D_wallHeight or 1,
	}
end

event.tileSchemaUpdate.add("createWallVisuals3D", "visuals", function()
	wallVisuals = {}

	for id = 1, TileTypes.getMaximumTileID() do
		wallVisuals[id] = generateWallVisualTable(TileTypes.getTileInfo(id))
	end
end)

loadWallVisualSelectorFire = OrderedSelector.new(event.F3D_loadWallVisual, {
	"load",
}).fire

--- @param ev Event.F3D_loadWallVisual
event.F3D_loadWallVisual.add("load", "load", function(ev)
	local x = ev.x
	local y = ev.y
	local visual = wallVisuals[getTileID(x, y)]
	if visual then
		local seed = F3DUtility.getTileVisualSeed()
		local rarity = threshold3(x, y, seed, 1 - visual.rareFrequency)
		local variantCount = (1 - rarity) * visual.commonCount + rarity * visual.rareCount
		local variantOffset = rarity * visual.commonCount
		local variant = visual.variants[variantOffset + noise3(x, y, seed, variantCount) + 1]

		ev.texture = visual.textures[noise3(x, y, seed, #visual.textures) + 1]
		ev.textureShiftX = variant.shiftX
		ev.spriteWidth = variant.width
		ev.spriteHeight = variant.height
		ev.wallHeight = visual.wallHeight
	end
end)

--- @param x integer
--- @param y integer
--- @param side boolean
--- @return string? texture
--- @return number textureShiftX
--- @return number textureWidth
--- @return number textureHeight
--- @return number height
function F3DWallRenderer.loadWallVisual(x, y, side)
	--- @class Event.F3D_loadWallVisual
	--- @field x integer
	--- @field y integer
	--- @field side boolean
	--- @field info Tile.Info
	--- @field texture string?
	--- @field textureShiftX number
	--- @field spriteWidth number
	--- @field spriteHeight number
	--- @field wallHeight number
	local ev = {
		x = x,
		y = y,
		side = side,
		info = getTileInfo(x, y),
		texture = nil,
		textureShiftX = 0,
		spriteWidth = 24,
		spriteHeight = 24,
		wallHeight = 1,
	}
	loadWallVisualSelectorFire(ev)
	return ev.texture, ev.textureShiftX, ev.spriteWidth, ev.spriteHeight, ev.wallHeight
end

local loadWallVisual = F3DWallRenderer.loadWallVisual

local wallVisualNSCache = {}
local wallVisualWECache = {}
function F3DWallRenderer.loadWallVisualCached(x, y, side)
	local i = reduceCoordinates(x, y)
	if i then
		local cache = side and wallVisualNSCache or wallVisualWECache
		if cache[i] == nil then
			cache[i] = { loadWallVisual(x, y, side) }
		end

		return unpack(cache[i], 1, 5)
	end
end

local loadWallVisualCached = F3DWallRenderer.loadWallVisualCached

local clearCacheInterval = 0
event.render.add("clearWallVisualsCache", "endLegacyGraphics", function()
	clearCacheInterval = clearCacheInterval + RenderTimestep.getDeltaTime()
	if clearCacheInterval > SettingWallClearCacheInterval then
		clearCacheInterval = 0
		wallVisualNSCache = {}
		wallVisualWECache = {}
	end
end)

event.F3D_renderViewport.add("renderWalls", {
	order = "wall",
	sequence = 1,
}, function(ev) --- @param ev Event.F3D_renderViewport
	local sampleStep = 1 / (ev.wallSample or SettingWallSample)

	local cameraX = ev.camera[F3DCamera.Field.PositionX]
	local cameraY = ev.camera[F3DCamera.Field.PositionY]
	local cameraZ = ev.camera[F3DCamera.Field.PositionZ]
	local cameraDirX = ev.camera[F3DCamera.Field.DirectionX]
	local cameraDirY = ev.camera[F3DCamera.Field.DirectionY]
	local cameraPlaneX = ev.camera[F3DCamera.Field.PlaneX]
	local cameraPlaneY = ev.camera[F3DCamera.Field.PlaneY]
	local cameraPitch = ev.camera[F3DCamera.Field.Pitch]
	local cameraViewSquareDistance = ev.camera[F3DCamera.Field.ViewSquareDistance]

	local viewDistance = sqrt(cameraViewSquareDistance)

	local viewportX = ev.rect[1]
	local viewportY = ev.rect[2]
	local viewportWidth = ev.rect[3]
	local viewportHeight = ev.rect[4]

	local raycastResult = {}
	local function raycastResultAdd(tileX, tileY, side, sideDistX, sideDistY, deltaDistX, deltaDistY, rayDirX, rayDirY)
		local perpDistance, texSampleX
		if side then
			perpDistance = sideDistY - deltaDistY
			texSampleX = cameraX + perpDistance * rayDirX
		else
			perpDistance = sideDistX - deltaDistX
			texSampleX = cameraY + perpDistance * rayDirY
		end

		local i = #raycastResult
		raycastResult[i + 1] = tileX
		raycastResult[i + 2] = tileY
		raycastResult[i + 3] = side
		raycastResult[i + 4] = perpDistance
		raycastResult[i + 5] = texSampleX - floor(texSampleX)
	end

	local function raycast(x)
		Utilities.clearTable(raycastResult)

		local rayDirX = cameraDirX + cameraPlaneX * (2 * x / viewportWidth - 1);
		local rayDirY = cameraDirY + cameraPlaneY * (2 * x / viewportWidth - 1);
		local tileX = floor(cameraX)
		local tileY = floor(cameraY)
		local sideDistX
		local sideDistY
		local deltaDistX = (rayDirX == 0) and 1e9 or abs(1 / rayDirX)
		local deltaDistY = (rayDirY == 0) and 1e9 or abs(1 / rayDirY)
		local stepX
		local stepY

		if rayDirX < 0 then
			stepX = -1
			sideDistX = (cameraX - tileX) * deltaDistX
		else
			stepX = 1
			sideDistX = (tileX + 1 - cameraX) * deltaDistX
		end
		if rayDirY < 0 then
			stepY = -1
			sideDistY = (cameraY - tileY) * deltaDistY
		else
			stepY = 1
			sideDistY = (tileY + 1 - cameraY) * deltaDistY
		end

		local side = false -- hit NS(horizontal) or EW(vertical)
		while sideDistX < viewDistance or sideDistY < viewDistance do
			if sideDistX < sideDistY then
				sideDistX = sideDistX + deltaDistX
				tileX = tileX + stepX
				side = false
			else
				sideDistY = sideDistY + deltaDistY
				tileY = tileY + stepY
				side = true
			end

			local info = getTileInfo(tileX, tileY)
			if info.F3D_thinWall ~= nil then
				if info.F3D_thinWall then
					local t = lineLineIntersect(tileX, tileY + .5, tileX + 1, tileY + .5,
						cameraX, cameraY, cameraX + rayDirX, cameraY + rayDirY)
					if t >= 0 and t <= 1 then
						sideDistY = sideDistY + deltaDistY * .5
						side = true

						raycastResultAdd(tileX, tileY, side,
							sideDistX, sideDistY, deltaDistX, deltaDistY, rayDirX, rayDirY)

						if not info.F3D_transparent then
							break
						end
					end
				else
					local t = lineLineIntersect(tileX + .5, tileY, tileX + .5, tileY + 1,
						cameraX, cameraY, cameraX + rayDirX, cameraY + rayDirY)
					if t >= 0 and t <= 1 then
						sideDistX = sideDistX + deltaDistX * .5
						side = false

						raycastResultAdd(tileX, tileY, side,
							sideDistX, sideDistY, deltaDistX, deltaDistY, rayDirX, rayDirY)

						if not info.F3D_transparent then
							break
						end
					end
				end
			elseif info.isWall then
				raycastResultAdd(tileX, tileY, side,
					sideDistX, sideDistY, deltaDistX, deltaDistY, rayDirX, rayDirY)

				if not info.F3D_transparent then
					break
				end
			end
		end
	end

	local drawArgs = {
		color = -1,
		rect = { 0, 0, 0, 0 },
		texRect = { 0, 0, 0, 0 },
		texture = "",
		z = 0,
	}
	local drawArgsRect = drawArgs.rect
	local drawArgsTexRect = drawArgs.texRect
	local grayNS = SettingWallGrayNS
	local grayEW = SettingWallGrayEW

	local draw = ev.buffer.draw
	for px = viewportX, viewportX + viewportWidth, sampleStep do
		raycast(px)

		for i = 0, #raycastResult - 5, 5 do
			local tileX = raycastResult[i + 1]
			local tileY = raycastResult[i + 2]
			local side = raycastResult[i + 3]
			local perpDistance = raycastResult[i + 4]
			local texSampleX = raycastResult[i + 5]
			local texture, textureShiftX, spriteWidth, spriteHeight, height = loadWallVisualCached(tileX, tileY, side)
			local brightnessFactor = texture and getTileBrightnessFactorCached(tileX, tileY)
			if brightnessFactor then
				local wallHeight = viewportHeight * height
				local lineHeight = wallHeight / perpDistance
				local projectedHeight = viewportHeight / perpDistance

				drawArgs.texture = texture
				drawArgs.color = gray(brightnessFactor * (side and grayNS or grayEW))

				drawArgsRect[1] = px
				drawArgsRect[2] = viewportY - (wallHeight / projectedHeight) / 2
					+ cameraZ * projectedHeight
					+ cameraPitch * viewportHeight / 2
					+ viewportHeight
					- viewportHeight / 2 * (1 - height)
					- wallHeight / 2
					- lineHeight
				drawArgsRect[3] = sampleStep
				drawArgsRect[4] = lineHeight

				drawArgsTexRect[1] = textureShiftX + floor(spriteWidth * texSampleX)
				drawArgsTexRect[2] = 0
				drawArgsTexRect[3] = 1
				drawArgsTexRect[4] = spriteHeight

				drawArgs.z = -sqrt(squareDistance(tileX + 0.5 - cameraX, tileY + 0.5 - cameraY))

				draw(drawArgs)
			end
		end
	end
end)

wallVisuals = script.persist(function()
	return wallVisuals
end)
