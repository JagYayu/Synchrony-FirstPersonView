local F3DFlyawayRenderer = {}

local AnimationTimer = require "necro.render.AnimationTimer"
local Flyaway = require "necro.game.system.Flyaway"
local segmentVisibility = require "necro.game.vision.SegmentVisibility"
local Settings = require "necro.config.Settings"

local isSegmentVisibleAt = segmentVisibility.isVisibleAt
local getAnimationTime = AnimationTimer.getTime
local getReferencedAnimationTime = AnimationTimer.getReferencedAnimationTime

_G.SettingGroupFlyaway = Settings.overridable.group {
	id = "render.flyaway",
	name = "Flyaway renderer",
}

SettingFlyawayEnabled = Settings.overridable.bool {
	id = "render.flyaway.enable",
	name = "Enable",
	default = true,
}

--- @param buffer VertexBuffer
--- @param camera F3D.Camera
--- @param rect F3D.Viewport.Rect
function F3DFlyawayRenderer.renderFlyaway(buffer, camera, rect, flyaway, factor)

end

local renderFlyaway = F3DFlyawayRenderer.renderFlyaway

function F3DFlyawayRenderer.renderFlyaways(buffer, camera, rect)
	for _, flyaway in ipairs(Flyaway.getAll()) do
		local time = getReferencedAnimationTime(flyaway.animationID, flyaway.turnID, "flyaway")

		renderFlyaway(buffer, camera, rect, flyaway, (time - flyaway.delay) / flyaway.duration)
	end

	local time = getAnimationTime()

	for _, flyaway in ipairs(Flyaway.getLocal()) do
		renderFlyaway(buffer, camera, rect, flyaway, (time - flyaway.animationTime) / flyaway.duration)
	end
end

--- @param ev Event.F3D_renderViewport
event.F3D_renderViewport.add("renderFlyaways", "flyaways", function(ev)
	if SettingFlyawayEnabled then
		F3DFlyawayRenderer.renderFlyaways(ev.buffer, ev.camera, ev.rect)
	end
end)

return F3DFlyawayRenderer
