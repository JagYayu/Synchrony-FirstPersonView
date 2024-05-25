local F3DUtility = {}

local Bitmap = require "system.game.Bitmap"
local FileIO = require "system.game.FileIO"
local GameClient = require "necro.client.GameClient"
local JSON = require "system.utils.serial.JSON"
local Tile = require "necro.game.tile.Tile"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local BRIGHTNESS_MAX = 255
local acos = math.acos
local clamp = Utilities.clamp
local cos = math.cos
local floor = math.floor
local getEffectiveBrightness = Vision.getEffectiveBrightness
local reduceCoordinates = Tile.reduceCoordinates
local sin = math.sin
local sqrt = math.sqrt

--#region Render Utilities

local bitmapPixelData = {}

function F3DUtility.getBitmapPixel(texture, sampleX, sampleY)
	local data = bitmapPixelData[texture]

	if data == nil then
		local bitmap = Bitmap.load(texture)
		if bitmap then
			local width = bitmap.getWidth()
			local height = bitmap.getHeight()

			-- Accessing array wrapper is much slower than lua native array.
			-- This is a big performance improvement for floor rendering.
			local pixelArray = {}
			for i = 0, bitmap.getArray().size do
				pixelArray[i] = bitmap.getPixel(i % width, floor(i / width))
			end

			data = { pixelArray, width, height }
		else
			data = false
		end

		bitmapPixelData[texture] = data
	end

	if data then
		return data[1][floor(sampleX * data[2]) + floor(sampleY * data[3]) * data[2]]
	end
end

local tileBrightnessFactorCache = {}

--- @param tileX integer
--- @param tileY integer
--- @return number? f @[0, 1]
function F3DUtility.getTileBrightnessFactorCached(tileX, tileY)
	local i = reduceCoordinates(tileX, tileY)
	if i then
		if tileBrightnessFactorCache[i] == nil then
			tileBrightnessFactorCache[i] = getEffectiveBrightness(tileX, tileY) / BRIGHTNESS_MAX
		end

		return tileBrightnessFactorCache[i]
	end
end

event.renderUI.add("clearBrightnessFactorCache", "clear", function()
	if next(tileBrightnessFactorCache) then
		tileBrightnessFactorCache = {}
	end
end)

local tileVisualsSeed

function F3DUtility.getTileVisualSeed()
	return tileVisualsSeed
end

event.gameStateLevel.add("randomizeWallVisuals", "tileVisuals", function(ev)
	tileVisualsSeed = ev.tileVisualsSeed or 0
end)

--#endregion

function F3DUtility.angleToVector2(radius)
	return cos(radius), sin(radius)
end

function F3DUtility.length3(x, y, z)
	return sqrt(x * x + y * y + z * z)
end

--- @param vectorX number
--- @param vectorY number
--- @param angle number
--- @return number vectorX
--- @return number vectorY
function F3DUtility.rotateVector2(vectorX, vectorY, angle)
	local cosAngle = cos(angle)
	local sinAngle = sin(angle)
	return vectorX * cosAngle - vectorY * sinAngle, vectorY * cosAngle + vectorX * sinAngle
end

function F3DUtility.lineLineIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
	local d = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
	return ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / d, ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / d
end

function F3DUtility.lineLineIntersectX(x1, y1, x2, y2, x3, y3, x4, y4)
	return ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
end

function F3DUtility.lineLineIntersectY(x1, y1, x2, y2, x3, y3, x4, y4)
	return ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
end

function F3DUtility.linePoint(t, x1, y1, x2, y2)
	return x1 + t * (x2 - x1), y1 + t * (y2 - y1)
end

function F3DUtility.pointLineIntersect(x, y, x1, y1, x2, y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local k = ((x - x1) * dy - (y - y1) * dx) / (dx ^ 2 + dy ^ 2)
	return x - k * dy, y + k * dx
end

function F3DUtility.vector2Dot(x1, y1, x2, y2)
	return x1 * x2 + y1 * y2
end

local v2D = F3DUtility.vector2Dot

function F3DUtility.vector2Module(x, y)
	return sqrt(x * x + y * y)
end

local v2M = F3DUtility.vector2Module

function F3DUtility.vector2Normalize(x, y)
	local m = v2M(x, y)
	return x / m, y / m
end

local v2N = F3DUtility.vector2Normalize

function F3DUtility.vector2Cos(x1, x2, y1, y2)
	return v2D(x1, y1, x2, y2) / (v2M(x1, x2) * v2M(y1, y2))
end

local v2C = F3DUtility.vector2Cos

function F3DUtility.vector2Angle(x1, x2, y1, y2)
	return acos(v2C(x1, x2, y1, y2))
end

function F3DUtility.vector2Cross(x1, x2, y1, y2)
	return x1 * y2 - y1 * x2
end

function F3DUtility.slerp(x1, y1, x2, y2, f)
	local dot = clamp(-1, v2D(x1, y1, x2, y2), 1);
	local x, y = v2N(x2 - x1 * dot, y2 - y1 * dot)
	local t = acos(dot) * f
	local ct = cos(t)
	local st = sin(t)
	return x1 * ct + x * st, y1 * ct + y * st
end

F3DUtility.clientIsModAuthor = false
pcall(function()
	local modJson = JSON.decode(FileIO.readFileToString "mods/F3D/mod.json")
	if type(modJson) == "table" and type(modJson.author) == "string" then
		local names = {}
		modJson.author:gsub("([^,]+)", function(name)
			names[#names + 1] = name
		end)
		F3DUtility.clientIsModAuthor = not not Utilities.arrayFind(names, GameClient.getUsername())
	end
end)

tileVisualsSeed = script.persist(function()
	return tileVisualsSeed
end)

return F3DUtility
