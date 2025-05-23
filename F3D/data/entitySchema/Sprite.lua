local F3DRender = require "F3D.render.Render"
local F3DSpriteRenderer = require "F3D.render.SpriteRenderer"

local Render = require "necro.render.Render"

local Floor = F3DSpriteRenderer.Style.Floor

event.entitySchemaLoadEntity.add("sprite", "overrides", function(ev)
	if ev.entity.F3D_sprite == nil and ev.entity.sprite then
		local sprite3D = {}

		do
			local sx = .83
			local sy = .83
			if ev.entity.itemCommon then
				sx = sx * .6
				sy = sy * .6
			end
			sprite3D.scaleX = sx
			sprite3D.scaleY = sy
		end

		ev.entity.F3D_sprite = sprite3D
	end

	if type(ev.entity.F3D_sprite) == "table" then
		if ev.entity.attachment and ev.entity.attachmentCopySpritePosition then
			ev.entity.F3D_attachmentCopySpritePosition = { offsetY = tonumber(ev.entity.attachmentCopySpritePosition.offsetY) }
		end

		if ev.entity.trap then
			ev.entity.F3D_sprite.offsetY = (tonumber(ev.entity.F3D_sprite.offsetY) or 0) - .25
		end

		if ev.entity.trapTravel then
			ev.entity.F3D_sprite.style = F3DSpriteRenderer.Style.Floor
			ev.entity.F3D_sprite.offsetY = 0
		end
	end

	if ev.entity.trapDescend and type(ev.entity.F3D_sprite) == "table" then
		ev.entity.F3D_sprite.style = F3DSpriteRenderer.Style.Floor
		ev.entity.F3D_sprite.offsetY = 0
	end
end)

event.entitySchemaLoadEntity.add("spriteVibrate", "overrides", function(ev)
	if ev.entity.spriteVibrate or ev.entity.spriteVibrateOnActionDelay or ev.entity.spriteVibrateOnTell then
		local v = (ev.entity.spriteVibrate and tonumber(ev.entity.spriteVibrate.x) or 1) / Render.TILE_SIZE
		ev.entity.F3D_spriteVibrate = { x = v, z = v }
	end
end)

event.entitySchemaLoadEntity.add("spriteHoverEffect", "overrides", function(ev)
	if ev.entity.hoverEffect then
		ev.entity.F3D_spriteHoverEffect = { scale = (not ev.entity.item) and (1.41 / Render.TILE_SIZE) or nil }
	end
end)

event.entitySchemaLoadEntity.add("relativeFacing", "overrides", function(ev)
	if ev.entity.sprite and ev.entity.facingDirection and ev.entity.directionalAnimation then
		ev.entity.F3D_relativeFacing = {}
	end
end)

local function removeSprite(n)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		ev.entity.F3D_sprite = false
	end)
end

removeSprite "BounceTrapDown"
removeSprite "BounceTrapDownLeft"
removeSprite "BounceTrapDownRight"
removeSprite "BounceTrapLeft"
removeSprite "BounceTrapRight"
removeSprite "BounceTrapRotating"
removeSprite "BounceTrapRotatingCW"
removeSprite "BounceTrapUp"
removeSprite "BounceTrapUpLeft"
removeSprite "BounceTrapUpRight"
removeSprite "Fakewall"
removeSprite "Fakewall2"

-- F3D_sprite.style
local function spriteStyle(n, v)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		if ev.entity.F3D_sprite then
			ev.entity.F3D_sprite.style = v
		end
	end)
end
for i = 0, 10 do
	spriteStyle("ResourceCoin" .. i, Floor)
end
spriteStyle("TriggerJanitorNext", Floor)
spriteStyle("TriggerJanitorReset", Floor)

-- F3D_sprite.offsetY
event.entitySchemaLoadEntity.add(nil, {
	order = "overrides",
	sequence = 100,
}, function(ev)
	if ev.entity.F3D_sprite then
		if ev.entity.itemCurrency then
			ev.entity.F3D_sprite.offsetY = (ev.entity.F3D_sprite.offsetY or 0) - 4 / Render.TILE_SIZE
		elseif ev.entity.shrine then
			ev.entity.F3D_sprite.offsetY = (ev.entity.F3D_sprite.offsetY or 0) - 3 / Render.TILE_SIZE
		end
	end
end)
local function spriteOffsetY(n, v)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		if ev.entity.F3D_sprite then
			ev.entity.F3D_sprite.offsetY = (tonumber(ev.entity.F3D_sprite.offsetY) or 0) + v / Render.TILE_SIZE
		end
	end)
end
-- Zone 1 enemies
spriteOffsetY("Bat", 2)
spriteOffsetY("Bat2", 2)
spriteOffsetY("Bat3", 2)
spriteOffsetY("Ghost", 1)
spriteOffsetY("Wraith", 4)
-- Zone 2 enemies
spriteOffsetY("Armadillo", -2)
spriteOffsetY("Armadillo2", -2)
spriteOffsetY("Golem", -1)
spriteOffsetY("Golem2", -1)
spriteOffsetY("MushroomExploding", -4)
spriteOffsetY("MushroomExplodingActivated", -4)
spriteOffsetY("MushroomLight", -4)
spriteOffsetY("Skeletonmage", -1)
spriteOffsetY("Skeletonmage2", -1)
spriteOffsetY("Skeletonmage3", -1)
spriteOffsetY("Sync_CoopGolem", -1)
spriteOffsetY("Wight", 4)
-- Zone 3 enemies
spriteOffsetY("Cauldron", -2)
spriteOffsetY("Cauldron2", -2)
spriteOffsetY("Ghast", 4)
spriteOffsetY("Sync_CoopSpirit", 4)
spriteOffsetY("Trapcauldron", -2)
spriteOffsetY("Trapcauldron2", -2)
spriteOffsetY("Yeti", -1)
-- Zone 4 enemies
spriteOffsetY("Armadillo3", -2)
spriteOffsetY("Bat4", 2)
spriteOffsetY("Blademaster", -1)
spriteOffsetY("Blademaster2", -1)
spriteOffsetY("Ghoul", 4)
spriteOffsetY("GhoulHallucination", 4)
spriteOffsetY("Golem3", -1)
spriteOffsetY("Golem3Gooless", -1)
spriteOffsetY("Harpy", 1)
spriteOffsetY("Sarcophagus", -2)
spriteOffsetY("Sarcophagus2", -2)
spriteOffsetY("Sarcophagus3", -2)
spriteOffsetY("SleepingGoblin", -2)
spriteOffsetY("Spider", 20)
spriteOffsetY("Sync_CoopBlademaster", -1)
spriteOffsetY("Warlock", -1)
spriteOffsetY("Warlock2", -1)
-- Zone 5 enemies
spriteOffsetY("Devil", -1)
spriteOffsetY("Devil2", -1)
spriteOffsetY("ElectricMage", -1)
spriteOffsetY("ElectricMage2", -1)
spriteOffsetY("ElectricMage3", -1)
spriteOffsetY("Evileye", 2)
spriteOffsetY("Evileye2", 2)
spriteOffsetY("Gorgon", -1)
spriteOffsetY("Gorgon2", -1)
spriteOffsetY("Orc", -2)
spriteOffsetY("Orc2", -2)
spriteOffsetY("Orc3", -2)
spriteOffsetY("Skull", -1)
spriteOffsetY("Skull2", -1)
spriteOffsetY("Skull3", -1)
spriteOffsetY("Sync_CoopOrc", -2)
spriteOffsetY("Wraith2", -2)
-- Minibosses
spriteOffsetY("BatMiniboss", 4)
spriteOffsetY("BatMiniboss2", 4)
spriteOffsetY("Dragon", -1)
spriteOffsetY("Dragon2", -1)
spriteOffsetY("Dragon3", -1)
spriteOffsetY("Dragon4", -1)
spriteOffsetY("Metrognome", -2)
spriteOffsetY("Metrognome2", -2)
spriteOffsetY("Minotaur", -1)
spriteOffsetY("Minotaur2", -1)
spriteOffsetY("Mommy", -1)
spriteOffsetY("Ogre", -1)
-- Bosses
spriteOffsetY("Bishop", -1)
spriteOffsetY("Bishop2", -1)
spriteOffsetY("Conductor", -6)
spriteOffsetY("Coralriff", -6)
spriteOffsetY("CoralriffAngry", -6)
spriteOffsetY("Deathmetal", -1)
spriteOffsetY("DeathmetalPhase2", -1)
spriteOffsetY("DeathmetalPhase3", -1)
spriteOffsetY("DeathmetalPhase4", -1)
spriteOffsetY("Fortissimole", -3)
spriteOffsetY("Frankensteinway", -4)
spriteOffsetY("King", 3)
spriteOffsetY("King2", 3)
spriteOffsetY("KingCongaAngry", -17)
spriteOffsetY("LuteDragon", -9)
spriteOffsetY("LuteHead", -7)
spriteOffsetY("Necrodancer", -4)
spriteOffsetY("NecrodancerPhase2", -3)
spriteOffsetY("Queen", 2)
spriteOffsetY("Queen2", 2)
for _, i in ipairs { "", "2", "3", "4", "5", "6", "7", "8" } do
	spriteOffsetY("Tentacle" .. i, -6)
	spriteOffsetY("Tentacle" .. i .. "Angry", -6)
	spriteOffsetY("TentacleDecor" .. i, 16)
end
-- NPCs
spriteOffsetY("Beastmaster", -1)
spriteOffsetY("Hephaestus", -21)
spriteOffsetY("Transmogrifier", -1)
spriteOffsetY("Weaponmaster", -6)
-- Others
spriteOffsetY("Bell", -3)
spriteOffsetY("Bell2", -1)
spriteOffsetY("FrankensteinwayProp", -7)
spriteOffsetY("Gargoyle", 9)
spriteOffsetY("MummyDancer", -1)
spriteOffsetY("SkeletonDancer", -1)
spriteOffsetY("SkeletonDancer2", -1)
spriteOffsetY("SkeletonDancer3", -1)
spriteOffsetY("TrapFireDecoration", -1)
spriteOffsetY("WallLightBulb", -8)
spriteOffsetY("WallMushroomLight", -5)
spriteOffsetY("WallTorch", -3)

-- F3D_sprite.zOrder
for _, name in ipairs { "FirepigLeft", "FirepigRight", "FirepigConductor", "FirepigGoldenLute" } do
	event.entitySchemaLoadNamedEntity.add(nil, name, function(ev)
		if ev.entity.F3D_sprite then
			ev.entity.F3D_sprite.zOrder = F3DRender.ZOrder.Character + math.sqrt(.5)
		end
	end)
end

-- F3D_spriteVibrate
local function spriteVibrate(n)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		ev.entity.F3D_spriteVibrate = {}
	end)
end
spriteVibrate "FortissimolePhase2"
