local F3DRenderOverrides = require "F3D.render.Overrides"

-- TODO !!
event.render.override("DynChar_renderDynamicAttachments", function(func, ev)
	if F3DRenderOverrides.hide2D() then
		-- TODO
	else
		func(ev)
	end
end)

-- event.renderUI.add("hookPlayerVisual", {
-- 	order = "initializeBuffers",
-- 	sequence = 5,
-- }, function()
-- 	local playerEntity = Player.getPlayerEntity()
-- 	if playerEntity then
-- 		local playerEntityID = playerEntity.id
-- 		local playerHeadID = playerEntity.characterWithAttachment and playerEntity.characterWithAttachment.attachmentID
--
-- 		F3DRender.hook(Render.Buffer.OBJECT, function(args)
-- 		end)
-- 	end
-- end)
