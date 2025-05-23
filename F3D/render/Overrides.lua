local F3DRenderOverrides = {}

local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"

local type = type

_G.SettingHide2DRenderer = Settings.overridable.choice {
	id = "hide2d",
	name = "2D Renderer",
	choices = {
		{ name = "Hide",               value = true,  desc = "Hide 2D renderer" },
		{ name = "Display",            value = false, desc = "Show 2D renderer and do nothing" },
		{ name = "Compatibility Mode", value = 0,     desc = "Show 2D renderer and convert to 3D space" },
	},
	default = true,
	visibility = Settings.Visibility.HIDDEN,
	cheat = true,
}

function F3DRenderOverrides.hide2D()
	return SettingHide2DRenderer == true
end

local function suppress(func, ev)
	if SettingHide2DRenderer ~= true then
		func(ev)
	end
end
for _, handler in ipairs {
	-- tileMap
	"renderTileMap",
	-- wires
	"renderWires",
	-- shadows
	"renderShadows",
	-- worldLabels
	"renderWorldLabels",
	-- priceTags
	"renderPriceTags",
	-- tells
	"fswTells",
	"renderTargetLockOverlay",
	"renderGameObjects",
	"drawLuteNeck",
	"goldOutlines",
	"renderSilhouetteOutlines",
	"renderLayeredRows",
	"renderContents",
	"renderItemStackSizes",
	"renderItemHintLabels",
	"renderShrineHintLabels",
	"renderSecretShopLabels",
	"renderSwipes",
	"renderHealthBars",
	"renderPlayerNames",
	"renderPlayerInputLockIndicators",
	"renderFlyaways",
	"renderExtraSprites",
	"renderParticles",
} do
	event.render.override(handler, suppress)
end

event.periodicCheck.add("overrideGraphicFeatures", "init", function()
	SettingsStorage.set("video.freezeFrames", 0, Settings.Layer.SCRIPT_OVERRIDE)
end)

return F3DRenderOverrides
