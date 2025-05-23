local Render = require "necro.render.Render"

event.entitySchemaLoadEntity.add("itemStackQuantityLabelWorld", "overrides", function(ev)
	if ev.entity.F3D_itemStackQuantityLabelWorld == nil and type(ev.entity.itemStackQuantityLabelWorld) == "table" then
		ev.entity.F3D_itemStackQuantityLabelWorld = {}
	end
end)

event.entitySchemaLoadEntity.add("priceTagLabel", "overrides", function(ev)
	if ev.entity.F3D_priceTagLabel == nil and type(ev.entity.priceTagLabel) == "table" then
		ev.entity.F3D_priceTagLabel = {
			offsetX = (tonumber(ev.entity.priceTagLabel.offsetX) or 0) / Render.TILE_SIZE,
			offsetZ = (tonumber(ev.entity.priceTagLabel.offsetY) or 0) / -Render.TILE_SIZE,
		}
	end
end)

event.entitySchemaLoadEntity.add("salePriceTagOffset", "overrides", function(ev)
	if ev.entity.F3D_salePriceTagOffset == nil and type(ev.entity.salePriceTagOffset) == "table" then
		ev.entity.F3D_salePriceTagOffset = {
			offsetX = (tonumber(ev.entity.salePriceTagOffset.offsetX) or 0) / Render.TILE_SIZE,
			offsetZ = (tonumber(ev.entity.salePriceTagOffset.offsetY) or 0) / -Render.TILE_SIZE,
		}
	end
end)

event.entitySchemaLoadEntity.add("secretShopLabel", "overrides", function(ev)
	if ev.entity.F3D_secretShopLabel == nil and type(ev.entity.secretShopLabel) == "table" then
		ev.entity.F3D_secretShopLabel = {
			offsetX = (tonumber(ev.entity.secretShopLabel.offsetX) or 0) / Render.TILE_SIZE,
			offsetZ = (tonumber(ev.entity.secretShopLabel.offsetY) or 0) / -Render.TILE_SIZE + .5,
		}
	end
end)

event.entitySchemaLoadEntity.add("worldLabel", "overrides", function(ev)
	if ev.entity.F3D_worldLabel == nil and type(ev.entity.worldLabel) == "table" then
		ev.entity.F3D_worldLabel = {
			offsetX = (tonumber(ev.entity.worldLabel.offsetX) or 0) / Render.TILE_SIZE,
			offsetZ = (tonumber(ev.entity.worldLabel.offsetY) or -15) / -Render.TILE_SIZE,
		}
	end
end)
