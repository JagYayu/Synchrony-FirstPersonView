local F3DDebug = {}
local F3DUtility = require "F3D.Utility"

local Color = require "system.utils.Color"
local DebugOverlay = require "necro.debug.DebugOverlay"
local Enum = require "system.utils.Enum"
local GFX = require "system.gfx.GFX"
local StringUtilities = require "system.utils.StringUtilities"
local Timer = require "system.utils.Timer"
local UI = require "necro.render.UI"

local getGlobalTime = Timer.getGlobalTime
local getOverlayMode = DebugOverlay.getOverlayMode

local debugTimesList = {}
local debugTimesListIndex = 0
local debugTimesListLength = 10
local renderViewportOrderKeys = {
	"floor",
	"wall",
	"objects",
	"particles",
	"worldLabels",
}

F3DDebug.Overlay = DebugOverlay.Overlay.extend("F3D_PerfViewport", Enum.data {
	func = function()
		local drawTextArgs = {
			alignX = 1,
			font = UI.Font.SYSTEM,
			x = GFX.getWidth(),
			backgroundColor = Color.rgba(32, 32, 32, 180)
		}
		local line = 1
		local function drawLine(text)
			drawTextArgs.text = text
			drawTextArgs.y = (line - 1) * UI.Font.SYSTEM.size
			UI.drawText(drawTextArgs)

			line = line + 1
		end

		local t = 0
		drawLine(("Viewport avg time %s frames"):format(debugTimesListLength))
		for _, debugTimes in ipairs(debugTimesList) do
			t = t + debugTimes["end"] - debugTimes.begin
		end
		drawLine(("Total: %.3fms"):format(Timer.toMilliseconds(t / #debugTimesList)))
		for index, orderKey in ipairs(renderViewportOrderKeys) do
			t = 0
			for _, debugTimes in ipairs(debugTimesList) do
				t = t + debugTimes[orderKey] - debugTimes[renderViewportOrderKeys[index - 1] or "begin"]
			end
			drawLine(("%s: %.3fms"):format(orderKey, Timer.toMilliseconds(t / #debugTimesList)))
		end
	end,
	dev = not F3DUtility.clientIsModAuthor,
})

local DebugOverlayID = F3DDebug.Overlay

function F3DDebug.isOverlay()
	return getOverlayMode() == DebugOverlayID
end

event.F3D_renderViewport.add("debugBegin", {
	order = "begin",
	sequence = -math.huge,
}, function(ev) --- @param ev Event.F3D_renderViewport
	-- if F3DDebug.isOverlay() then
	ev.debugTimes = { begin = getGlobalTime() }
	-- end
end)

for _, orderKey in ipairs(renderViewportOrderKeys) do
	event.F3D_renderViewport.add("debugTrace" .. StringUtilities.capitalizeFirst(orderKey), {
		order = orderKey,
		sequence = math.huge,
	}, function(ev) --- @param ev Event.F3D_renderViewport
		if ev.debugTimes then
			ev.debugTimes[orderKey] = getGlobalTime()
		end
	end)
end

event.F3D_renderViewport.add("debugEnd", {
	order = "end",
	sequence = math.huge,
}, function(ev) --- @param ev Event.F3D_renderViewport
	if ev.debugTimes then
		ev.debugTimes["end"] = getGlobalTime()

		debugTimesListIndex = (debugTimesListIndex % debugTimesListLength) + 1
		debugTimesList[debugTimesListIndex] = ev.debugTimes
	end
end)

return F3DDebug
