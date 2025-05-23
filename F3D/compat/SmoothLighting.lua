local GameMod = require "necro.game.data.resource.GameMod"

if GameMod.isModLoaded "SmoothLighting_io_4105528" then
	Warn = true
	event.renderUI.override("SmoothLighting_applySmoothLighting", function()
		if Warn then
			Warn = false
			log.warn "First Person View is already built-in Smooth Lighting."
		end
	end)
end
