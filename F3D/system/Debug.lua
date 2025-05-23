local F3DCharacter = require "F3D.system.Entity"
local F3DDebug = {}
local F3DDraw = require "F3D.render.Draw"
local F3DRender = require "F3D.render.Render"
local F3DMainCamera = require "F3D.camera.Main"
local F3DVector = require "F3D.necro3d.Vector"

local Color = require "system.utils.Color"
local DebugCommands = require "necro.debug.DebugCommands"
local DebugOverlay = require "necro.debug.DebugOverlay"
local ECS = require "system.game.Entities"
local GFX = require "system.gfx.GFX"
local Render = require "necro.render.Render"
local UI = require "necro.render.UI"
local Utilities = require "system.utils.Utilities"

local clamp = Utilities.clamp
local imageY = F3DDraw.imageY
local magnitude = F3DVector.magnitude
local opacity = Color.opacity
local textY = F3DDraw.textY
local getTileAt = F3DRender.getTileAt
local getTileCenter = F3DRender.getTileCenter

DebugCommands.register("cameraReset", function()
	F3DMainCamera.getCurrent():reset()
	F3DMainCamera.setPosition(0, 0, 0)
	F3DMainCamera.setRotation(0, 0, 0)
	F3DMainCamera.snap()
end)

DebugCommands.register("cameraSet", function(x, y, z, pitch, yaw, roll)
	F3DMainCamera.setPosition(x, y, z)
	pitch = pitch and math.rad(tonumber(pitch) or 0)
	yaw = yaw and math.rad(tonumber(yaw) or 0)
	roll = roll and math.rad(tonumber(roll) or 0)
	F3DMainCamera.setRotation(pitch, yaw, roll)
	F3DMainCamera.snap()
end)

DebugCommands.register("cameraTP", function(entityID)
	local entity = ECS.getEntityByID(entityID)
	if entity then
		local x, y, z = F3DMainCamera.getPosition()
		if entity.F3D_position then
			local position3D = F3DCharacter.getPosition(entity)
			x, y, z = position3D.x, position3D.y, position3D.z
		elseif entity.position then
			x, z = F3DRender.getTileCenter(entity.position.x, entity.position.y)
		end
		F3DMainCamera.setPosition(x, y, z)
		F3DMainCamera.snap()
	end
end)

ShowGrids = false
local font

function F3DDebug.showGrids(b)
	if b == nil then
		return ShowGrids
	else
		ShowGrids = not not b
	end
end

DebugCommands.register("toggleGrids", function()
	ShowGrids = not ShowGrids
end)

local debugDrawTextArgs = {
	font = UI.Font.SYSTEM,
	alignX = .5,
	alignY = .5,
	size = 3,
}

event.renderUI.add("debug", { order = "renderGame", sequence = 1, }, function()
	if not ShowGrids then
		return
	end

	local col = Color.opacity(128)
	local ord = 1e7
	local cx, _, cz = F3DMainCamera.getCurrent():getPosition()
	local tx, ty = F3DRender.getTileAt(cx, cz)
	for tdy = -5, 5 do
		for tdx = -5, 5 do
			local x, z = getTileCenter(tx + tdx, ty + tdy)
			imageY(x - .5, 0, z - .5, 1, 1,
				"mods/F3D/gfx/test/grid.png", 0, 0, 96, 96,
				col, ord)

			debugDrawTextArgs.text = ("%s,%s"):format(x, z)
			textY(x, 0, z, debugDrawTextArgs, font, 1)
		end
	end

	debugDrawTextArgs.text = "你好世界\n，Hello World!"
	F3DDraw.textY(0, 0, 0, debugDrawTextArgs, font, 2)
end)

local bufferID = Render.Buffer.extend("F3D_test", { transform = Render.Transform.NONE })
local buffer = Render.getBuffer(bufferID)
event.render.add(nil, "floors", function()
	if true then
		return
	end

	for index, value in ipairs { "hello" } do
		UI.drawText {
			buffer = bufferID,
			font = UI.Font.MEDIUM,
			text = value,
			spacingY = 1,
			x = 0,
			y = 0,
			z = 0,
		}
	end
	-- buffer.draw {
	-- 	rect = { 0, 0, 100, 100 },
	-- 	color = -1,
	-- }

	local t = {
		anim = {},
		color = {},
		x = {},
		y = {},
		z = {},
		tx = {},
		ty = {},
		zOrder = {},
	}
	buffer.read(0, 100, t)
	-- print(t)
end)

return F3DDebug
