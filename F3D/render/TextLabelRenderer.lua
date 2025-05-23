local F3DEntity = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.Draw"
local F3DTextLabelRenderer = {}
local F3DMainCamera = require "F3D.camera.Main"
local F3DRender = require "F3D.render.Render"
local F3DRenderVisibility = require "F3D.camera.Visibility"
local F3DVector = require "F3D.necro3d.Vector"

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

local checkCollision = Collision.check
local clamp = Utilities.clamp
local distanceL1 = Utilities.distanceL1
local drawImage = F3DDraw.image
local drawText = F3DDraw.text
local drawTextY = F3DDraw.textY
local getEntityByID = ECS.getEntityByID
local getPosition3D = F3DEntity.getPosition
local checkEntityVisibility = F3DRenderVisibility.checkEntity
local isInstantReplayActive = InstantReplay.isActive
local isRevealed = Vision.isRevealed
local isSegmentVisible = SegmentVisibility.isVisibleAt
local invTS = 1 / Render.TILE_SIZE
local lerp = Utilities.lerp
local min = math.min
local sqrt = math.sqrt
local squareDistance = Utilities.squareDistance
local step = Utilities.step

local fontDigits = Utilities.fastCopy(UI.Font.DIGITS)
local fontSmall = Utilities.fastCopy(UI.Font.SMALL)
fontDigits.size = 4
fontSmall.size = 4

event.render.add("renderItemStackSizes", "itemStackSizes", function(ev)
	for entity in ECS.entitiesWithComponents {
		"F3D_itemStackQuantityLabelWorld",
		"F3D_position",
		"itemStack",
		"itemStackQuantityLabelWorld",
		"visibility",
	} do
		if entity.visibility.visible and (not entity.silhouette or not entity.silhouette.active) and entity.itemStack.quantity >= entity.itemStackQuantityLabelWorld.minimumQuantity then
			local position3D = getPosition3D(entity)
			drawText(position3D.x, position3D.y + entity.F3D_itemStackQuantityLabelWorld.offsetY, position3D.z, {
				alignY = 1,
				text = Inventory.formatQuantity(entity.itemStack.quantity),
			}, fontSmall, F3DRender.ZOrder.TextLabel)
		end
	end
end)

event.render.add("renderSecretShopLabels", "secretShopLabels", function(ev)
	if isInstantReplayActive() then
		return
	end

	for entity in ECS.entitiesWithComponents {
		"F3D_secretShopLabel",
		"position",
		"secretShopLabel",
		"visibility",
	} do
		if entity.visibility.visible and (not entity.provokable or not entity.provokable.active) and entity.secretShopLabel.visible then
			local position = entity.homePosition or entity.position
			local player = Focus.getNearest(position.x, position.y, Focus.Flag.TEXT_LABEL)
			local cost = PriceTag.getEffectiveCost(player, entity)
			local x, z = F3DRender.getTileCenter(position.x, position.y)

			drawTextY(x + entity.F3D_secretShopLabel.offsetX, 0, z + entity.F3D_secretShopLabel.offsetZ, {
				alignX = .5,
				alignY = 1,
				spacingY = 1,
				text = entity.secretShopLabel.text:format(cost),
			}, fontSmall, F3DRender.ZOrder.TextLabel)
		end
	end
end)

local function isPriceTagVisible(entity)
	return entity.priceTag and entity.priceTagLabel and entity.priceTag.active
end

event.render.add("renderPriceTags", "priceTags", function()
	for saleEntity in ECS.entitiesWithComponents {
		"position",
		"sale",
		"visibility",
	} do
		if saleEntity.visibility.visible and not (saleEntity.silhouette and saleEntity.silhouette.active) then
			local priceEntity = getEntityByID(saleEntity.sale.priceTag)

			if priceEntity and saleEntity.F3D_position and priceEntity.F3D_priceTagLabel and isPriceTagVisible(priceEntity) then
				local player = Focus.getNearest(saleEntity.position.x, saleEntity.position.y, Focus.Flag.TEXT_LABEL)
				local result = PriceTag.check(player, priceEntity)
				local cost = result.effectiveCost

				if cost > 0 then
					local position3D = F3DEntity.getPosition(saleEntity)
					local x = position3D.x + priceEntity.F3D_priceTagLabel.offsetX
					local y = position3D.y + priceEntity.F3D_priceTagLabel.offsetY
					local z = position3D.z + priceEntity.F3D_priceTagLabel.offsetY

					if saleEntity.F3D_salePriceTagOffset then
						x, z = x + saleEntity.F3D_salePriceTagOffset.offsetX, z + saleEntity.F3D_salePriceTagOffset.offsetZ
					end

					local opacity = result.coupon and 0.4 or 1
					if priceEntity.priceTagLabelInlineImage then
						drawText(x, y, z, {
							alignX = .5,
							text = cost * priceEntity.priceTagLabelInlineImage.costMultiplier,
							opacity = opacity,
						}, fontDigits, F3DRender.ZOrder.TextLabel, F3DRender.ZOrder.TextLabel)

						-- TODO
						-- local w, h = GFX.getImageSize(priceEntity.priceTagLabelInlineImage.texture)
						-- drawImage(x, y, z, w, h,
						-- 	priceEntity.priceTagLabelInlineImage.texture, 0, 0, w, h,
						-- 	opacity, F3DRender.ZOrder.TextLabel)
						-- drawImage(priceEntity.priceTagLabelInlineImage.texture, rect.x + rect.width + 1, rect.y, rect.y - 48, opacity)
					else
						drawText(x, y, z, {
							alignX = .5,
							text = cost,
							opacity = opacity,
						}, fontDigits, F3DRender.ZOrder.TextLabel)
					end
				end
			end
		end
	end
end)

function F3DTextLabelRenderer.isFocusedEntityClose(entity)
	local itemHintsDistance

	for _, focusedEntity in ipairs(Focus.getAll(Focus.Flag.TEXT_LABEL)) do
		itemHintsDistance = itemHintsDistance or SettingsStorage.get "video.itemHintsDistance"
		local distance = distanceL1(focusedEntity.position.x - entity.position.x, focusedEntity.position.y - entity.position.y)

		if distance > 0 and distance <= itemHintsDistance then
			return true
		end
	end
end

local isFocusedEntityClose = F3DTextLabelRenderer.isFocusedEntityClose

event.render.add("renderItemHintLabels", "hintLabels", function(ev)
	if isInstantReplayActive() then
		return
	end

	local bItemHints = SettingsStorage.get "video.itemHints"
	local bItemNames = SettingsStorage.get "video.itemNames"

	if bItemHints or bItemNames then
		for entity in ECS.entitiesWithComponents {
			"itemHintLabel",
			"position",
			"visibility",
		} do
			if entity.visibility.visible and (not entity.silhouette or not entity.silhouette.active) then
				local text

				if bItemHints and entity.itemHintLabel.text ~= "" and isFocusedEntityClose(entity) then
					text = entity.itemHintLabel.text
				elseif bItemNames then
					text = entity.friendlyName and entity.friendlyName.name or entity.name
				else
					goto continue
				end

				local adjacentY = 0
				if bItemNames then
					adjacentY = .25
				end

				local tx = entity.position.x
				local ty = entity.position.y
				if (tx + ty) % 2 == 1
					and (checkCollision(tx + 1, ty, Collision.Type.ITEM)
						or checkCollision(tx, ty - 1, Collision.Type.ITEM)
						or checkCollision(tx - 1, ty, Collision.Type.ITEM)
						or checkCollision(tx, ty + 1, Collision.Type.ITEM))
				then
					adjacentY = adjacentY + .25
				end

				local x, z = F3DRender.getTileCenter(entity.position.x, entity.position.y)
				drawText(x, .75 + adjacentY, z, {
					alignX = .5,
					text = text,
				}, fontSmall, F3DRender.ZOrder.TextLabel)
			end

			::continue::
		end
	end

	if bItemNames then
		for entity in ECS.entitiesWithComponents {
			"itemCurrencyLabel",
			"itemStack",
			"position",
			"visibility",
		} do
			if entity.visibility.visible and (not entity.silhouette or not entity.silhouette.active) and entity.itemStack.quantity >= entity.itemCurrencyLabel.minimumQuantity then
				local x, z = F3DRender.getTileCenter(entity.position.x, entity.position.y)
				drawText(x, .75, z, {
					alignX = .5,
					text = entity.itemStack.quantity .. entity.itemCurrencyLabel.suffix,
				}, fontSmall, F3DRender.ZOrder.TextLabel)
			end
		end
	end
end)

local labelOpacities = {}

function F3DTextLabelRenderer.getLabelOpacities()
	return labelOpacities
end

event.gameStateLevel.add("resetLabelOpacities", "resetLevelVariables", function()
	labelOpacities = {}
end)

local function updateLabelOpacities(factor)
	for label in ECS.entitiesWithComponents { "worldLabelHideDuringMenu" } do
		local targetOpacity = Menu.isOpen() and 0 or 1

		labelOpacities[label.id] = lerp(labelOpacities[label.id] or targetOpacity, targetOpacity, factor)
	end

	for label in ECS.entitiesWithComponents { "worldLabelFade" } do
		local sqDist = select(2, Focus.getNearestWithDistance(label.position.x, label.position.y, Focus.Flag.TEXT_LABEL))
		local maxDistance = label.worldLabelFade.maxDistance
		local targetOpacity = lerp(1.44 - min(sqDist, maxDistance) * label.worldLabelFade.falloff, 0,
			step(maxDistance, sqDist))

		labelOpacities[label.id] = clamp(0,
			lerp(labelOpacities[label.id] or targetOpacity, targetOpacity, factor * label.worldLabelFade.factor), 1)
	end

	for label in ECS.entitiesWithComponents { "worldLabelBlink" } do
		if Beatmap.getPrimary().getMusicBeatFraction() > 0.75 then
			labelOpacities[label.id] = 0
		else
			local sqDist = select(2, Focus.getNearestWithDistance(label.position.x, label.position.y, Focus.Flag.TEXT_LABEL))

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
	for label in ECS.entitiesWithComponents { "worldLabelHideNearFlyaway" } do
		if label.visibility.visible then
			if not occlusionTable then
				occlusionTable = {}
				for _, instance in ipairs(Flyaway.getAll()) do
					local tileX = math.floor((instance.x or 0) / 24 + 0.5)
					local tileY = (instance.y or 0) / 24

					if occlusionTable[tileX] then
						occlusionTable[tileX] = math.max(occlusionTable[tileX], tileY)
					else
						occlusionTable[tileX] = tileY
					end
				end
			end

			local occlusionY = occlusionTable[label.position.x]
			local targetOpacity = occlusionY and clamp(0, label.position.y - occlusionY, 1) or 1

			labelOpacities[label.id] = lerp(labelOpacities[label.id] or targetOpacity, targetOpacity, factor)
		end
	end
end

event.render.add("renderWorldLabels", "worldLabels", function(ev)
	if isInstantReplayActive() then
		return
	end

	updateLabelOpacities(1 - 0.9 ^ Tick.getFloatDeltaTicks())

	local minX, minY, maxX, maxY = Camera.getVisibleTileRect()
	maxX, maxY = minX + maxX, minY + maxY
	local worldLabelDrawTextArgs = {
		alignX = .5,
		size = 6,
	}

	for entity in ECS.entitiesWithComponents {
		"F3D_position",
		"F3D_worldLabel",
		"worldLabel",
	} do
		local tx, ty = entity.position.x, entity.position.y

		if minX <= tx and tx <= maxX and minY <= ty and ty <= maxY then
			local opacity = labelOpacities[entity.id] or 1

			if isRevealed(tx, ty) and isSegmentVisible(tx, ty) and opacity > .00390625 then
				local position3D = getPosition3D(entity)
				local x = position3D.x
				local y = position3D.y
				local z = position3D.z
				worldLabelDrawTextArgs.text = entity.worldLabel.text
				worldLabelDrawTextArgs.alignY = entity.worldLabel.alignY
				worldLabelDrawTextArgs.opacity = labelOpacities[entity.id] or 1
				F3DDraw.text(x + entity.worldLabel.offsetX * invTS, y, z - entity.worldLabel.offsetY * invTS, worldLabelDrawTextArgs, fontSmall)
			end
		end
	end
end)

--- @diagnostic disable-next-line: redefined-local
labelOpacities = script.persist(function()
	return labelOpacities
end)

return F3DTextLabelRenderer
