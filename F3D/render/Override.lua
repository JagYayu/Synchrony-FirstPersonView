local F3DOverrideRenderer = {}
local F3DViewport = require "F3D.render.Viewport"

local Settings = require "necro.config.Settings"

SettingHide2DRenderer = Settings.overridable.choice {
	id = "hide2d",
	name = "Hide 2d renderer",
	default = 1,
	choices = {
		{
			name = "Always",
			value = 0,
		},
		{
			name = "On Viewport3D Enabled",
			value = 1,
		},
		{
			name = "Disable",
			value = 2,
		},
	},
	visibility = Settings.Visibility.HIDDEN,
}

local suppressHide2DRenderer = false

function F3DOverrideRenderer.isHiding2DRenderer()
	return suppressHide2DRenderer
end

event.render.add("hide2DRenderer", "initLegacyGraphics", function()
	suppressHide2DRenderer = SettingHide2DRenderer == 2 or (SettingHide2DRenderer == 1 and not F3DViewport.isEnabled())
end)

local function suppress(func, ev)
	if suppressHide2DRenderer then
		func(ev)
	end
end
for _, handler in ipairs {
	"renderTileMap",
	"renderWires",
	"renderShadows",
	"renderWorldLabels",
	"renderPriceTags",
	"renderTargetLockOverlay",
	"renderGameObjects",
	"renderLayeredRows",
	"renderSilhouetteOutlines",
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

return F3DOverrideRenderer
