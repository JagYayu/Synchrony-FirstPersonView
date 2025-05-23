local F3DDraw = require "F3D.render.Draw"
local F3DMainCamera = require "F3D.camera.Main"
local F3DMainCameraMode = require "F3D.camera.Mode"
local F3DRender = require "F3D.render.Render"
local F3DUtilities = require "F3D.system.Utilities"

local Render = require "necro.render.Render"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local Swipe = require "necro.game.system.Swipe"
local Color = require "system.utils.Color"

local drawImageY = F3DDraw.imageY
local getBuffer = Render.getBuffer
local opacity = Color.opacity
local vector2RotateAround = F3DUtilities.vector2RotateAround
local worldTileCenter = F3DRender.getTileCenter
local invTS = 1 / Render.TILE_SIZE
local tau = 2 * math.pi

local function getPositionAligned(instance)
	local x, z = worldTileCenter(instance.x, instance.y)
	return x - 1, z - .5
end

-- TODO implement
Swipe.FollowMode.data[Swipe.FollowMode.TWEEN].F3D_func = function(instance)
	return getPositionAligned(instance)
end

Swipe.FollowMode.data[Swipe.FollowMode.TILE].F3D_func = function(instance)
	return getPositionAligned(instance)
end

event.render.add("renderSwipes", "swipes", function()
	local getPosition = Swipe.FollowMode.data[Swipe.getFollowMode()].F3D_func or getPositionAligned

	local _, cy, _ = F3DMainCamera.getCurrent():getPosition()
	cy = F3DMainCameraMode.getData().fpv and cy / 2 or .5

	for _, instance in ipairs(Swipe.getAll()) do
		local frame = Swipe.getAnimationFrame(instance)

		if frame > 0 and SegmentVisibility.isVisibleAt(instance.x, instance.y) then
			local ang = tau - instance.angle
			local sx = instance.scaleX
			local sy = instance.scaleY
			local w = instance.width * invTS
			local h = instance.height * invTS
			local tx = instance.width * (frame - 1)
			local ty = instance.height * (instance.frameY - 1)
			local tw = instance.width
			local th = instance.height
			local x, z = getPosition(instance)
			local x1, z1 = x + instance.offsetX * invTS + .5, z + instance.offsetX * invTS
			local x2, z2 = x1 + w * sx, z1
			local x3, z3 = x1, z1 + h * sy
			local x4, z4 = x2, z3

			if instance.mirrorX ~= 0 then
				x1, x2, x3, x4 = x2, x1, x4, x3
				z1, z2, z3, z4 = z2, z1, z4, z3
			end
			if instance.mirrorY ~= 0 then
				x1, x2, x3, x4 = x3, x4, x1, x2
				z1, z2, z3, z4 = z3, z4, z1, z2
			end

			if ang % tau ~= 0 then
				local xp = x + w / 2 + instance.rotationCenterX * invTS
				local zp = z + h / 2 + instance.rotationCenterY * invTS
				x1, z1 = vector2RotateAround(x1, z1, xp, zp, ang)
				x2, z2 = vector2RotateAround(x2, z2, xp, zp, ang)
				x3, z3 = vector2RotateAround(x3, z3, xp, zp, ang)
				x4, z4 = vector2RotateAround(x4, z4, xp, zp, ang)
			end

			local y = instance.backLayer and invTS or cy
			F3DDraw.quad(x1, y, z1, x2, y, z2, x3, y, z3, x4, y, z4,
				instance.texture, tx, ty, tw, th,
				opacity(1 - Swipe.getAnimationFraction(instance) * instance.fading), F3DRender.ZOrder.Effect)
		end
	end
end)
