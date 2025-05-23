local F3DCameraVisibility = require "F3D.camera.Visibility"
local F3DCharacter = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.Draw"
local F3DMainCamera = require "F3D.camera.Main"
local F3DRender = require "F3D.render.Render"
local F3DSpriteRenderer = {}
local F3DUtilities = require "F3D.system.Utilities"
local F3DVector = require "F3D.necro3d.Vector"

local Color = require "system.utils.Color"
local Currency = require "necro.game.item.Currency"
local CurrentLevel = require("necro.game.level.CurrentLevel")
local ECS = require "system.game.Entities"
local EntitySelector = require "system.events.EntitySelector"
local Enum = require "system.utils.Enum"
local GFX = require "system.gfx.GFX"
local ItemStorage = require "necro.game.item.ItemStorage"
local ObjectRenderer = require "necro.render.level.ObjectRenderer"
local Perspective = require "necro.game.system.Perspective"
local Render = require "necro.render.Render"
local Segment = require "necro.game.tile.Segment"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local Tile = require "necro.game.tile.Tile"

local checkEntityCameraVisibility = F3DCameraVisibility.checkEntity
local drawImage = F3DDraw.image
local drawQuad = F3DDraw.quad
local getEntityByID = ECS.getEntityByID
local getObjectVisual = ObjectRenderer.getObjectVisual
local getPosition3D = F3DCharacter.getPosition
local invTS = 1 / Render.TILE_SIZE
local vector2Normalize = F3DUtilities.vector2Normalize

local cameraX = 0
local cameraY = 0
local cameraZ = 0

event.render.add(nil, {
	order = "camera",
	sequence = 1e3,
}, function()
	cameraX, cameraY, cameraZ = F3DMainCamera.getCurrent():getPosition()
end)

local styleBillboardVisual
local styleFloorVisual
do
	local visual = {}

	styleBillboardVisual = function(entity)
		local position3D = getPosition3D(entity)
		local sprite = entity.sprite
		local sprite3D = entity.F3D_sprite
		local x = position3D.x + sprite3D.offsetX
		local y = position3D.y + sprite3D.offsetY
		local z = position3D.z + sprite3D.offsetZ
		local w = sprite.width * sprite3D.scaleX * invTS
		local h = sprite.height * sprite3D.scaleY * invTS

		local dx = x - cameraX
		local dz = z - cameraZ
		do
			dx, dz = vector2Normalize(dx, dz)
			dx, dz = dz, -dx
		end

		local x1, y1, z1
		local x2, y2, z2
		local x3, y3, z3
		local x4, y4, z4
		do
			local f = w * .5 * sprite.mirrorX
			local xl = x - dx * f
			local zl = z - dz * f
			local xr = x + dx * f
			local zr = z + dz * f
			x1 = xl
			y1 = y + h
			z1 = zl
			x2 = xr
			y2 = y + h
			z2 = zr
			x3 = xl
			y3 = y
			z3 = zl
			x4 = xr
			y4 = y
			z4 = zr
		end
		local tx = sprite.textureShiftX
		local ty = sprite.textureShiftY
		local tw = sprite.width
		local th = sprite.height

		do
			local crop = entity.croppedSprite
			if crop then
				if crop.right ~= 0 then
					local v = crop.right
					tw = tw - v
					v = v * invTS
					x2 = x2 - v * dx
					z2 = z2 - v * dz
					x4 = x4 - v * dx
					z4 = z4 - v * dz
				end
				if crop.top ~= 0 then
					local v = crop.top
					ty = ty + v
					th = th - v
					v = v * invTS
					y1 = y1 - v
					y2 = y2 - v
				end
				if crop.left ~= 0 then
					local v = crop.left
					tx = tx + v
					tw = tw - v
					v = v * invTS
					x1 = x1 + v * dx
					z1 = z1 + v * dz
					x3 = x3 + v * dx
					z3 = z3 + v * dz
				end
				if crop.bottom ~= 0 then
					local v = crop.bottom
					th = th - v
					v = v * invTS
					y1 = y1 - v
					y2 = y2 - v
				end
			end
		end

		if entity.rotatedSprite and entity.rotatedSprite.angle ~= 0 then
			local a = entity.rotatedSprite.angle
			local ox = x1 + entity.rotatedSprite.originX * invTS * dx
			local oy = z1 + entity.rotatedSprite.originX * invTS * dz

			x1, z1 = F3DUtilities.vector2RotateAround(x, y, ox, oy, a)
			x2, z2 = F3DUtilities.vector2RotateAround(x, y, ox, oy, a)
			x3, z3 = F3DUtilities.vector2RotateAround(x, y, ox, oy, a)
			x4, z4 = F3DUtilities.vector2RotateAround(x, y, ox, oy, a)
		end

		visual.x1 = x1
		visual.y1 = y1
		visual.z1 = z1
		visual.x2 = x2
		visual.y2 = y2
		visual.z2 = z2
		visual.x3 = x3
		visual.y3 = y3
		visual.z3 = z3
		visual.x4 = x4
		visual.y4 = y4
		visual.z4 = z4
		visual.t = sprite.texture
		visual.tx = tx
		visual.ty = ty
		visual.tw = tw
		visual.th = th
		visual.col = sprite.color
		visual.ord = sprite3D.zOrder

		return visual
	end

	styleFloorVisual = function(entity)
		local sprite = entity.sprite
		local position3D = getPosition3D(entity)
		local sprite3D = entity.F3D_sprite
		local x = position3D.x + sprite3D.offsetX
		local y = position3D.y + sprite3D.offsetY
		local z = position3D.z + sprite3D.offsetZ
		local w = sprite.width * invTS
		local h = sprite.height * invTS
		local hw = w * .5
		local hh = h * .5

		local objectVisual = getObjectVisual(entity)

		visual.x1 = x - hw
		visual.y1 = y
		visual.z1 = z + hh
		visual.x2 = x + hw
		visual.y2 = y
		visual.z2 = z + hh
		visual.x3 = x - hw
		visual.y3 = y
		visual.z3 = z - hh
		visual.x4 = x + hw
		visual.y4 = y
		visual.z4 = z - hh
		visual.t = objectVisual.texture
		visual.tx = objectVisual.texRect[1]
		visual.ty = objectVisual.texRect[2]
		visual.tw = objectVisual.texRect[3]
		visual.th = objectVisual.texRect[4]
		visual.col = objectVisual.color
		visual.ord = sprite3D.zOrder
		-- TODO support vertex animation -- visual.anim = objectVisual.anim
		return visual
	end
end

F3DSpriteRenderer.Style = Enum.sequence {
	Billboard = Enum.data(styleBillboardVisual),
	--- @warn Does not apply `croppedSprite` and `rotatedSprite` by default.
	Floor = Enum.data(styleFloorVisual),
}
local dataStyle = F3DSpriteRenderer.Style.data

function F3DSpriteRenderer.getSpriteVisual(entity)
	assert(entity.F3D_sprite, "missing component F3D_sprite")
	local getVisual = dataStyle[entity.F3D_sprite.style]
	return getVisual and getVisual(entity)
end

local animateSpriteSelectorFire = EntitySelector.new(event.F3D_animateSprite, {
	"reset",
	"hover",
	"wallOffset",
	"vibrate",
}).fire

function F3DSpriteRenderer.drawSpriteVisual(visual)
	drawQuad(visual.x1, visual.y1, visual.z1,
		visual.x2, visual.y2, visual.z2,
		visual.x3, visual.y3, visual.z3,
		visual.x4, visual.y4, visual.z4,
		visual.t, visual.tx, visual.ty, visual.tw, visual.th,
		visual.col, visual.ord)
end

local drawSpriteVisual = F3DSpriteRenderer.drawSpriteVisual

event.render.add("renderSprites", {
	order = "objects",
	sequence = 100,
}, function()
	for entity in ECS.entitiesWithComponents {
		"F3D_sprite",
		"position",
		"sprite",
		"visibility",
	} do
		if entity.sprite.visible and entity.visibility.visible and checkEntityCameraVisibility(entity) then
			animateSpriteSelectorFire(entity, entity.name)

			local getVisual = dataStyle[entity.F3D_sprite.style]
			if getVisual then
				drawSpriteVisual(getVisual(entity))
			end
		end
	end
end)

event.render.add("attachmentCopySpritePosition", {
	order = "spriteDependencies",
	sequence = 1,
}, function()
	for entity in ECS.entitiesWithComponents {
		"F3D_attachmentCopySpritePosition",
		"F3D_position",
		"attachment",
	} do
		local target = getEntityByID(entity.attachment.parent)
		if target and target.F3D_position then
			local position3D = getPosition3D(entity)
			local targetPosition3D = getPosition3D(target)
			position3D.x = targetPosition3D.x + entity.F3D_attachmentCopySpritePosition.offsetX
			position3D.y = targetPosition3D.y + entity.F3D_attachmentCopySpritePosition.offsetY
			position3D.z = targetPosition3D.z + entity.F3D_attachmentCopySpritePosition.offsetZ
		end
	end
end)

--- @type { [1]: number, [2]: number } | false
CachedWallGoldPosition = false

function F3DSpriteRenderer.getWallGoldPosition()
	return CachedWallGoldPosition or nil
end

function F3DSpriteRenderer.setWallGoldPosition(x, y)
	CachedWallGoldPosition = { x, y }
end

event.gameStateLevel.add("clearCacheWallGoldPosition", "resetLevelVariables", function(ev)
	CachedWallGoldPosition = false
end)

local function getWallGoldPosition()
	local segmentX, segmentY, segmentWidth, segmentHeight = Segment.getBounds(Segment.MAIN)

	for x = segmentX, segmentX + segmentWidth - 1 do
		for y = segmentY, segmentY + segmentHeight - 1 do
			local tileInfo = Tile.getInfo(x, y)

			if tileInfo.visibleByMonocle and (tileInfo.digEntity or tileInfo.digDiamonds) then
				return { x, y }
			end
		end
	end

	return { 0, 0 }
end

local function renderContent(item, container, offsetY)
	local x, z = F3DRender.getTileCenter(container.position.x, container.position.y)
	local visual = getObjectVisual(item)
	local h = item.sprite.height * item.F3D_sprite.scaleY * invTS
	drawImage(x, h + offsetY, z, item.sprite.width * item.F3D_sprite.scaleX * invTS, h,
		visual.texture, visual.texRect[1], visual.texRect[2], visual.texRect[3], visual.texRect[4],
		Color.fade(visual.color, .5), 4)
end

local function renderWallContent(item, tx, ty)
	local entity = ECS.getEntityPrototype(item)
	if not entity or not entity.F3D_sprite then
		return
	end

	local x, z = F3DRender.getTileCenter(tx, ty)
	local visual = getObjectVisual(entity)
	local h = entity.sprite.height * entity.F3D_sprite.scaleY * invTS
	drawImage(x, h, z, entity.sprite.width * entity.F3D_sprite.scaleX * invTS, h,
		visual.texture, visual.texRect[1], visual.texRect[2], visual.texRect[3], visual.texRect[4],
		visual.color, 5)
end

event.render.add("renderContents", "contents", function()
	for _, component in ipairs(Perspective.getListAttribute(Perspective.Attribute.CONTENTS_VISIBILITY_GROUPS)) do
		for entity in ECS.entitiesWithComponents {
			"storage",
			"visibility",
			"sprite",
			"positionalSprite",
			component,
		} do
			local items = ItemStorage.getItems(entity)
			local len = #items
			for i, item in ipairs(items) do
				if entity.visibility.visible and entity.sprite.visible and item and item.sprite then
					renderContent(item, entity, (i - (len + 1) * .5))
				end
			end
		end

		if component == "contentsVisibleByMonocle" then
			CachedWallGoldPosition = CachedWallGoldPosition or getWallGoldPosition()

			local x, y = CachedWallGoldPosition[1], CachedWallGoldPosition[2]
			local tileInfo = Tile.getInfo(x, y)

			if tileInfo.visibleByMonocle and SegmentVisibility.isVisibleAt(x, y) then
				if tileInfo.digDiamonds then
					local item = Currency.getItemForAmount(Currency.Type.DIAMOND, CurrentLevel.getZone())

					renderWallContent(item, x, y)
				elseif tileInfo.digEntity then
					renderWallContent(tileInfo.digEntity, x, y)
				end
			end
		end
	end
end)

return F3DSpriteRenderer
