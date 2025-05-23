--- @class F3D.Ray

local F3DCamera = require "F3D.necro3d.Camera"
--- @class F3DRay : F3D.Ray
local F3DRay = {}
local F3DRender = require "F3D.render.Render"
local F3DMainCamera = require "F3D.camera.Main"
local F3DVector = require "F3D.necro3d.Vector"

local GFX = require "system.gfx.GFX"
local Input = require "system.game.Input"

local camera = F3DMainCamera.getCurrent()

--- @return number? x
--- @return number z
function F3DRay:castToGround()
	if self[5] < 0 then
		local t = -self[2] / self[5]
		return self[1] + self[4] * t, self[3] + self[6] * t
	end
	return nil, 0
end

--- @return integer? x
--- @return integer y
function F3DRay:castToTile()
	local x, z = self:castToGround()
	if x then
		return F3DRender.getTileAt(x, z)
	end
	return nil, 0
end

do
	F3DRay[1] = 0
	F3DRay[2] = 0
	F3DRay[3] = 0
	F3DRay[4] = 1
	F3DRay[5] = 0
	F3DRay[6] = 0

	function F3DRay.create(x, y, z, dirX, dirY, dirZ)
		return {
			x or F3DRay[1],
			y or F3DRay[2],
			z or F3DRay[3],
			dirX or F3DRay[4],
			dirY or F3DRay[5],
			dirZ or F3DRay[6],
		}
	end
end

function F3DRay:tostring()
	return "{" .. table.concat(self, ",") .. "}"
end

do
	local metatable = {
		__index = F3DRay,
		__tostring = F3DRay.tostring,
	}

	function F3DRay.setmetatable(tbl)
		return setmetatable(tbl, metatable)
	end
end

--- @return F3DRay
function F3DRay.new(x, y, z, dirX, dirY, dirZ)
	return F3DRay.setmetatable(F3DRay.create(x, y, z, dirX, dirY, dirZ))
end

local createRay = F3DRay.new

--- @param x number? screen x
--- @param y number? screen y
--- @return F3DRay
function F3DRay.newScreen(x, y)
	local w, h = GFX.getSize()
	x = x or Input.mouseX() * 2 / w - 1
	y = y or Input.mouseY() * 2 / h - 1

	x, y = F3DRender.getProjectionMatrix():inverse():multiplyVector(x, y, 1, 1)

	local z
	x, y, z = F3DVector.normalize(F3DRender.getViewMatrix():multiplyVector(x, y, 1))
	return createRay(camera[F3DCamera.Field.X], camera[F3DCamera.Field.Y], camera[F3DCamera.Field.Z], x, -y, -z)
end

return F3DRay
