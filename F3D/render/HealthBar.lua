local F3DSpriteRenderer = require "F3D.render.Sprite"
local F3DViewport = require "F3D.render.Viewport"

local ECS = require "system.game.Entities"
local GFX = require "system.gfx.GFX"
local Health = require "necro.game.character.Health"

local ceil = math.ceil
local floor = math.floor
local getSpriteVisual = F3DSpriteRenderer.getSpriteVisual
local min = math.min

local healthBarGlobalScale = 1 / 32

--- @param camera F3D.Camera
--- @param draw function
--- @param entity Entity
--- @param args F3D.DrawSpriteArgs
local function drawHealthBar(camera, draw, entity, args)
	local columns = entity.healthBar.columns
	local hearts = Health.getHearts(entity)
	local heartCount = #hearts

	if entity.healthBar.alignRight and columns < heartCount then
		local shift = heartCount % columns

		if shift ~= 0 then
			heartCount = heartCount - shift + columns

			for i = heartCount, heartCount - columns + 1, -1 do
				hearts[i] = (shift >= heartCount - i + 1) and hearts[i - columns + shift]
			end
		end
	end

	local spacingX = entity.healthBar.spacingX
	local spacingY = entity.healthBar.spacingY

	local x = args.rect[1] + args.rect[3] / 2
	local y = args.rect[2] + args.rect[4] / 2

	local heartData = Health.Heart.data
	do
		local primaryHeart = heartData[hearts[1]].imageWorld

		if primaryHeart then
			local width, height = GFX.getImageSize(primaryHeart)

			spacingX = spacingX + width
			spacingY = spacingY + height
			x = x - ceil(width / 2)
		end
	end

	local crop = entity.croppedSprite and entity.croppedSprite.bottom or 0

	x = x - spacingX * (min(heartCount, columns) / 2 - .5)
	y = y - spacingY * (ceil(heartCount / columns) - 1) - 8 + crop

	for i = 1, heartCount do
		local heart = heartData[hearts[i]]

		if heart and heart.imageWorld then
			-- args.anim = entity.shadowPosition.animID
			args.texture = heart.imageWorld
			args.rect[1] = x + spacingX * ((i - 1) % columns)
			args.rect[2] = y + spacingY * floor((i - 1) / columns)
			args.rect[3] = nil
			args.rect[4] = nil

			-- args.texRect[1] = 0
			-- args.texture[2] = 0
			-- args.texRect[3], args.texRect[4] = GFX.getImageSize(heart.imageWorld)
			args.texRect[1] = 0
			args.texRect[2] = 0
			args.texRect[3] = nil
			args.texRect[4] = nil
			args.z = y

			draw(args)
		end
	end
end

event.F3D_drawSprite3D.add("drawHealthBar", {
	filter = "healthBar",
	order = "healthBar",
}, function(ev) --- @param ev Event.F3D_drawSprite3D
	if ev.drawArgs and ev.entity.healthBar.visible then
		drawHealthBar(ev.camera, ev.buffer.draw, ev.entity, ev.drawArgs)
	end
end)
