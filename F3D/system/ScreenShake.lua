local F3DMainCamera = require "F3D.camera.Main"
local F3DScreenShake = {}

local AnimationTimer = require "necro.render.AnimationTimer"
local ECS = require "system.game.Entities"
local Focus = require "necro.game.character.Focus"
local GFX = require "system.gfx.GFX"
local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"

local max = math.max
local sqrt = math.sqrt

F3DScreenShake.AnimationName = "screenShake"

_G.SettingScreenShake = Settings.overridable.percent {
	id = "camera.screenShake",
	name = "Screen shake factor",
	desc = "An extra parameter to control the factor of screen shaking.",
	default = 1,
	sliderMinimum = 0,
	sliderMaximum = 1,
	minimum = -math.huge,
	maximum = math.huge,
	step = .25,
	smoothStep = .01,
}

function F3DScreenShake.getFalloffFactor(dx, dy, range)
	return (max(1 - sqrt(dx * dx + dy * dy) / max(range, .75), 0))
end

function F3DScreenShake.getIntensityAtPosition(x, y)
	local intensity = 0

	for entity in ECS.entitiesWithComponents {
		"position",
		"screenShakeEffect",
	} do
		if entity.screenShakeEffect.active and (not entity.screenShakeRequireFocus or Focus.check(entity, Focus.Flag.SCREEN_SHAKE)) then
			local shake = entity.screenShakeEffect

			local factor = 1 - AnimationTimer.getFactorClamped(entity.id, F3DScreenShake.AnimationName, shake.duration)
			local falloff = F3DScreenShake.getFalloffFactor(entity.position.x - x, entity.position.y - y, shake.range)

			intensity = max(intensity, factor * falloff * shake.intensity)
		end
	end

	return intensity * SettingScreenShake * SettingsStorage.get "video.screenShake"
end

event.F3D_renderingMatrices.add("screenShake", "screenShake", function(ev)
	local intensity = F3DScreenShake.getIntensityAtPosition(F3DMainCamera.getCurrentTilePosition())
	if intensity ~= 0 then
		local w, h = GFX.getSize()

		intensity = intensity * math.max(w, h) * .003
		ev.viewportMatrix:translate(
			intensity * (math.random() - .5),
			intensity * (math.random() - .5),
			intensity * (math.random() - .5))
	end
end)

return F3DScreenShake
