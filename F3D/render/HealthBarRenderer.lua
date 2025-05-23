local F3DCameraVisibility = require "F3D.camera.Visibility"
local F3DEntity = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.Draw"
local F3DHealthBarRenderer = {}
local F3DMainCamera = require "F3D.camera.Main"
local F3DSpriteRenderer = require "F3D.render.SpriteRenderer"
local F3DRender = require "F3D.render.Render"
local F3DUtilities = require "F3D.system.Utilities"

local ECS = require("system.game.Entities")
local GFX = require("system.gfx.GFX")
local Health = require("necro.game.character.Health")
local Render = require "necro.render.Render"
local VisualExtent = require("necro.render.level.VisualExtent")

local camera = F3DMainCamera.getCurrent()
local checkEntityCameraVisibility = F3DCameraVisibility.checkEntity
local getPosition3D = F3DEntity.getPosition
local getSprite3DVisual = F3DSpriteRenderer.getSpriteVisual
local invTS = 1 / Render.TILE_SIZE

function F3DHealthBarRenderer.render(entity)
	if not entity.F3D_sprite or not entity.sprite.visible then
		return false
	end

	local hearts = Health.getHearts(entity)
	local columns = entity.healthBar.columns
	local heartCount = #hearts

	if entity.healthBar.alignRight and columns < heartCount then
		local shift = heartCount % columns

		if shift ~= 0 then
			heartCount = heartCount - shift + columns

			for i = heartCount, heartCount - columns + 1, -1 do
				hearts[i] = shift >= heartCount - i + 1 and hearts[i - columns + shift]
			end
		end
	end

	local spacingX = entity.healthBar.spacingX * invTS
	local spacingY = entity.healthBar.spacingY * invTS
	local position3D = getPosition3D(entity)
	local x = position3D.x
	local y = position3D.y + entity.sprite.height * entity.F3D_sprite.scaleY * invTS - .25
	local z = position3D.z

	do
		local primaryHeart = Health.Heart.data[hearts[1]].imageWorld

		if primaryHeart then
			local width, height = GFX.getImageSize(primaryHeart)

			-- spacingX = spacingX + width
			-- spacingY = spacingY + height
			-- x = x - math.ceil(width / 2)
		end
	end

	local cx, cy, cz = camera:getPosition()
	local dx = x - cx
	local dz = z - cz
	dx, dz = F3DUtilities.vector2Normalize(dx, dz)
	dx, dz = dz, -dx

	local heartData = Health.Heart.data

	for i = 1, heartCount do
		local heart = heartData[hearts[i]]

		if heart and heart.imageWorld then
			local texW, texH = GFX.getImageSize(heart.imageWorld)
			local tw = texW * invTS * .75
			local th = texH * invTS * .75

			local d = -heartCount * tw / 2
			local xl = x + dx * (d + (i - 1) * tw + spacingX * ((i - 1) % columns))
			local zl = z + dz * (d + (i - 1) * th)
			local xr = xl + tw * dx
			local zr = zl + th * dz

			F3DDraw.quad(xl, y + th, zl,
				xr, y + th, zr,
				xl, y, zl,
				xr, y, zr,
				heart.imageWorld, 0, 0, texW, texH, -1, F3DRender.ZOrder.HealthBar)
		end
	end
end

local render = F3DHealthBarRenderer.render

event.render.add("renderHealthBars", "healthBars", function()
	for entity in ECS.entitiesWithComponents { "healthBar" } do
		if entity.healthBar.visible and checkEntityCameraVisibility(entity) then
			render(entity)
		end
	end
end)

return F3DHealthBarRenderer
