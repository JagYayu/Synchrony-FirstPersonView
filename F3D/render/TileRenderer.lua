local F3DCamera = require "F3D.necro3d.Camera"
local F3DDraw = require "F3D.render.Draw"
local F3DMainCamera = require "F3D.camera.Main"
local F3DMainCameraVisibility = require "F3D.camera.Visibility"
local F3DQuadsRenderer = require "F3D.render.QuadsRenderer"
local F3DRender = require "F3D.render.Render"
local F3DTileRenderer = {}
local F3DTileVisuals = require "F3D.render.TileVisuals"

local Color = require "system.utils.Color"
local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local Tile = require "necro.game.tile.Tile"
local TileTypes = require "necro.game.tile.TileTypes"
local TileRenderer = require "necro.render.level.TileRenderer"
local Vision = require "necro.game.vision.Vision"

local ZOrderFloor = F3DRender.ZOrder.Floor
local ZOrderWall = F3DRender.ZOrder.Wall
local bitOr = bit.bor
local cameraVisibilityCheckTile = F3DMainCameraVisibility.getTile
local colorGray = Color.gray
local drawImageY = F3DDraw.imageY
local drawWall = F3DDraw.wall
local getEffectiveBrightness = Vision.getEffectiveBrightness
local getFloorVisual = F3DTileVisuals.getFloorVisual
local getTileID = Tile.get
local getTileInfo = Tile.getInfo
local getTileInfoByID = TileTypes.getTileInfo
local getTileQuads = F3DTileVisuals.getQuadsVisual
local getTileQuadsFrame = F3DTileVisuals.getQuadsFrame
local getTileWorldCenter = F3DRender.getTileCenter
local getWallVisual = F3DTileVisuals.getWallVisual
local isVisible = Vision.isVisible
local renderQuads = F3DQuadsRenderer.renderQuads
local tonumber = tonumber

_G.SettingSmoothLighting = Settings.overridable.bool {
	id = "render.smoothLighting",
	name = "Smooth lighting",
	order = 502,
	desc = "Apply smooth brightness to tiles. May impact performance.",
	default = (function()
		local success, default = pcall(function()
			local Performance = require "system.debug.Performance"
			return not not Performance.isLuaJITProfilerRunning()
		end)
		if success then
			return default
		else
			return false
		end
	end)(),
}

do
	local tileBoundingVertices = {}

	local function getFloorBoundingVertices(info)
		local l = (1 - (tonumber(info.F3D_length) or 1)) / 2
		local w = (1 - (tonumber(info.F3D_width) or 1)) / 2
		local dl = 1 - l
		local dw = 1 - w
		return {
			l, 0, dw, -- back right
			l, 0, w, -- back left
			dl, 0, w, -- front right
			dl, 0, dw, -- front left
		}
	end

	local function getWallBoundingVertices(info)
		local l = (1 - (tonumber(info.F3D_length) or 1)) / 2
		local w = (1 - (tonumber(info.F3D_width) or 1)) / 2
		local h = (1 - (tonumber(info.F3D_height) or 1)) / 2
		local dl = 1 - l
		local dw = 1 - w
		local dh = 1 - h
		local bounding = {
			l, h, w, -- back down right
			l, h, dw, -- back down left
			l, dh, w, -- back up right
			l, dh, dw, -- back up left
			dl, h, w, -- front down right
			dl, h, dw, -- front down left
			dl, dh, w, -- front up right
			dl, dh, dw, -- front up left
		}
		local floorInfo = getTileInfoByID(TileTypes.lookUpTileID(info.floor, info.zoneID))
		if floorInfo.F3D_floor then
			local floor = getFloorBoundingVertices(floorInfo)
			bounding[01] = math.min(floor[01], bounding[01])
			bounding[02] = math.min(floor[02], bounding[02])
			bounding[03] = math.min(floor[03], bounding[03])
			bounding[04] = math.min(floor[04], bounding[04])
			bounding[05] = math.min(floor[05], bounding[05])
			bounding[06] = math.max(floor[06], bounding[06])
			bounding[13] = math.max(floor[07], bounding[13])
			bounding[14] = math.min(floor[08], bounding[14])
			bounding[15] = math.min(floor[09], bounding[15])
			bounding[16] = math.max(floor[10], bounding[16])
			bounding[17] = math.min(floor[11], bounding[17])
			bounding[18] = math.max(floor[12], bounding[18])
		end
		return bounding
	end

	event.tileSchemaUpdate.add("createTileBoundingVertices", "visuals", function()
		tileBoundingVertices = {}

		for id = 1, TileTypes.getMaximumTileID() do
			local info = TileTypes.getTileInfo(id)
			local bounding
			if info.F3D_floor then
				bounding = getFloorBoundingVertices(info)
			elseif info.F3D_wall then
				bounding = getWallBoundingVertices(info)
			end
			tileBoundingVertices[id] = bounding
		end
	end)

	local frustum = F3DRender.getFrustum()
	local check = frustum.isInside

	--- Frustum culling invisible tiles.
	--- @param tx integer
	--- @param ty integer
	--- @return boolean
	function F3DTileRenderer.canSeeTile(tx, ty)
		local offsets = tileBoundingVertices[getTileID(tx, ty)]
		if offsets then
			local x, z = getTileWorldCenter(tx, ty)
			x = x - .5
			z = z - .5
			for i = 1, #offsets - 2, 3 do
				if check(frustum, x + offsets[i], offsets[i + 1], z + offsets[i + 2]) then
					return true
				end
			end
		end
		return false
	end
end

local canSeeTile = F3DTileRenderer.canSeeTile

--- @return Color
local function getTileEffectiveColor(tx, ty)
	return colorGray(getEffectiveBrightness(tx, ty) / 255)
end

function F3DTileRenderer.getWallVisibleFaces(tx, ty)
	local flags = 0
	if not getTileInfo(tx + 1, ty).F3D_wallFaceCuller then
		flags = bitOr(flags, 0b0001)
	end
	if not getTileInfo(tx, ty - 1).F3D_wallFaceCuller then
		flags = bitOr(flags, 0b0010)
	end
	if not getTileInfo(tx - 1, ty).F3D_wallFaceCuller then
		flags = bitOr(flags, 0b0100)
	end
	if not getTileInfo(tx, ty + 1).F3D_wallFaceCuller then
		flags = bitOr(flags, 0b1000)
	end
	return flags
end

local getWallVisibleFaces = F3DTileRenderer.getWallVisibleFaces

--- This function address will be changed dynamically, cache only while you use.
--- @param tx integer
--- @param ty integer
--- @return F3DDraw.col
--- @diagnostic disable-next-line: unused-local
function F3DTileRenderer.getFloorColorArg(tx, ty)
	return -1
end

--- This function address will be changed dynamically, cache only while you use.
--- @param tx integer
--- @param ty integer
--- @return F3DDraw.col
--- @diagnostic disable-next-line: unused-local
function F3DTileRenderer.getWallColorArg(tx, ty)
	return -1
end

local function updateGetColorArgsFunctions()
	if SettingSmoothLighting then
		local f = .25 / 255
		local function getColors(tx, ty)
			local b0 = getEffectiveBrightness(tx, ty)
			local b1 = getEffectiveBrightness(tx + 1, ty)
			local b2 = getEffectiveBrightness(tx + 1, ty - 1)
			local b3 = getEffectiveBrightness(tx, ty - 1)
			local b4 = getEffectiveBrightness(tx - 1, ty - 1)
			local b5 = getEffectiveBrightness(tx - 1, ty)
			local b6 = getEffectiveBrightness(tx - 1, ty + 1)
			local b7 = getEffectiveBrightness(tx, ty + 1)
			local b8 = getEffectiveBrightness(tx + 1, ty + 1)
			return colorGray((b0 + b1 + b2 + b3) * f),
				colorGray((b0 + b3 + b4 + b5) * f),
				colorGray((b0 + b5 + b6 + b7) * f),
				colorGray((b0 + b1 + b7 + b8) * f)
		end

		do
			local arg = { 0, 0, 0, 0 }
			F3DTileRenderer.getFloorColorArg = function(tx, ty)
				local c1, c2, c3, c4 = getColors(tx, ty)
				arg[1] = c2
				arg[2] = c1
				arg[3] = c3
				arg[4] = c4
				return arg
			end
		end

		do
			local arg = {
				{ 0, 0, 0, 0 },
				{ 0, 0, 0, 0 },
				{ 0, 0, 0, 0 },
				{ 0, 0, 0, 0 },
				{ 0, 0, 0, 0 },
			}
			--- @return F3DRender.wall.col
			F3DTileRenderer.getWallColorArg = function(tx, ty)
				local c1, c2, c3, c4 = getColors(tx, ty)
				arg[1][1] = c2; arg[2][1] = c4; arg[3][1] = c2; arg[4][1] = c3; arg[5][1] = c3
				arg[1][2] = c1; arg[2][2] = c1; arg[3][2] = c1; arg[4][2] = c2; arg[5][2] = c4
				arg[1][3] = c3; arg[2][3] = c4; arg[3][3] = c2; arg[4][3] = c3; arg[5][3] = c3
				arg[1][4] = c4; arg[2][4] = c1; arg[3][4] = c1; arg[4][4] = c2; arg[5][4] = c4
				return arg
			end
		end
	else
		F3DTileRenderer.getFloorColorArg = getTileEffectiveColor
		F3DTileRenderer.getWallColorArg = getTileEffectiveColor
	end
end

event.render.add("renderTileMap", "tileMap", function()
	updateGetColorArgsFunctions()
	local getFloorColorArg = F3DTileRenderer.getFloorColorArg
	local getWallColorArg = F3DTileRenderer.getWallColorArg

	local beat = TileRenderer.getCurrentBeat()
	local groove = TileRenderer.isGrooveChainActive()
	local ctx, cty
	do
		local cx, _, cz = F3DMainCamera.getCurrent():getPosition()
		ctx, cty = F3DRender.getTileAt(cx, cz)
	end
	local viewDistance = SettingsStorage.get "mod.F3D.render.viewDistance"
	local squareViewDistance = viewDistance * viewDistance
	local canSeeFloor = F3DMainCamera.getCurrent()[F3DCamera.Field.Y] > 0

	for ty = cty - viewDistance, cty + viewDistance do
		local squareDY
		do
			local dy = cty - ty
			squareDY = dy * dy
		end

		for tx = ctx - viewDistance, ctx + viewDistance do
			local dist
			do
				local dx = ctx - tx
				dist = dx * dx + squareDY
			end

			if ((dist <= squareViewDistance and canSeeTile(tx, ty)) or dist < 1.5) then
				local invisibility = cameraVisibilityCheckTile(tx, ty)
				local info

				if canSeeFloor and not invisibility.floor then
					info = info or getTileInfo(tx, ty)

					local x, z, w, h, tex, texX, texY, texW, texH = getFloorVisual(tx, ty, info, beat, isVisible(tx, ty), groove)
					if x then
						drawImageY(x + w, 0, z - h, w, h,
							tex, texX, texY, texW, texH,
							getFloorColorArg(tx, ty), info.F3D_zOrder or ZOrderFloor)
					end
				end

				local wallColArg
				if not invisibility.wall then
					local x, z, l, w, h, t, tx1, ty1, tw1, th1, tx2, ty2, tw2, th2, tx3, ty3, tw3, th3 = getWallVisual(tx, ty)
					if x then
						info = info or getTileInfo(tx, ty)
						wallColArg = getWallColorArg(tx, ty)

						drawWall(x, z, l, w, h, t,
							tx1, ty1, tw1, th1,
							tx2, ty2, tw2, th2,
							tx3, ty3, tw3, th3,
							info.F3D_wallFaceCulling and getWallVisibleFaces(tx, ty) or 15,
							wallColArg, info.F3D_zOrder or ZOrderWall)
					end
				end

				local quads = getTileQuads(tx, ty)
				if quads then
					local x, z = getTileWorldCenter(tx, ty)
					wallColArg = wallColArg or getWallColorArg(tx, ty)
					renderQuads(quads, getTileQuadsFrame(tx, ty), x, 0, z, wallColArg)
				end
			end
		end
	end
end)

return F3DTileRenderer
