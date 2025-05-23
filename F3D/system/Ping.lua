local F3DPing = {}
local F3DRay = require "F3D.system.Ray"
local F3DUtilities = require "F3D.system.Utilities"

local Action = require "necro.game.system.Action"
local Controls = require "necro.config.Controls"
local Cutscene = require "necro.client.Cutscene"
local Ping = require "necro.client.Ping"
local Settings = require "necro.config.Settings"
local TouchInput = require "necro.client.input.TouchInput"

SettingPingOverride = Settings.overridable.bool {
	id = "Ping override",
	name = "Ping override",
	default = false, -- true,
	setter = function(v)
		F3DPing.updateOverriding(v)
	end,
	visibility = Settings.Visibility.HIDDEN,
}

function F3DPing.updateOverriding(b)
	local data = Controls.Misc.data[Controls.Misc.PING_CURSOR]
	if F3DUtilities.ifNil(b, SettingPingOverride, not not b) then
		if type(data.F3D_pingCursorCallbackOverride) ~= "function" and type(data.callback) == "function" then
			data.F3D_pingCursorCallbackOverride = data.callback
			data.callback = function(...)
				if Cutscene.isActive() or TouchInput.isInteracting() then
					return false
				end

				local x, y = F3DRay.newScreen():castToTile()
				if x then
					return Ping.perform(x, y)
				else
					return data.F3D_pingCursorCallbackOverride(...)
				end
			end
		end
	else
		if type(data.F3D_pingCursorCallbackOverride) == "function" then
			data.callback = data.F3D_pingCursorCallbackOverride
			data.F3D_pingCursorCallbackOverride = nil
		end
	end
end

event.contentLoad.add("pingOverride", "dlc", F3DPing.updateOverriding)

return F3DPing
