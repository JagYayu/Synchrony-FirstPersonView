local F3DCamera = require "F3D.Camera"
local F3DSwipeRenderer = {}
local F3DViewport = require "F3D.render.Viewport"

local Color = require "system.utils.Color"
local Render = require "necro.render.Render"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local Settings = require "necro.config.Settings"
local Swipe = require "necro.game.system.Swipe"
local Utilities = require "system.utils.Utilities"

local TILE_SIZE = Render.TILE_SIZE
local abs = math.abs
local getCameraRenderOffset = F3DCamera.getRenderOffset
local getSwipeAnimationFraction = Swipe.getAnimationFraction
local getSwipeAnimationFrame = Swipe.getAnimationFrame
local opacity = Color.opacity
local sqrt = math.sqrt
local squareDistance = Utilities.squareDistance
local viewportTransformVector = F3DViewport.transformVector

_G.SettingGroupSwipe = Settings.overridable.group {
	id = "render.swipe",
	name = "Swipe renderer",
}

SettingSwipeScale = Settings.overridable.number {
	id = "render.swipe.scale",
	name = "Scale factor",
	default = 1,
	minimum = 0,
	sliderMaximum = 2,
}

local swipeGlobalScale = 1 / 24

local drawArgs = {
	rect = {},
	texRect = {},
}
local drawArgsRect = drawArgs.rect
local drawArgsTexRect = drawArgs.texRect

local function getPositionAligned(instance)
	return (instance.x - .5) * TILE_SIZE, (instance.y - .5) * TILE_SIZE
end

function F3DSwipeRenderer.renderSwipes(buffer, camera, rect)
	local draw = buffer.draw
	local getRenderPosition = Swipe.FollowMode.data[Swipe.getFollowMode()].func or getPositionAligned

	for index, swipe in ipairs(Swipe.getAll()) do
		local frame = getSwipeAnimationFrame(swipe)
		if frame <= 0 or not SegmentVisibility.isVisibleAt(swipe.x, swipe.y) then
			goto continue
		end

		local x, y, animID = getRenderPosition(swipe)
		local dx, dy = getCameraRenderOffset(camera, x, y - 12)
		local px, py, tx, ty = viewportTransformVector(camera, rect, dx, dy)
		if not px then
			goto continue
		end

		local mirrorX = swipe.mirrorX
		local mirrorY = swipe.mirrorY

		-- local buffer = getBuffer(instance.buffer)

		-- args.anim = animID
		drawArgs.texture = swipe.texture
		drawArgsTexRect[1] = swipe.width * (frame - 1)
		drawArgsTexRect[2] = swipe.height * (swipe.frameY - 1)
		drawArgsTexRect[3] = swipe.width
		drawArgsTexRect[4] = swipe.height

		local scale = rect[4] / ty * swipeGlobalScale

		local width = swipe.width * scale * swipe.scaleX
		local height = swipe.height * scale * swipe.scaleY
		drawArgsRect[3] = (1 - 2 * mirrorX) * width
		drawArgsRect[4] = (1 - 2 * mirrorY) * height
		drawArgsRect[1] = px + swipe.offsetX + mirrorX * width - abs(drawArgsRect[3]) / 2
		drawArgsRect[2] = py + swipe.offsetY + (mirrorY - .5) * height - abs(drawArgsRect[4]) / 2

		-- args.origin = {
		-- 	x - args.rect[1] + instance.rotationCenterX,
		-- 	y - args.rect[2] + instance.rotationCenterY
		-- }

		drawArgs.angle = swipe.angle
		drawArgs.color = opacity((swipe.opacity or 1) * (1 - getSwipeAnimationFraction(swipe) * swipe.fading))
		drawArgs.z = -sqrt(squareDistance(dx, dy)) -- drawArgs.rect[2] + swipe.offsetZ

		draw(drawArgs)

		::continue::
	end
end

-- event.swipe.add("", { order = 9999999999999999 }, function(ev)
-- 	ev.swipe.duration = 60
-- end)

--- @param ev Event.F3D_renderViewport
event.F3D_renderViewport.add("renderSwipes", "swipes", function(ev)
	F3DSwipeRenderer.renderSwipes(ev.buffer, ev.camera, ev.rect)
end)

return F3DSwipeRenderer
