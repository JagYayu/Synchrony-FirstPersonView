local F3DCharacter = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.Draw"
local F3DQuadsRenderer = {}
local F3DRender = require "F3D.render.Render"
local F3DTileRenderer = require "F3D.render.TileRenderer"
local F3DCameraVisibility = require "F3D.camera.Visibility"
local F3DUtilities = require "F3D.system.Utilities"

local Animations = require "necro.render.level.Animations"
local AnimationTimer = require "necro.render.AnimationTimer"
local Beatmap = require "necro.audio.Beatmap"
local Collision = require "necro.game.tile.Collision"
local ECS = require "system.game.Entities"
local Enum = require "system.utils.Enum"
local MoveAnimations = require "necro.render.level.MoveAnimations"
local OrderedSelector = require "system.events.OrderedSelector"
local Render = require "necro.render.Render"
local SpriteEffects = require "necro.render.level.SpriteEffects"
local Tile = require "necro.game.tile.Tile"
local TileTypes = require "necro.game.tile.TileTypes"
local Utilities = require "system.utils.Utilities"

local TILE_SIZE = Render.TILE_SIZE
local WALL = Collision.Type.WALL
local animateHop = MoveAnimations.animateHop
local checkEntityCameraVisibility = F3DCameraVisibility.checkEntity
local collisionCheck = Collision.check
local drawQuad = F3DDraw.quad
local emptyTable = F3DUtilities.emptyTable
local getPosition3D = F3DCharacter.getPosition
local ifNil = F3DUtilities.ifNil
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local type = type

function F3DQuadsRenderer.generateQuadsFrames(frames)
	local newFrames = {}
	for key, entries in pairs(frames) do
		local newEntries = {}
		for i, entry in ipairs(entries) do
			newEntries[i] = {
				tonumber(entry.x1) or 0,
				tonumber(entry.x2) or 0,
				tonumber(entry.x3) or 0,
				tonumber(entry.x4) or 0,
				tonumber(entry.y1) or 0,
				tonumber(entry.y2) or 0,
				tonumber(entry.y3) or 0,
				tonumber(entry.y4) or 0,
				tonumber(entry.z1) or 0,
				tonumber(entry.z2) or 0,
				tonumber(entry.z3) or 0,
				tonumber(entry.z4) or 0,
				entry.texture ~= nil and tostring(entry.texture) or nil,
				tonumber(entry.textureShiftX) or nil,
				tonumber(entry.textureShiftY) or nil,
				tonumber(entry.textureWidth) or nil,
				tonumber(entry.textureHeight) or nil,
				tonumber(entry.color) or nil,
				tonumber(entry.zOrder) or nil,
				ifNil(entry.customOrder, nil, not not entry.customOrder),
			}
		end
		newFrames[key] = newEntries
	end
	return newFrames
end

event.entitySchemaLoadEntity.add("validateCustomDrawFrames", "validation", function(ev)
	if type(ev.entity.F3D_quads) == "table" then
		ev.entity.F3D_quads.frames = type(ev.entity.F3D_quads.frames) == "table" and F3DQuadsRenderer.generateQuadsFrames(ev.entity.F3D_quads.frames) or {}
	end
end)

function F3DQuadsRenderer.renderQuads(quads, frame, x, y, z, colArg)
	x = (tonumber(x) or 0) + quads.offsetX
	y = (tonumber(y) or 0) + quads.offsetY
	z = (tonumber(z) or 0) + quads.offsetZ
	local t_ = quads.texture
	local tx_ = quads.textureShiftX
	local ty_ = quads.textureShiftY
	local tw_ = quads.textureWidth
	local th_ = quads.textureHeight
	local col_ = quads.color
	local ord_ = quads.zOrder
	local cstOrd_ = quads.customOrder
	frame = frame or quads.frame
	for i, entry in ipairs(quads.frames[frame] or emptyTable) do
		local x1 = x + entry[01]
		local x2 = x + entry[02]
		local x3 = x + entry[03]
		local x4 = x + entry[04]
		local y1 = y + entry[05]
		local y2 = y + entry[06]
		local y3 = y + entry[07]
		local y4 = y + entry[08]
		local z1 = z + entry[09]
		local z2 = z + entry[10]
		local z3 = z + entry[11]
		local z4 = z + entry[12]
		local t = entry[13] or t_
		local tx = entry[14] or tx_
		local ty = entry[15] or ty_
		local tw = entry[16] or tw_
		local th = entry[17] or th_
		local col = type(colArg) == "table" and tonumber(colArg[i]) or tonumber(colArg) or entry[18] or col_
		local ord = entry[19] or ord_
		local cstOrd = ifNil(entry[20], cstOrd_, entry[20])
		drawQuad(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4,
			t, tx, ty, tw, th, col, ord, cstOrd)
	end
end

local renderQuads = F3DQuadsRenderer.renderQuads

local renderQuadsSelectorFire = OrderedSelector.new(event.F3D_renderQuads, {
	"spriteSheet",
	"tileset",
	"facingDirection",
	"shift",
	"silhouette",
	"render",
}).fire

event.F3D_renderQuads.add("quadsFrameCopySpriteSheetX", "spriteSheet", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_quads",
		"F3D_quadsFrameCopySpriteSheetX",
		"spriteSheet",
	} do
		entity.F3D_quads.frame = entity.spriteSheet.frameX
	end
end)

event.F3D_renderQuads.add("quadsFrameUseTileset", "spriteSheet", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_quads",
		"F3D_quadsFrameUseTileset",
		"position",
	} do
		entity.F3D_quads.frame = entity.F3D_quadsFrameUseTileset.mapping[Tile.getInfo(entity.position.x, entity.position.y).tileset or false] or entity.F3D_quads.frame
	end
end)

event.F3D_renderQuads.add("quadsFrameConditionShiftSpriteSheetX", "shift", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_quads",
		"F3D_quadsFrameSpriteSheetXShifts",
		"spriteSheet",
	} do
		local shiftX = tonumber(entity.F3D_quadsFrameSpriteSheetXShifts.mapping[entity.spriteSheet.frameX])
		if shiftX then
			entity.F3D_quads.frame = entity.F3D_quads.frame + shiftX
		end
	end
end)

event.F3D_renderQuads.add("quadsFrameCopyFacingDirection", "facingDirection", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_quads",
		"F3D_quadsFrameCopyFacingDirection",
		"facingDirection",
		"visibility",
	} do
		entity.F3D_quads.frame = entity.facingDirection.direction
	end
end)

event.F3D_renderQuads.add("quadsFrameIfSilhouetteActive", "silhouette", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_quads",
		"F3D_quadsFrameIfSilhouetteActive",
		"spriteSheet",
		"silhouette",
	} do
		if entity.silhouette.active then
			entity.F3D_quads.frame = entity.F3D_quadsFrameIfSilhouetteActive.frame
		end
	end
end)

event.F3D_renderQuads.add("render", "render", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_quads",
		"F3D_position",
		"visibility",
		"!F3D_quadsApplyWallColor",
	} do
		if entity.visibility.visible and checkEntityCameraVisibility(entity) then
			local position3D = getPosition3D(entity)
			renderQuads(entity.F3D_quads, nil, position3D.x, position3D.y, position3D.z)
		end
	end

	local getWallColor = F3DTileRenderer.getWallColorArg
	for entity in ECS.entitiesWithComponents {
		"F3D_quads",
		"F3D_quadsApplyWallColor",
		"F3D_position",
		"position",
		"visibility",
	} do
		if entity.visibility.visible and checkEntityCameraVisibility(entity) then
			local position3D = getPosition3D(entity)
			renderQuads(entity.F3D_quads, nil, position3D.x, position3D.y, position3D.z, getWallColor(entity.position.x, entity.position.y))
		end
	end
end)

event.render.add("renderQuads", {
	order = "objects",
	sequence = 200,
}, renderQuadsSelectorFire)

return F3DQuadsRenderer
