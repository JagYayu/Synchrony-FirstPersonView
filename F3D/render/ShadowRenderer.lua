local F3DCamera = require "F3D.necro3d.Camera"
local F3DCameraVisibility = require "F3D.camera.Visibility"
local F3DCharacter = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.Draw"
local F3DMainCamera = require "F3D.camera.Main"
local F3DRender = require "F3D.render.Render"
local F3DShadowRenderer = {}
local F3DUtilities = require "F3D.system.Utilities"
local F3DVector = require "F3D.necro3d.Vector"

local AnimationTimer = require "necro.render.AnimationTimer"
local Color = require "system.utils.Color"
local CropFilter = require "necro.render.filter.CropFilter"
local ECS = require "system.game.Entities"
local FloorVisuals = require "necro.render.level.FloorVisuals"
local GFX = require "system.gfx.GFX"
local Random = require "system.utils.Random"
local Render = require "necro.render.Render"
local SettingsStorage = require "necro.config.SettingsStorage"
local Tile = require "necro.game.tile.Tile"
local TileTypes = require "necro.game.tile.TileTypes"
local TileRenderer = require "necro.render.level.TileRenderer"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"
local WallVisuals = require "necro.render.level.WallVisuals"

local ZOrder = F3DRender.ZOrder.Shadow
local abs = math.abs
local clamp = Utilities.clamp
local checkEntityCameraVisibility = F3DCameraVisibility.checkEntity
local colorOpacity = Color.opacity
local floor = math.floor
local getImageSize = GFX.getImageSize
local getPosition3D = F3DCharacter.getPosition
local getTileInfo = Tile.getInfo
local imageY = F3DDraw.imageY
local tileSize = Render.TILE_SIZE
local tonumber = tonumber
local vectorMagnitude = F3DVector.magnitude

local invTS = 1 / tileSize

function F3DShadowRenderer.render(entity, cameraY)
	local position3D = getPosition3D(entity)
	local shadow3D = entity.F3D_shadow
	local y = position3D.y
	if cameraY > y then
		local x = position3D.x
		local z = position3D.z
		local t = shadow3D.texture
		local hs = shadow3D.size
		local tw, th = getImageSize(t)

		local platformY = tonumber(getTileInfo(entity.position.x, entity.position.y).F3D_platformY) or 0

		imageY(x - hs * .5, shadow3D.y, z - hs * .5, hs, hs,
			t, 0, 0, tw, th,
			colorOpacity(clamp(0, (shadow3D.maxHeight - (position3D.y - platformY)) * invTS, 1)),
			ZOrder)
	end
end

event.render.add("shadowsProjectToGround", {
	order = "shadows",
	sequence = 1,
}, function()
	for entity in ECS.entitiesWithComponents {
		"F3D_position",
		"F3D_shadow",
		"shadow",
		"position",
		"visibility",
	} do
		if entity.shadow.visible and entity.visibility.visible and checkEntityCameraVisibility(entity) then
			local platformY = tonumber(getTileInfo(entity.position.x, entity.position.y).F3D_platformY) or 0
			if getPosition3D(entity).y >= platformY then
				entity.F3D_shadow.y = platformY
			end
		end
	end
end)

event.render.add("renderShadows", {
	order = "shadows",
	sequence = 1,
}, function()
	local cy = F3DMainCamera.getCurrent()[F3DCamera.Field.Y]

	for entity in ECS.entitiesWithComponents {
		"F3D_shadow",
		"position",
		"shadow",
		"visibility",
	} do
		if entity.shadow.visible and entity.visibility.visible and checkEntityCameraVisibility(entity) then
			F3DShadowRenderer.render(entity, cy)
		end
	end
end)

return F3DShadowRenderer
