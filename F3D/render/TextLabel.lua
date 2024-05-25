local F3DCamera = require "F3D.Camera"
local F3DOverrideRenderer = require "F3D.render.Override"
local F3DTextLabelRenderer = {}
local F3DViewport = require "F3D.render.Viewport"

local Beatmap = require "necro.audio.Beatmap"
local Color = require "system.utils.Color"
local ECS = require "system.game.Entities"
local Flyaway = require "necro.game.system.Flyaway"
local Focus = require "necro.game.character.Focus"
local InstantReplay = require "necro.client.replay.InstantReplay"
local Inventory = require "necro.game.item.Inventory"
local Localization = require "system.i18n.Localization"
local Menu = require "necro.menu.Menu"
local PriceTag = require "necro.game.item.PriceTag"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local Settings = require "necro.config.Settings"
local TextLabelRenderer = require "necro.render.level.TextLabelRenderer"
local Tick = require "necro.cycles.Tick"
local UI = require "necro.render.UI"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local WHITE = Color.WHITE
local abs = math.abs
local clamp = Utilities.clamp
local drawText = UI.drawText
local fade = Color.fade
local getCameraPositionOffset = F3DCamera.getPositionOffset
local isInstantReplayActive = InstantReplay.isActive
local isRevealed = Vision.isRevealed
local isSegmentVisible = SegmentVisibility.isVisibleAt
local lerp = Utilities.lerp
local min = math.min
local sqrt = math.sqrt
local squareDistance = Utilities.squareDistance
local step = Utilities.step
local viewportTransformVector = F3DViewport.transformVector

_G.SettingGroupTextLabel = Settings.overridable.group {
	id = "render.textLabel",
	name = "Text label renderer",
}

SettingTextLabelMaxDistance = Settings.overridable.number {
	id = "render.textLabel.maxDistance",
	name = "World label max draw distance",
	desc = "L2 distance",
	default = 20,
}

SettingTextLabelScale = Settings.overridable.number {
	id = "render.textLabel.scale",
	name = "Scale factor",
	default = 1,
}

local labelOpacities = {}
local labelGlobalScale = 1 / 96

function F3DTextLabelRenderer.renderItemStackSizes(buffer, camera, rect)
	local maxDistL2 = SettingTextLabelMaxDistance
	local scale = SettingTextLabelScale * labelGlobalScale

	local drawTextArgs = {
		buffer = buffer,
		font = Utilities.fastCopy(UI.Font.MEDIUM),
	}

	for entity in ECS.entitiesWithComponents {
		"F3D_label3D",
		"itemStackQuantityLabelWorld",
		"itemStack",
		"position",
		"rowOrder",
		"visibility",
	} do
		if not entity.visibility.visible or (entity.silhouette and entity.silhouette.active) then
			goto continue
		end

		local dx, dy = getCameraPositionOffset(camera, entity.position.x, entity.position.y)
		if abs(dx) + abs(dy) > maxDistL2 then
			goto continue
		end

		local labelComponent = entity.itemStackQuantityLabelWorld
		if entity.itemStack.quantity < labelComponent.minimumQuantity then
			goto continue
		end

		local px, py, tx, ty = viewportTransformVector(camera, rect, dx, dy)
		if not px then
			goto continue
		end

		local sizeScale = rect[4] / ty * scale

		drawTextArgs.alignX = 0
		drawTextArgs.alignY = 1
		drawTextArgs.opacity = labelOpacities[entity.id] or 1
		drawTextArgs.size = drawTextArgs.font.size * sizeScale
		drawTextArgs.text = Inventory.formatQuantity(entity.itemStack.quantity)
		drawTextArgs.x = px
		drawTextArgs.y = py
		drawTextArgs.z = entity.F3D_label3D.zOrder - sqrt(squareDistance(dx, dy))

		drawText(drawTextArgs)

		::continue::
	end
end

event.F3D_renderViewport.add("renderItemStackSizes", "worldLabels", function(ev)
	F3DTextLabelRenderer.renderItemStackSizes(ev.buffer, ev.camera, ev.rect)
end)

function F3DTextLabelRenderer.renderPriceTags(buffer, camera, rect)
	local drawTextArgs = {
		buffer = buffer,
		font = UI.Font.DIGITS,
	}
	local scale = labelGlobalScale * SettingTextLabelScale

	local function drawNumber(number, x, y, opacity, vy, z)
		drawTextArgs.text = tostring(number)
		drawTextArgs.size = drawTextArgs.font.size * rect[4] / vy * scale
		drawTextArgs.x = x
		drawTextArgs.y = y
		drawTextArgs.opacity = opacity
		drawTextArgs.z = z

		return drawText(drawTextArgs)
	end

	for entity in ECS.entitiesWithComponents {
		"F3D_label3D",
		"position",
		"sale",
		"visibility",
	} do
		if not entity.visibility.visible then
			goto continue
		end

		local priceEntity = ECS.getEntityByID(entity.sale.priceTag)
		if not (priceEntity and priceEntity.priceTag and priceEntity.priceTagLabel and priceEntity.priceTag.active) then
			goto continue
		end

		local player = Focus.getNearest(entity.position.x, entity.position.y, Focus.Flag.TEXT_LABEL)
		local result = PriceTag.check(player, priceEntity)
		local cost = result.effectiveCost
		if cost <= 0 then
			goto continue
		end

		local dx, dy = getCameraPositionOffset(camera, entity.position.x, entity.position.y)
		local px, py, vx, vy = viewportTransformVector(camera, rect, dx, dy)
		if not px then
			goto continue
		end

		if entity.salePriceTagOffset then
			px, py = px + entity.salePriceTagOffset.offsetX, py + entity.salePriceTagOffset.offsetY
		end

		px, py = px + priceEntity.priceTagLabel.offsetX, py + priceEntity.priceTagLabel.offsetY

		local opacity = result.coupon and 0.4 or 1
		local z = entity.F3D_label3D.zOrder - sqrt(squareDistance(dx, dy))

		if priceEntity.priceTagLabelInlineImage then
			local drawRect = drawNumber(cost * priceEntity.priceTagLabelInlineImage.costMultiplier,
				px, py, opacity, vy, z)

			-- drawImage(priceEntity.priceTagLabelInlineImage.texture,
			-- 	drawRect.x + drawRect.width + 1, drawRect.y, drawRect.y - 48, opacity)
		else
			drawNumber(cost, px, py, opacity, vy, z)
		end

		::continue::
	end
end

event.F3D_renderViewport.add("renderPriceTags", "worldLabels", function(ev)
	F3DTextLabelRenderer.renderPriceTags(ev.buffer, ev.camera, ev.rect)
end)

function F3DTextLabelRenderer.renderWorldLabels(buffer, camera, rect)
	local cx = camera[F3DCamera.Field.PositionX]
	local cy = camera[F3DCamera.Field.PositionY]
	local enableWordWrap = Localization.getLoadedLanguageID() ~= nil or nil
	local maxDistL2 = SettingTextLabelMaxDistance
	local scale = labelGlobalScale * SettingTextLabelScale

	local drawTextArgs = {
		buffer = buffer,
		font = Utilities.fastCopy(UI.Font.MEDIUM)
	}

	for entity in ECS.entitiesWithComponents { "F3D_label3D", "worldLabel", "position" } do
		local ex = entity.position.x
		local ey = entity.position.y
		if abs(cx - ex) + abs(cy - ey) > maxDistL2 or not isRevealed(ex, ey) or not isSegmentVisible(ex, ey) then
			goto continue
		end

		local px, py, vx, vy = viewportTransformVector(camera, rect, getCameraPositionOffset(camera, ex, ey))
		if not px then
			goto continue
		end

		local sizeScale = rect[4] / vy * scale
		local wrap = entity.worldLabelMaxWidth and (enableWordWrap or entity.worldLabelMaxWidth.force)

		drawTextArgs.alignX = .5
		drawTextArgs.alignY = entity.worldLabel.alignY
		drawTextArgs.maxWidth = wrap and (entity.worldLabelMaxWidth.width * sizeScale)
		drawTextArgs.opacity = labelOpacities[entity.id] or 1
		drawTextArgs.size = drawTextArgs.font.size * sizeScale
		drawTextArgs.spacingY = entity.worldLabel.spacingY
		drawTextArgs.text = entity.worldLabel.text
		drawTextArgs.wordWrap = wrap
		drawTextArgs.x = rect[1] + px
		drawTextArgs.y = rect[2] + py
		drawTextArgs.z = entity.F3D_label3D.zOrder - sqrt(squareDistance(abs(cx - ex), abs(cy - ey)))

		drawText(drawTextArgs)

		::continue::
	end
end

--- @param ev Event.F3D_renderViewport
event.F3D_renderViewport.add("renderWorldLabels", "worldLabels", function(ev)
	if not isInstantReplayActive() then
		F3DTextLabelRenderer.renderWorldLabels(ev.buffer, ev.camera, ev.rect)
	end
end)

event.render.add("spriteCopyTextOpacity", "worldLabels", function()
	if not F3DOverrideRenderer.isHiding2DRenderer() then
		return
	end

	for entity in ECS.entitiesWithComponents { "spriteCopyTextOpacity", "sprite" } do
		entity.sprite.color = fade(WHITE, labelOpacities[entity.id] or 1)
	end
end)

event.render.add("updateWorldLabelOpacities", "worldLabels", function()
	if not F3DOverrideRenderer.isHiding2DRenderer() then
		return
	end

	local factor = 1 - 0.9 ^ Tick.getFloatDeltaTicks()

	for entity in ECS.entitiesWithComponents { "worldLabelHideDuringMenu" } do
		local targetOpacity = Menu.isOpen() and 0 or 1
		labelOpacities[entity.id] = lerp(labelOpacities[entity.id] or targetOpacity, targetOpacity, factor)
	end

	for entity in ECS.entitiesWithComponents { "position", "worldLabelFade" } do
		local sqDist = select(2,
			Focus.getNearestWithDistance(entity.position.x, entity.position.y, Focus.Flag.TEXT_LABEL))
		local maxDistance = entity.worldLabelFade.maxDistance
		local targetOpacity = lerp(1.44 - min(sqDist, maxDistance) * entity.worldLabelFade.falloff,
			0, step(maxDistance, sqDist))

		labelOpacities[entity.id] = clamp(0,
			lerp(labelOpacities[entity.id] or targetOpacity, targetOpacity, factor * entity.worldLabelFade.factor), 1)
	end

	for label in ECS.entitiesWithComponents { "worldLabelBlink" } do
		if Beatmap.getPrimary().getMusicBeatFraction() > 0.75 then
			labelOpacities[label.id] = 0
		else
			local sqDist = select(2,
				Focus.getNearestWithDistance(label.position.x, label.position.y, Focus.Flag.TEXT_LABEL))

			labelOpacities[label.id] = sqDist > label.worldLabelBlink.maxDistance and 0 or 1
		end
	end

	for label in ECS.entitiesWithComponents { "worldLabelVisibleBySetting" } do
		local func = TextLabelRenderer.VisibilityOption.data[label.worldLabelVisibleBySetting.option].func

		if type(func) == "function" and not func(label) then
			labelOpacities[label.id] = 0
		end
	end

	local occlusionTable
	local function getFlyawayOcclusionTable()
		for _, instance in ipairs(Flyaway.getAll()) do
			local tileX = math.floor((instance.x or 0) / 24 + 0.5)
			local tileY = (instance.y or 0) / 24

			if occlusionTable[tileX] then
				occlusionTable[tileX] = math.max(occlusionTable[tileX], tileY)
			else
				occlusionTable[tileX] = tileY
			end
		end

		return occlusionTable
	end

	for label in ECS.entitiesWithComponents { "worldLabelHideNearFlyaway" } do
		if label.visibility.visible then
			occlusionTable = occlusionTable or getFlyawayOcclusionTable()

			local occlusionY = occlusionTable[label.position.x]
			local targetOpacity = occlusionY and clamp(0, label.position.y - occlusionY, 1) or 1

			labelOpacities[label.id] = lerp(labelOpacities[label.id] or targetOpacity, targetOpacity, factor)
		end
	end
end)

return F3DTextLabelRenderer
