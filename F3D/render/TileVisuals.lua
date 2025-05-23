local F3DQuadsRenderer = require "F3D.render.QuadsRenderer"
local F3DTileVisuals = {}
local F3DUtilities = require "F3D.system.Utilities"

local AnimationTimer = require "necro.render.AnimationTimer"
local FloorVisuals = require "necro.render.level.FloorVisuals"
local Random = require "system.utils.Random"
local Render = require "necro.render.Render"
local Tile = require "necro.game.tile.Tile"
local TileTypes = require "necro.game.tile.TileTypes"

local emptyTable = F3DUtilities.emptyTable
local getFloorSprite = FloorVisuals.getFloorSprite
local getFloorTexture = FloorVisuals.getTexture
local getTileID = Tile.get
local invTileSize = 1 / Render.TILE_SIZE
local mathRandom = math.random
local randomNoise3 = Random.noise3
local reduceCoordinates = Tile.reduceCoordinates
local tileCenter = Render.tileCenter
local tileSize = Render.TILE_SIZE

local seed = 0
local tileAnimationTimes = {}

event.gameStateLevel.add("tileVisuals", "tileVisuals", function(ev)
	seed = ev.tileVisualsSeed or 0
	tileAnimationTimes = {}
end)
event.tileMapSizeChange.add("tileVisuals", "tileVisuals", function(ev)
	tileAnimationTimes = {}
end)

do
	local function getRandomAnimationFrame(x, y, params)
		local index = reduceCoordinates(x, y) or 0
		local time = AnimationTimer.getTime()
		local factor = (time - (tileAnimationTimes[index] or 0)) / params.duration

		if params.numFrames <= factor then
			tileAnimationTimes[index] = time + mathRandom(params.minInterval, params.maxInterval)

			return 0
		end

		return math.max(0, math.floor(factor))
	end

	--- @param tx integer
	--- @param ty integer
	--- @param beat integer
	--- @param visible boolean
	--- @param grooveChain boolean
	--- @return integer? x
	--- @return integer z
	--- @return integer w
	--- @return integer h
	--- @return string tex
	--- @return integer texX
	--- @return integer texY
	--- @return integer texW
	--- @return integer texH
	function F3DTileVisuals.getFloorVisual(tx, ty, info, beat, visible, grooveChain)
		local cx, cy = tileCenter(tx - .5, ty - .5)
		local id = getTileID(tx, ty)
		local sprite = getFloorSprite(id, tx, ty, beat, visible, grooveChain)
		if sprite then
			local x = (cx + sprite.offsetX - tileSize) * invTileSize
			local z = -(cy + sprite.offsetY) * invTileSize
			local w = sprite.width * invTileSize
			local h = sprite.height * invTileSize
			local tex = getFloorTexture(id, tx, ty)
			local texX = sprite.shiftX
			local texY = sprite.shiftY
			local texW = sprite.width
			local texH = sprite.height

			local randomAnimation = info.randomAnimation
			if randomAnimation then
				local frame = getRandomAnimationFrame(x, z, randomAnimation)
				texX = texX + randomAnimation.shift[1] * frame
				texY = texY + randomAnimation.shift[2] * frame
			end

			return x, z, w, h, tex, texX, texY, texW, texH
		end
		return nil, 0, 0, 0, "", 0, 0, 0, 0
	end
end

do
	local wallStaticVisuals = {}
	local fallbackFrameTexRects = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

	--- @param tx integer
	--- @param ty integer
	--- @return integer? x world x
	--- @return integer z world z
	--- @return integer l wall length
	--- @return integer w wall width
	--- @return integer h wall height
	--- @return string t wall texture
	--- @return integer tx1
	--- @return integer ty1
	--- @return integer tw1
	--- @return integer th1
	--- @return integer tx2
	--- @return integer ty2
	--- @return integer tw2
	--- @return integer th2
	--- @return integer tx3
	--- @return integer ty3
	--- @return integer tw3
	--- @return integer th3
	function F3DTileVisuals.getWallVisual(tx, ty)
		local staticVisual = wallStaticVisuals[getTileID(tx, ty)]
		if not staticVisual then
			return nil, 0, 0, 0, 0, "", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		end

		local frameID = staticVisual[2][randomNoise3(tx, ty, seed, staticVisual[1]) + 1]
		if staticVisual[4] then
			local randomAnimation = staticVisual[4]
			local index = reduceCoordinates(tx, ty) or 0
			local time = AnimationTimer.getTime()
			local factor = (time - (tileAnimationTimes[index] or 0)) * randomAnimation[1]
			local toFrameIndex
			local animFrameIDs = randomAnimation[4][frameID] or emptyTable
			if factor > #animFrameIDs + 1 then
				tileAnimationTimes[index] = time + mathRandom(randomAnimation[3], randomAnimation[2])
			else
				toFrameIndex = math.max(0, math.floor(factor))
			end
			frameID = toFrameIndex and animFrameIDs[toFrameIndex] or frameID
		end

		local x, y = tileCenter(tx - .5, ty - .5)
		x = x * invTileSize
		y = y * invTileSize
		local l = staticVisual[5]
		local w = staticVisual[6]
		local texRects = staticVisual[3][frameID] or fallbackFrameTexRects
		return x + ((1 - l) * .5), -(y + 1) + (1 - w) * .5,
			l, w, staticVisual[7], staticVisual[8],
			texRects[1], texRects[2], texRects[3], texRects[4],
			texRects[5], texRects[6], texRects[7], texRects[8],
			texRects[9], texRects[10], texRects[11], texRects[12]
	end

	event.tileSchemaUpdate.add("createWallVisuals", "visuals", function()
		wallStaticVisuals = {}

		for id = 1, TileTypes.getMaximumTileID() do
			local info = TileTypes.getTileInfo(id)
			if not info.F3D_wall or type(info.F3D_sprites) ~= "table" then
				wallStaticVisuals[id] = false
				goto continue
			end

			local frameList = {}
			for frameID, weight in pairs(type(info.F3D_frames) == "table" and info.F3D_frames or { tonumber(info.F3D_frames) or 1 }) do
				for _ = 1, math.min(weight, 1e3) do
					frameList[#frameList + 1] = frameID
				end
			end

			local frame2Rects = {}
			for frameID, sprites in pairs(info.F3D_sprites) do
				local t1 = type(sprites.top) == "table" and sprites.top or emptyTable
				local t2 = type(sprites.front) == "table" and sprites.front or emptyTable
				local t3 = type(sprites.left) == "table" and sprites.left or emptyTable
				frame2Rects[frameID] = {
					tonumber(t1.x) or 0, tonumber(t1.y) or 0, tonumber(t1.width) or 0, tonumber(t1.height) or 0,
					tonumber(t2.x) or 0, tonumber(t2.y) or 0, tonumber(t2.width) or 0, tonumber(t2.height) or 0,
					tonumber(t3.x) or 0, tonumber(t3.y) or 0, tonumber(t3.width) or 0, tonumber(t3.height) or 0,
				}
			end

			local randomAnimation
			if type(info.F3D_randomAnimation) == "table" then
				local animFrameIDsMap = {}
				for frameID, animFrameIDs in pairs(info.F3D_randomAnimation.frames or {}) do
					animFrameIDsMap[frameID] = animFrameIDs
				end
				randomAnimation = {
					1 / (tonumber(info.F3D_randomAnimation.duration) or .5),
					tonumber(info.F3D_randomAnimation.maxInterval) or .35,
					tonumber(info.F3D_randomAnimation.minInterval) or .15,
					animFrameIDsMap,
				}
			end

			wallStaticVisuals[id] = {
				#frameList,
				frameList,
				frame2Rects,
				randomAnimation or false,
				tonumber(info.F3D_length) or 1,
				tonumber(info.F3D_width) or 1,
				tonumber(info.F3D_height) or 1,
				tostring(info.F3D_texture or ""),
			}
			::continue::
		end
	end)
end

do
	local tileIndex2Frame = {}
	local tileID2Quads = {}

	function F3DTileVisuals.getQuadsFrame(tx, ty)
		local index = reduceCoordinates(tx, ty)
		return index and tileIndex2Frame[index]
	end

	function F3DTileVisuals.setQuadsFrame(tx, ty, frame)
		local index = reduceCoordinates(tx, ty)
		if index then
			tileIndex2Frame[index] = frame
		end
	end

	function F3DTileVisuals.getQuadsVisual(tx, ty)
		local id = getTileID(tx, ty)
		local quads = id and tileID2Quads[id]
		if quads then
			return quads
		end
	end

	event.tileSchemaUpdate.add("createTileObjectVisuals", "visuals", function()
		tileID2Quads = {}

		for id = 1, TileTypes.getMaximumTileID() do
			local quads = TileTypes.getTileInfo(id).F3D_quads
			if type(quads) == "table" and type(quads.frames) == "table" and next(quads.frames) then
				local offsetX = tonumber(quads.offsetX) or 0
				local offsetY = tonumber(quads.offsetY) or 0
				local offsetZ = tonumber(quads.offsetZ) or 0
				local texture = tostring(quads.texture) or ""
				local textureShiftX = tonumber(quads.textureShiftX) or 0
				local textureShiftY = tonumber(quads.textureShiftY) or 0
				local textureWidth = tonumber(quads.textureWidth) or 0
				local textureHeight = tonumber(quads.textureHeight) or 0
				local color = tonumber(quads.color) or -1
				local order = tonumber(quads.order) or 0
				local customOrder = F3DUtilities.ifNil(quads.customOrder, nil, not not quads.customOrder)

				tileID2Quads[id] = {
					offsetX = offsetX,
					offsetY = offsetY,
					offsetZ = offsetZ,
					texture = texture,
					textureShiftX = textureShiftX,
					textureShiftY = textureShiftY,
					textureWidth = textureWidth,
					textureHeight = textureHeight,
					color = color,
					order = order,
					customOrder = customOrder,
					frames = F3DQuadsRenderer.generateQuadsFrames(quads.frames),
					frame = quads.frame or 1,
				}
			end
		end
	end)
end

--- @diagnostic disable-next-line: redefined-local, unused-local
seed = script.persist(function()
	return seed
end)

return F3DTileVisuals
