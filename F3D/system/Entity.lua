local F3DEntity = {}
local F3DMainCameraMode = require "F3D.camera.Mode"
local F3DUtilities = require "F3D.system.Utilities"

local Action = require "necro.game.system.Action"

local ECS = require "system.game.Entities"

local Focus = require "necro.game.character.Focus"
local GameInput = require "necro.client.Input"
local Player = require "necro.game.character.Player"
local SettingsStorage = require "necro.config.SettingsStorage"

local entityPositions = {}

local positionMetatable = {
	__index = function(_, k)
		error(("Attempt to index non-exist field '%s' at position component"):format(k), 2)
	end,
	__newindex = function(_, k)
		error(("Attempt to inject field '%s' to position component"):format(k), 2)
	end,
}

--- @return { x: number, y: number, z: number }
function F3DEntity.getPosition(entity)
	if entity.F3D_position then
		local id = entity.id
		entityPositions[id] = entityPositions[id] or setmetatable({ x = 0, y = 0, z = 0 }, positionMetatable)
		return entityPositions[id]
	end
	error(("Entity %s is missing tag component `F3D_position`"):format(entity.id), 2)
end

local function copyPositionComponents()
	local getPosition3D = F3DEntity.getPosition

	for entity in ECS.entitiesWithComponents { "F3D_position" } do
		local position3D = getPosition3D(entity)
		entity.F3D_position.x, entity.F3D_position.y, entity.F3D_position.z = position3D.x, position3D.y, position3D.z
	end
end

event.renderUI.add("copyPositionComponents", {
	order = "renderGame",
	sequence = 1,
}, function()
	if SettingsStorage.get "mod.F3D.injectPosition" then
		pcall(copyPositionComponents)
	end
end)

event.objectDespawn.add("despawnEntityPosition", {
	filter = "F3D_position",
	order = "despawnExtras",
}, function(ev)
	entityPositions[ev.entity.id] = nil
end)

event.periodicCheck.add("despawnEntityPositions", "init", function()
	for entityID in pairs(entityPositions) do
		if not ECS.entityExists(entityID) then
			entityPositions[entityID] = nil
		end
	end
end)

event.gameStateLevel.add("resetEntityPositions", "resetLevelVariables", function()
	entityPositions = {}
end)


-- event.lightSourceUpdate.add("updateHoldableLightRadius", {
-- 	filter = { "F3D_controllableDisableLightSource", "controllable", "lightSourceRadial" },
-- 	order = "activation",
-- 	sequence = 1,
-- }, function(ev)
-- 	if ev.entity.lightSourceRadial.active and ev.entity.controllable.playerID ~= 0 then
-- 		ev.entity.lightSourceRadial.active = false
-- 	end
-- end)

entityPositions = script.persist(function()
	return entityPositions
end)

return F3DEntity
