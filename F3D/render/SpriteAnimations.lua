local F3DAnimations = require "F3D.render.Animations"
local F3DCamera = require "F3D.necro3d.Camera"
local F3DCharacter = require "F3D.system.Entity"
local F3DMainCamera = require "F3D.camera.Main"
local F3DRender = require "F3D.render.Render"
local F3DSpriteAnimations = {}
local F3DUtilities = require "F3D.system.Utilities"

local Action = require "necro.game.system.Action"
local AnimationTimer = require "necro.render.AnimationTimer"
local Animations = require "necro.render.level.Animations"
local ECS = require "system.game.Entities"
local EnumSelector = require "system.events.EnumSelector"
local Player = require "necro.game.character.Player"
local Random = require "system.utils.Random"
local Settings = require "necro.config.Settings"
local SpriteEffects = require "necro.render.level.SpriteEffects"
local Tile = require "necro.game.tile.Tile"
local Utilities = require "system.utils.Utilities"
local VisualExtent = require "necro.render.level.VisualExtent"

local floor = math.floor
local getAnimationTime = AnimationTimer.getTime
local getEntityPrototype = ECS.getEntityPrototype
local hoverHeight = SpriteEffects.hoverHeight
local lerp = Utilities.lerp
local random = math.random
local vector2Normalize = F3DUtilities.vector2Normalize
local noise3 = Random.noise3

event.render.add("updateRelativeFacing", {
	order = "spriteAnimations",
	sequence = -1,
}, function()
	local x, _, z = F3DMainCamera.getCurrent():getPosition()
	local f = math.pi / 4

	for entity in ECS.entitiesWithComponents { "F3D_relativeFacing" } do
		local position3D = F3DCharacter.getPosition(entity)
		local ang = math.rad(-22.5) - (math.atan2(z - position3D.z, x - position3D.x) + Action.getAngle(entity.facingDirection.direction))
		local dir = floor(math.deg((ang - math.rad(45)) % (math.pi * 2)) / 45) + 1
		entity.F3D_relativeFacing.direction = dir
	end
end)

event.render.add("relativeFacingMirrorX", {
	order = "spriteAnimations",
	sequence = 1,
}, function(ev)
	for entity in ECS.entitiesWithComponents { "F3D_relativeFacing", "facingMirrorX", "sprite" } do
		entity.sprite.mirrorX = entity.facingMirrorX.directions[entity.F3D_relativeFacing.direction] or entity.sprite.mirrorX
	end
end)

local function animate(entity, animationName, variant)
	local frame = Animations.getAnimationFrame(entity, animationName, variant)

	if frame then
		entity.spriteSheet.frameX = frame
	end
end
event.animateObjects.override("applyDirectionalAnimations", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_relativeFacing",
		"directionalAnimation",
		"facingDirection",
	} do
		animate(entity, "directionalAnimation", entity.F3D_relativeFacing.direction)
	end

	for entity in ECS.entitiesWithComponents {
		"directionalAnimation",
		"facingDirection",
		"!F3D_relativeFacing",
	} do
		animate(entity, "directionalAnimation", entity.facingDirection.direction)
	end
end)

event.F3D_animateSprite.add("resetOffsets", {
	filter = "F3D_sprite",
	order = "reset",
}, function(entity)
	local c = entity.F3D_sprite
	local pc = getEntityPrototype(entity.name).F3D_sprite
	c.offsetX = pc.offsetX
	c.offsetY = pc.offsetY
	c.offsetZ = pc.offsetZ
end)

event.F3D_animateSprite.add("spriteHoverEffect", {
	filter = { "F3D_spriteHoverEffect", "F3D_sprite", "hoverEffect" },
	order = "hover",
}, function(entity)
	if entity.hoverEffect.active then
		local sprite3D = entity.F3D_sprite
		local y = sprite3D.offsetY - (hoverHeight(entity, entity.hoverEffect.timeStart) - entity.hoverEffect.offset) * entity.F3D_spriteHoverEffect.scale
		sprite3D.offsetY = y
	end
end)

function F3DSpriteAnimations.spriteVibrateOffsets(id, data)
	local t = getAnimationTime() * 1024
	local x = data.x * 1024
	local z = data.z * 1024
	x = noise3(t, x, id, x) / 1024
	z = noise3(z, t, id, z) / 1024
	return x, z
end

event.F3D_animateSprite.add("vibrate", {
	filter = { "F3D_spriteVibrate", "F3D_sprite", "spriteVibrate" },
	order = "vibrate",
}, function(entity)
	if entity.spriteVibrate.active then
		local sprite3D = entity.F3D_sprite
		local offsetX, offsetZ = F3DSpriteAnimations.spriteVibrateOffsets(entity.id, entity.F3D_spriteVibrate)
		sprite3D.offsetX = sprite3D.offsetX + offsetX
		sprite3D.offsetZ = sprite3D.offsetZ + offsetZ
	end
end)

return F3DSpriteAnimations
