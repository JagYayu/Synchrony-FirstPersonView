local F3DEntity = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.Draw"
local F3DFlyawayRenderer = {}
local F3DMainCamera = require "F3D.camera.Main"
local F3DRender = require "F3D.render.Render"
local F3DRenderVisibility = require "F3D.camera.Visibility"
local F3DVector = require "F3D.necro3d.Vector"

local AnimationTimer = require "necro.render.AnimationTimer"
local Beatmap = require "necro.audio.Beatmap"
local Camera = require "necro.render.Camera"
local Collision = require "necro.game.tile.Collision"
local Color = require "system.utils.Color"
local ECS = require "system.game.Entities"
local Flyaway = require "necro.game.system.Flyaway"
local Focus = require "necro.game.character.Focus"
local GFX = require "system.gfx.GFX"
local InstantReplay = require "necro.client.replay.InstantReplay"
local Inventory = require "necro.game.item.Inventory"
local Localization = require "system.i18n.Localization"
local Menu = require "necro.menu.Menu"
local PriceTag = require "necro.game.item.PriceTag"
local Render = require "necro.render.Render"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local TextLabelRenderer = require "necro.render.level.TextLabelRenderer"
local Tick = require "necro.cycles.Tick"
local UI = require "necro.render.UI"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local getAnimationTime = AnimationTimer.getTime
local getReferencedAnimationTime = AnimationTimer.getReferencedAnimationTime
local isSegmentVisibleAt = SegmentVisibility.isVisibleAt
local invTS = 1 / Render.TILE_SIZE

local fontSmall = Utilities.mergeTables(Utilities.fastCopy(UI.Font.SMALL), {})
local noteFont = Utilities.mergeTables(Utilities.fastCopy(UI.Font.MEDIUM), { shadowColor = false })
local noteText = UI.Symbol.EIGHTH_NOTES
local drawTextArgs = {
	alignX = nil,
	alignY = nil,
	opacity = nil,
	text = nil,
}

function F3DFlyawayRenderer.renderFlyaway(instance, factor)
	if not (instance.worldX and instance.worldY and isSegmentVisibleAt(instance.worldX, instance.worldY)) then
		return
	end

	factor = math.max(factor, 0)
	local x, z = F3DRender.getTileCenter(instance.worldX, instance.worldY)
	drawTextArgs.alignX = instance.alignX
	drawTextArgs.alignY = instance.alignY
	drawTextArgs.opacity = (1 - factor) / instance.fadeOut
	drawTextArgs.text = instance.text
	F3DDraw.text(x, 1 + (factor * instance.distance) * invTS, z, drawTextArgs, instance.text == noteText and noteFont or fontSmall)
end

local renderFlyaway = F3DFlyawayRenderer.renderFlyaway

event.render.add("renderFlyaways", "flyaways", function()
	if not SettingsStorage.get "video.flyaways" then
		return
	end

	for _, instance in ipairs(Flyaway.getAll()) do
		local time = getReferencedAnimationTime(instance.animationID, instance.turnID, "flyaway")

		renderFlyaway(instance, (time - instance.delay) / instance.duration)
	end

	for _, instance in ipairs(Flyaway.getLocal()) do
		local time = getAnimationTime() - instance.animationTime

		renderFlyaway(instance, time / instance.duration)
	end
end)
