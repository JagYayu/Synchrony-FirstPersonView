local F3DDraw = require "F3D.render.Draw"
local F3DMainCamera = require "F3D.camera.Main"
local F3DRender = require "F3D.render.Render"
local F3DWireRenderer = {}

local Beatmap = require "necro.audio.Beatmap"
local Bitmap = require "system.game.Bitmap"
local Color = require "system.utils.Color"
local CommonFilter = require "necro.render.filter.CommonFilter"
local Render = require "necro.render.Render"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local Tile = require "necro.game.tile.Tile"
local Wire = require "necro.game.level.Wire"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local bitmapHeaderSize = Bitmap.HEADER_SIZE
local clamp = Utilities.clamp
local colorOpacity = Color.opacity
local getEffectiveBrightness = Vision.getEffectiveBrightness
local getTileInfo = Tile.getInfo
local isSegmentVisibleAt = SegmentVisibility.isVisibleAt
local imageY = F3DDraw.imageY
local reduceCoordinates = Tile.reduceCoordinates
local tileSize = Render.TILE_SIZE
local unwrapCoordinates = Tile.unwrapCoordinates

F3DWireRenderer.ZOrder = -.5

local paddedSize = tileSize + 2
F3DWireRenderer.padWire = CommonFilter.register("F3D_wirePadding", { image = true }, {}, function(args)
	local maxFrameX = math.floor(args.image.getWidth() / tileSize)
	local maxFrameY = math.floor(args.image.getHeight() / tileSize)
	local input = args.image.getArray()
	local outputBitmap = Bitmap.new(maxFrameX * paddedSize, maxFrameY * paddedSize)
	local output = outputBitmap.getArray()
	local inputWidth = args.image.getWidth()
	local outputWidth = maxFrameX * paddedSize

	for frameY = 0, maxFrameY - 1 do
		for frameX = 0, maxFrameX - 1 do
			local outBase = bitmapHeaderSize + (frameY * outputWidth + frameX) * paddedSize
			local inBase = bitmapHeaderSize + (frameY * inputWidth + frameX) * tileSize

			for y = 0, paddedSize - 1 do
				local inY = clamp(1, y, tileSize) - 1

				for x = 0, paddedSize - 1 do
					local inX = clamp(1, x, tileSize) - 1
					local outputPos = outBase + y * outputWidth + x
					local inputPos = inBase + inY * inputWidth + inX

					output[outputPos] = input[inputPos]
				end
			end
		end
	end

	return outputBitmap
end)

local wirePaddingImageCache = {}
function F3DWireRenderer.getPaddedWireTexture(texture)
	local padded = wirePaddingImageCache[texture]
	if not padded then
		padded = F3DWireRenderer.padWire { image = texture }
		wirePaddingImageCache[texture] = padded
	end
	return padded
end

local getPaddedWireTexture = F3DWireRenderer.getPaddedWireTexture

local wireList
event.updateVisuals.add("clearWireList", "clearCaches", function(ev)
	wireList = nil
end)

event.render.add("renderWires", "wires", function(ev)
	local wireMap, wireVisualMap, wireFrameY = Wire.getAll()
	if not next(wireMap) then
		return
	end

	wireList = wireList or Utilities.removeIf(Utilities.getKeyList(wireMap), function(index)
		local x, y = unwrapCoordinates(index)
		return not isSegmentVisibleAt(x, y)
	end)

	local baseFrameY = ({
		2,
		1,
		4,
		3,
		2,
	})[Utilities.lowerBound({
		0.09,
		0.39,
		0.69,
		0.99,
	}, 1 - Beatmap.getPrimary().getMusicBeatFraction())]
	local ord = F3DWireRenderer.ZOrder

	local invBrightness = 1 / 255
	for _, index in ipairs(wireList) do
		local tx, ty = unwrapCoordinates(index)
		local wire = getTileInfo(tx, ty).wire

		if wire and wire.texture then
			local connectivity = wireVisualMap[index] + 1
			local frameX = wire.connectivityFrameX[connectivity]
			local frameY = wireFrameY[index] or baseFrameY
			local mirrorX = wire.connectivityMirrorX[connectivity]

			imageY((tx - .5 * mirrorX), 0, (-ty - .5), mirrorX, 1,
				getPaddedWireTexture(wire.texture), (frameX - 1) * paddedSize + 1, (frameY - 1) * paddedSize + 1,
				tileSize, tileSize, colorOpacity(getEffectiveBrightness(tx, ty) * invBrightness), ord)
		end
	end
end)

return F3DWireRenderer
