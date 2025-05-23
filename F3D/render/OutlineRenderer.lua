local F3DCharacter = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.SpriteRenderer"
local F3DOutlineRenderer = {}
local F3DSpriteRenderer = require "F3D.render.SpriteRenderer"

local Color = require "system.utils.Color"
local ECS = require "system.game.Entities"
local OutlineFilter = require "necro.render.filter.OutlineFilter"
local Perspective = require "necro.game.system.Perspective"
local Render = require "necro.render.Render"
local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local drawSpriteVisual = F3DSpriteRenderer.drawSpriteVisual
local invColorStep = 0.00392156862745098
local invTS = 1 / Render.TILE_SIZE
local isPerspectiveShadowed = Vision.isPerspectiveShadowed

function F3DOutlineRenderer.padOutlineVisual(visual, frameOffsetX, frameOffsetY)
	local dx1 = (visual.x2 - visual.x1) * invTS
	local dy1 = (visual.y2 - visual.y1) * invTS
	local dz1 = (visual.z2 - visual.z1) * invTS
	local dx2 = (visual.x3 - visual.x1) * invTS
	local dy2 = (visual.y3 - visual.y1) * invTS
	local dz2 = (visual.z3 - visual.z1) * invTS

	visual.x1 = visual.x1 - dx1
	visual.y1 = visual.y1 - dy1
	visual.z1 = visual.z1 - dz1
	visual.x1 = visual.x1 - dx2
	visual.y1 = visual.y1 - dy2
	visual.z1 = visual.z1 - dz2

	visual.x2 = visual.x2 + dx1
	visual.y2 = visual.y2 + dy1
	visual.z2 = visual.z2 + dz1
	visual.x2 = visual.x2 - dx2
	visual.y2 = visual.y2 - dy2
	visual.z2 = visual.z2 - dz2

	visual.x3 = visual.x3 - dx1
	visual.y3 = visual.y3 - dy1
	visual.z3 = visual.z3 - dz1
	visual.x3 = visual.x3 + dx2
	visual.y3 = visual.y3 + dy2
	visual.z3 = visual.z3 + dz2

	visual.x4 = visual.x4 + dx1
	visual.y4 = visual.y4 + dy1
	visual.z4 = visual.z4 + dz1
	visual.x4 = visual.x4 + dx2
	visual.y4 = visual.y4 + dy2
	visual.z4 = visual.z4 + dz2

	visual.tx = visual.tx + (frameOffsetX or 0) * 3
	visual.ty = visual.ty + (frameOffsetY or 0) * 3
	visual.tw = visual.tw + 2
	visual.th = visual.th + 2
	visual.ord = visual.ord + .001

	return visual
end

function F3DOutlineRenderer.getEntityOutlineVisual(entity, visual, mode)
	visual = visual or F3DSpriteRenderer.getSpriteVisual(entity)
	if entity.sprite then
		F3DOutlineRenderer.padOutlineVisual(visual, math.floor(visual.tx / entity.sprite.width), math.floor(visual.ty / entity.sprite.height))
	end
	visual.t = OutlineFilter.getEntityImage(entity, visual.t, mode)
	return visual
end

local getOutlineVisual = F3DOutlineRenderer.getEntityOutlineVisual

event.render.add("renderGoldOutlines", "outlines", function()
	local outlineColor = SettingsStorage.get "video.goldOutlineColor"

	if Color.getA(outlineColor) > 0 and Perspective.getAttribute(Perspective.Attribute.GOLD_OUTLINE) then
		local filterMode = OutlineFilter.Mode.BASIC

		for gold in ECS.entitiesWithComponents {
			"F3D_sprite",
			"position",
			"sprite",
			"spriteGoldOutline",
			"visibility",
		} do
			if gold.visibility.fullyVisible and not isPerspectiveShadowed(gold.position.x, gold.position.y) then
				local visual = getOutlineVisual(gold, nil, filterMode)
				visual.col = outlineColor
				drawSpriteVisual(visual)
			end
		end
	end
end)

event.render.add("renderSilhouetteOutlines", "outlines", function()
	if 1 then
		return
	end

	local intensity = SettingsStorage.get "video.silhouetteOutline.enemy"

	if intensity > invColorStep and not Perspective.getListAttribute(Perspective.Attribute.OBJECT_SILHOUETTE_GROUPS)[1] then
	end
end)

return F3DOutlineRenderer
