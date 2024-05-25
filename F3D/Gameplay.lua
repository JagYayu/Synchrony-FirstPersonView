local F3DGameplay = {}

local Ability = require "necro.game.system.Ability"
local Action = require "necro.game.system.Action"
local Collision = require "necro.game.tile.Collision"
local CustomActions = require "necro.game.data.CustomActions"
local Move = require "necro.game.system.Move"
local Settings = require "necro.config.Settings"

local abs = math.abs
local floor = math.floor
local sqrt = math.sqrt

_G.SettingGroupGameplay = Settings.shared.group {
	id = "gameplay",
	name = "Gameplay",
	order = 20,
}

SettingStrictMoveCollision = Settings.shared.choice {
	id = "gameplay.strictMoveCollision",
	name = "Strict move collision check",
	desc = "Most obviously, entities that move diagonally are not allowed to pass through seamless walls",
	default = 0,
	choices = {
		{
			name = "None",
			value = 0,
		},
		{
			name = "Players",
			value = 1,
		},
		{
			name = "Other entities",
			value = 2,
		},
		{
			name = "All entities",
			value = 3,
		},
	},
}

--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @param mask? integer
--- @param check? fun(x: integer, y: integer, ...: any): boolean?
--- @return boolean collide
--- @return number? x
--- @return number? y
function F3DGameplay.raycastCheck(x1, y1, x2, y2, mask, check)
	if not check then
		check = Collision.check
	end

	-- DDA raycast
	local rayDistX = x2 - x1
	local rayDistY = y2 - y1
	local rayDist = sqrt(rayDistX * rayDistX + rayDistY * rayDistY)
	local rayDirX = rayDistX / rayDist
	local rayDirY = rayDistY / rayDist
	local tileX = floor(x1)
	local tileY = floor(y1)
	local sideDistX
	local sideDistY
	local deltaDistX = abs(1 / rayDirX)
	local deltaDistY = abs(1 / rayDirY)
	local stepX
	local stepY
	if rayDirX < 0 then
		stepX = -1
		sideDistX = (x1 - tileX) * deltaDistX
	else
		stepX = 1
		sideDistX = (tileX + 1 - x1) * deltaDistX
	end
	if rayDirY < 0 then
		stepY = -1
		sideDistY = (y1 - tileY) * deltaDistY
	else
		stepY = 1
		sideDistY = (tileY + 1 - y1) * deltaDistY
	end

	while sideDistX < rayDist or sideDistY < rayDist do
		if sideDistX == sideDistY then
			if check(tileX + stepX, tileY, mask) or check(tileX, tileY + stepY, mask) then
				return true, tileX, tileY
			end

			sideDistX = sideDistX + deltaDistX
			sideDistY = sideDistY + deltaDistY
			tileX = tileX + stepX
			tileY = tileY + stepY
		else
			if sideDistX < sideDistY then
				sideDistX = sideDistX + deltaDistX
				tileX = tileX + stepX
			else
				sideDistY = sideDistY + deltaDistY
				tileY = tileY + stepY
			end

			if check(tileX, tileY, mask) then
				return true, tileX, tileY
			end
		end
	end

	return false
end

event.objectCheckMove.add("checkForPreMoveCollisions", {
	filter = "collisionCheckOnMove",
	order = "collision",
}, function(ev)
	if true then
		return -- TODO XD its broken right now.
	end

	if ev.result == nil
		and Move.Flag.check(ev.moveType, Move.Flag.COLLIDE_INTERMEDIATE)
		and (ev.x - ev.prevX ~= 0 and ev.y - ev.prevY ~= 0)
		and SettingStrictMoveCollision ~= 0
	then
		local collide, x, y = F3DGameplay.raycastCheck(ev.prevX, ev.prevY, ev.x, ev.y,
			ev.entity.collisionCheckOnMove.mask)
		if collide then
			ev.x = x
			ev.y = y
		end
	end
end)

return F3DGameplay
