local F3DUtilities = {}
local F3DVector = require "F3D.necro3d.Vector"

local Bitmap = require "system.game.Bitmap"
local ClientActionBuffer = require "necro.client.ClientActionBuffer"
local Controls = require "necro.config.Controls"
local CustomActions = require "necro.game.data.CustomActions"
local EnumSelector = require "system.events.EnumSelector"
local FileIO = require "system.game.FileIO"
local Focus = require "necro.game.character.Focus"
local GameClient = require "necro.client.GameClient"
local GameState = require "necro.client.GameState"
local GFX = require "system.gfx.GFX"
local Input = require "system.game.Input"
local JSON = require "system.utils.serial.JSON"
local LocalCoop = require "necro.client.LocalCoop"
local PlayerList = require "necro.client.PlayerList"
local Rollback = require "necro.client.Rollback"
local SettingsStorage = require "necro.config.SettingsStorage"
local StringUtilities = require "system.utils.StringUtilities"
local Tile = require "necro.game.tile.Tile"
local Turn = require("necro.cycles.Turn")
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local cos = math.cos
local d2r = math.pi / 180
local sqrt = math.sqrt
local sin = math.sin
local tonumber = tonumber
local vectorAdd = F3DVector.add

--- @param key any
--- @return any
function F3DUtilities.getSettingSafe(key)
	local value = SettingsStorage.get(key)
	local default = SettingsStorage.getDefaultValue(key)
	if type(value) ~= type(default) then
		value = default
		SettingsStorage.set(key, value)
	end
	return value
end

function F3DUtilities.registerHotKeyDown(args)
	local id = CustomActions.registerHotkey(args)

	event.tick.override("F3D_action_" .. id, function() end)

	local function keyDown(getKeyBinds, ...)
		for _, key in ipairs(getKeyBinds(...) or {}) do
			if Input.keyDown(key) then
				return true
			end
		end

		return false
	end

	event.tick.add("actionHotKeyDown" .. id, {
		order = args.callbackOrder or "customHotkeys",
		sequence = args.F3D_callbackSequence,
	}, args.perPlayerBinding and function()
		for _, playerID in ipairs(LocalCoop.getLocalPlayerIDs()) do
			if args.enableIf(playerID) and keyDown(Controls.getActionKeyBinds, id, LocalCoop.getControllerID(playerID)) and args.callback(playerID) then
				Controls.consumeActionKey(id, LocalCoop.getControllerID(playerID))
			end
		end
	end or function()
		local playerID = PlayerList.getLocalPlayerID()
		if args.enableIf(playerID) and keyDown(Controls.getMiscKeyBinds, id, LocalCoop.getControllerID(playerID)) and args.callback(playerID) ~= false then
			Controls.consumeMiscKey(id)
		end
	end)

	return id
end

F3DUtilities.emptyTable = setmetatable({}, {
	__newindex = function()
		error("Attempt to modify empty table", 2)
	end
})

function F3DUtilities.ifNil(a, b, c)
	if a == nil then
		return b
	else
		return c
	end
end

function F3DUtilities.listFindIf(list, cond)
	for index, entry in ipairs(list) do
		if cond(entry, index) then
			return entry, index
		end
	end
end

function F3DUtilities.newImmutable(tbl)
	if type(tbl) ~= "table" then
		error("table expected", 2)
	end

	return setmetatable({}, {
		__index = function(_, k)
			if tbl[k] then
				return tbl[k]
			end

			local msg = ("Attempt to index non-exist field '%s'"):format(k)
			local what = StringUtilities.didYouMean(k, Utilities.getKeyList(tbl))
			if what ~= k then
				msg = msg .. ". " .. k
			end
			error(msg, 2)
		end,
		__newindex = function(_, k)
			error(("Attempt modify field '%s' at an immutable table"):format(k), 2)
		end,
	})
end

--- Translate a triangle in local coordinates
function F3DUtilities.planeTranslate(dx, dy, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)
	local ax, ay, az = F3DVector.sub(x2, y2, z2, x1, y1, z1)
	local bx, by, bz = F3DVector.sub(x2, y2, z2, x1, y1, z1)
	local nx, ny, nz = F3DVector.cross(ax, ay, az, bx, by, bz)
end

do
	local defaultScaleComponentFields = {
		sprite = "scale",
		shadow = "scale",
	}

	--- @param entity Entity
	--- @param scale number
	--- @param componentFields table<Entity.ComponentType, string>?
	--- @return Entity
	function F3DUtilities.scaleEntityWrapper(entity, scale, componentFields)
		componentFields = componentFields or defaultScaleComponentFields

		return setmetatable({}, {
			__index = function(_, component)
				local fieldName = componentFields[component]
				return fieldName and setmetatable({}, {
					__index = function(_, field)
						local c = entity[component]
						local v = field == fieldName and tonumber(c[field])
						return v and v * scale or c[field]
					end,
				}) or entity[component]
			end,
		})
	end
end

function F3DUtilities.vector2FromAngle(ang)
	return cos(ang), sin(ang)
end

function F3DUtilities.vector2Magnitude(x, y)
	return sqrt(x * x + y * y)
end

function F3DUtilities.vector2Normalize(x, y)
	local t = 1 / sqrt(x * x + y * y)
	return x * t, y * t
end

function F3DUtilities.vector2Rotate(x, y, ang)
	local angleRadians = ang * d2r
	local c = cos(angleRadians);
	local s = sin(angleRadians);
	return x * c - y * s, x * s + y * c
end

function F3DUtilities.vector2RotateAround(x, y, ox, oy, ang)
	ox = ox or 0
	oy = oy or 0

	local c = cos(ang)
	local s = sin(ang)

	x = x - ox
	y = y - oy

	return x * c - y * s + ox, x * s + y * c + oy
end

return F3DUtilities
