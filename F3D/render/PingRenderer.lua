local ECS = require "system.game.Entities"

local function isEntityVisible(entity)
	if not entity or not entity.sprite then
		return false
	elseif (not entity.gameObject or not entity.gameObject.tangible) and not entity.pingableIgnoreVisibility then
		return false
	else
		return true
	end
end

event.pingRender.add("renderPing", "render", function(ev)
	local target = ev.ping
	if not target.visible then
		return
	end

	local entity = ECS.getEntityByID(target.entityID)

	if target.entityID and not isEntityVisible(entity) then
		return
	end
end)
