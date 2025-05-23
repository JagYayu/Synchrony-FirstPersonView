event.entitySchemaLoadEntity.add("camera", "overrides", function(ev)
	if ev.entity.F3D_camera == nil and ev.entity.controllable then
		ev.entity.F3D_camera = {}

		if ev.entity.character then
			ev.entity.F3D_cameraFacing = {}

			if ev.entity.ai and ev.entity.movable then
				ev.entity.F3D_cameraFacingAIControl = {}
			end
		elseif ev.entity.facingDirection then
			ev.entity.F3D_cameraUseFacingDirection = {}
		end

		if ev.entity.hoverEffect then
			ev.entity.F3D_cameraHoverEffect = {}
		end

		if ev.entity.dwarfism then
			ev.entity.F3D_cameraDwarfism = {
				heightMultiplier = type(ev.entity.spriteDwarfismScale) == "table" and tonumber(ev.entity.spriteDwarfismScale.scale),
			}
		end

		if ev.entity.gigantism then
			ev.entity.F3D_cameraGigantism = {
				heightMultiplier = type(ev.entity.spriteGigantismScale) == "table" and tonumber(ev.entity.spriteGigantismScale.scale),
			}
		end

		if ev.entity.rotatedSprite then
			ev.entity.F3D_cameraUseRotatedSprite = {}
		end
	end
end)

event.entitySchemaLoadEntity.add("cameraFirstPersonVisibilityHiddenIfTooClose", {
	order = "overrides",
	sequence = 10,
}, function(ev)
	if (ev.entity.F3D_position or ev.entity.controllable) and ev.entity.F3D_sprite and ev.entity.visibility then
		ev.entity.F3D_cameraFirstPersonVisibilityHiddenIfTooClose = {}
	end
end)
