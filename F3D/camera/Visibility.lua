local F3DEntity = require "F3D.system.Entity"
local F3DRender = require "F3D.render.Render"
local F3DMainCamera = require "F3D.camera.Main"
local F3DMainCameraMode = require "F3D.camera.Mode"
local F3DMainCameraFirstPersonMode = require "F3D.camera.FirstPersonMode"
local F3DCameraVisibility = {}
local F3DUtilities = require "F3D.system.Utilities"

local ECS = require "system.game.Entities"
local Focus = require "necro.game.character.Focus"
local LocalCoop = require "necro.client.LocalCoop"
local OrderedSelector = require "system.events.OrderedSelector"
local Tile = require "necro.game.tile.Tile"
local Utilities = require "system.utils.Utilities"

local emptyTable = F3DUtilities.emptyTable
local getEntityPrototype = ECS.getEntityPrototype
local getPosition3D = F3DEntity.getPosition
local reduceCoordinates = Tile.reduceCoordinates

local entityInvisibilitySet = {}
local tileInvisibilitySet = {}

--- return false if the entity is invisible by camera.
--- @return boolean isInvisible
function F3DCameraVisibility.checkEntity(entity)
	return not entityInvisibilitySet[entity.id]
end

function F3DCameraVisibility.getTile(tx, ty)
	local i = reduceCoordinates(tx, ty)
	return i and tileInvisibilitySet[i] or emptyTable
end

local updateCameraVisibilitySelectorFire = OrderedSelector.new(event.F3D_updateCameraVisibilities, {
	"firstPersonLocatedWalls",
	"entitiesReset",
	"firstPersonTarget",
	"firstPersonHideCloser",
	"grabber",
	"attachments",
	"frustumCulling",
}).fire

event.F3D_updateCameraVisibilities.add("firstPersonLocatedWalls", "firstPersonLocatedWalls", function(ev)
	if F3DMainCameraMode.getData().fpv then
		local x, _, z = F3DMainCamera.getCurrent():getPosition()
		local tx, ty = F3DRender.getTileAt(x, z)
		if Tile.getInfo(tx, ty).isWall then
			ev.tiles[#ev.tiles + 1] = {
				index = reduceCoordinates(tx, ty),
				invisibility = { wall = true }
			}
		end
	end
end)

event.F3D_updateCameraVisibilities.add("entitiesReset", "entitiesReset", function()
	for entity in ECS.entitiesWithComponents { "F3D_visibility" } do
		if entity.visibility.visible then
			entity.F3D_visibility.visible = getEntityPrototype(entity.name).F3D_visibility.visible
		else
			entity.F3D_visibility.visible = false
		end
	end
end)

event.F3D_updateCameraVisibilities.add("firstPersonTarget", "firstPersonTarget", function(ev)
	local entity = F3DMainCameraFirstPersonMode.getTarget()
	if entity then
		ev.focusedEntity = entity
		ev.entities[#ev.entities + 1] = entity
	end
end)

event.F3D_updateCameraVisibilities.add("firstPersonHideCloser", "firstPersonHideCloser", function(ev)
	if F3DMainCameraMode.getData().fpv then
		local cx, _, cz = F3DMainCamera.getCurrent():getPosition()
		for entity in ECS.entitiesWithComponents { "F3D_cameraFirstPersonVisibilityHiddenIfTooClose" } do
			if entity.visibility.visible then
				local position3D = getPosition3D(entity)
				local dx = cx - position3D.x
				local dz = cz - position3D.z

				if dx * dx + dz * dz < entity.F3D_cameraFirstPersonVisibilityHiddenIfTooClose.squareDistance then
					ev.entities[#ev.entities + 1] = entity
				end
			end
		end
	end
end)

event.F3D_updateCameraVisibilities.add("grabber", "grabber", function(ev)
	local entity = ev.focusedEntity and ev.focusedEntity.grabbable and ECS.getEntityByID(ev.focusedEntity.grabbable.grabber)
	if entity then
		ev.grabber = entity
		ev.entities[#ev.entities + 1] = entity
	end
end)

event.F3D_updateCameraVisibilities.add("attachments", "attachments", function(ev)
	for i = 1, #ev.entities do
		local entity = ev.entities[i]
		if entity.characterWithAttachment then
			local attachmentEntity = ECS.getEntityByID(entity.characterWithAttachment.attachmentID)
			if attachmentEntity and attachmentEntity.visibility then
				ev.focusedEntityAttachment = attachmentEntity
				ev.entities[#ev.entities + 1] = attachmentEntity
			end
		end
	end
end)

event.render.add("updateCameraVisibilities", {
	order = "camera",
	sequence = 1e4,
}, function()
	local ev = {
		entities = {},
		tiles = {},
	}
	updateCameraVisibilitySelectorFire(ev)

	entityInvisibilitySet = {}
	for _, entity in ipairs(ev.entities) do
		entityInvisibilitySet[entity.id] = true
	end

	tileInvisibilitySet = {}
	for _, tile in pairs(ev.tiles) do
		tileInvisibilitySet[tile.index] = tile.invisibility
	end
end)

return F3DCameraVisibility
