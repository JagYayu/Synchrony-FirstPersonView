local F3DComponents = {}
local F3DRender = require "F3D.render.Render"
local F3DSpriteRenderer = require "F3D.render.SpriteRenderer"

local Action = require "necro.game.system.Action"
local Components = require "necro.game.data.Components"
local Render = require "necro.render.Render"
local Settings = require "necro.config.Settings"

local const = Components.constant
local dependency = Components.dependency
local field = Components.field

F3DComponents.Tag = Settings.Tag.extend "F3D_ReloadScripts"

_G.SettingInjectPosition = Settings.shared.bool {
	id = "injectPosition",
	name = "Inject position component",
	default = false,
	visibility = Settings.Visibility.HIDDEN,
	tag = Settings.Tag.ENTITY_SCHEMA,
}

event.taggedSettingChanged.add("reloadScripts", F3DComponents.Tag, require "necro.config.i18n.Translation".reload)

Components.register {
	F3D_attachmentCopySpritePosition = {
		const.float("offsetX", 0),
		const.float("offsetY", 0),
		const.float("offsetZ", 0),
	},
	--- Entity with this component carries first person camera.
	F3D_camera = {
		field.bool("active", true),
		field.float("height", .5),
		dependency("F3D_position"),
	},
	F3D_cameraDwarfism = {
		const.float("heightMultiplier", .6),
		const.float("fovMultiplier", .5),
		dependency("dwarfism"),
	},
	F3D_cameraFacing = {
		field.enum("direction", Action.Direction, Action.Direction.RIGHT),
		const.enum("defaultDirection", Action.Direction, Action.Direction.RIGHT),
		const.int("rotationMultiplier", 2),
		const.enum("onBossLevel", Action.Direction, Action.Direction.UP),
		dependency("F3D_camera"),
	},
	F3D_cameraFacingAIControl = {
		const.enum("rotation", Action.Rotation, Action.Rotation.IDENTITY),
		dependency("F3D_cameraFacing"),
		dependency("controllable"),
		dependency("movable"),
	},
	F3D_cameraFirstPersonVisibilityHiddenIfTooClose = {
		const.float("squareDistance", .1),
		dependency("F3D_position"),
		dependency("visibility"),
	},
	F3D_cameraGigantism = {
		const.float("heightMultiplier", 1.5),
		dependency("gigantism"),
		dependency("F3D_camera"),
	},
	F3D_cameraHoverEffect = {
		const.float("scale", 1 / Render.TILE_SIZE),
		dependency("hoverEffect"),
		dependency("F3D_camera"),
	},
	F3D_cameraUseRotatedSprite = {
		const.float("scale", 1),
		-- const.float("pitch", math.rad(25)),
		-- const.float("speed", 5),
		-- const.string("animationName", "F3D_cameraSlide"),
		dependency("rotatedSprite"),
		dependency("F3D_camera"),
	},
	F3D_cameraUseFacingDirection = {
		const.enum("rotation", Action.Rotation, Action.Rotation.IDENTITY),
		dependency("facingDirection"),
		dependency("F3D_camera"),
	},
	F3D_controllableDisableLightSource = {},
	F3D_itemStackQuantityLabelWorld = {
		const.float("offsetY"),
		dependency("F3D_position"),
		dependency("itemStack"),
		dependency("itemStackQuantityLabelWorld")
	},
	F3D_objectVibrate = {
		const.float("x", math.sqrt(1 / 2) / Render.TILE_SIZE),
		const.float("z", math.sqrt(1 / 2) / Render.TILE_SIZE),
	},
	--- Represent position in 3D world space, most extended 3d component have dependency on it.
	--- Use `F3DCharacter.getPosition(entity)` to get position.
	--- @class Component.F3D_position
	--- @field x number
	--- @field y number
	--- @field z number
	--- @class Entity
	--- @field F3D_position Component.F3D_position
	F3D_position = SettingInjectPosition and {
		field.float("x"),
		field.float("y"),
		field.float("z"),
	} or {},
	F3D_positionOffsets = {
		const.float("x"),
		const.float("y"),
		const.float("z"),
	},
	F3D_positionOffsetsIfInsideWall = {
		const.float("x"),
		const.float("y", 1),
		const.float("z"),
	},
	F3D_priceTagLabel = {
		const.float("offsetX"),
		const.float("offsetY"),
		const.float("offsetZ"),
	},
	F3D_quads = {
		const.float("offsetX"),
		const.float("offsetY"),
		const.float("offsetZ"),
		const.string("texture", ""),
		const.int("textureShiftX", 0),
		const.int("textureShiftY", 0),
		const.int("textureWidth", 24),
		const.int("textureHeight", 24),
		const.int("color", -1),
		const.float("zOrder", 0),
		const.bool("customOrder", false),
		--- Each frame stores a list ofs drawing parameters of quad, all parameters will be converted during `event.entitySchemaLoadEntity`. Available fields of parameter:
		--- | number x1
		--- | number x2
		--- | number x3
		--- | number x4
		--- | number y1
		--- | number y2
		--- | number y3
		--- | number y4
		--- | number z1
		--- | number z2
		--- | number z3
		--- | number z4
		--- | string texture
		--- | number textureShiftX
		--- | number textureShiftY
		--- | number textureWidth
		--- | number textureHeight
		--- | number color
		--- | number order
		--- | boolean customOrder
		const.table("frames", {}),
		field.int("frame", 1),
	},
	F3D_quadsApplyWallColor = {
		dependency("F3D_quads"),
		dependency("position"),
	},
	F3D_quadsFrameCopyFacingDirection = {
		dependency "F3D_quads",
		dependency "facingDirection",
	},
	F3D_quadsFrameCopySpriteSheetX = {
		dependency "F3D_quads",
		dependency "spriteSheet",
	},
	F3D_quadsFrameIfSilhouetteActive = {
		const.int("frame"),
		dependency "F3D_quads",
		dependency "silhouette",
	},
	F3D_quadsFrameSpriteSheetXShifts = {
		const.table("mapping", {}),
		dependency "F3D_quads",
		dependency "spriteSheet",
	},
	F3D_quadsFrameUseTileset = {
		const.table("mapping"),
		dependency("F3D_quads"),
	},
	F3D_relativeFacing = {
		field.enum("direction", Action.Direction),
		dependency("F3D_position"),
		dependency("facingDirection"),
	},
	F3D_salePriceTagOffset = {
		const.float("offsetX"),
		const.float("offsetZ"),
	},
	F3D_secretShopLabel = {
		const.float("offsetX"),
		const.float("offsetZ"),
		dependency("secretShopLabel"),
	},
	F3D_shadow = {
		field.float("y"),
		const.string("texture", "mods/F3D/gfx/object/shadow_standard.png"),
		const.float("maxHeight", 20),
		const.float("size", 1),
		dependency("F3D_position"),
		dependency("position"),
	},
	F3D_shadowPosition = {
		field.float("x"),
		field.float("y"),
		field.float("z"),
	},
	F3D_sprite = {
		const.enum("style", F3DSpriteRenderer.Style, F3DSpriteRenderer.Style.Billboard),
		--- Override drawing texture.
		field.string("texture", ""),
		field.float("offsetX", 0),
		field.float("offsetY", 0),
		field.float("offsetZ", 0),
		const.float("zOrder", F3DRender.ZOrder.Character),
		const.float("scaleX", .83),
		const.float("scaleY", .83),
		dependency("F3D_position"),
	},
	F3D_spriteHoverEffect = {
		const.float("scale", 1 / Render.TILE_SIZE),
	},
	F3D_spriteVibrate = {
		const.float("x", 1 / Render.TILE_SIZE),
		const.float("z", 1 / Render.TILE_SIZE),
		dependency("F3D_sprite"),
	},
	--- Unused
	F3D_transform = {},
	F3D_worldLabel = {
		const.float("offsetX"),
		const.float("offsetZ"),
		dependency("F3D_position"),
	},
	F3D_visibility = {
		field.bool("visible", true),
		dependency("visibility"),
	},
	F3D_visibilityFrustumCulling = {
		const.table("vertices", {
			-.5, -.5, -.5,
			-.5, -.5, .5,
			-.5, .5, -.5,
			-.5, .5, .5,
			.5, -.5, -.5,
			.5, -.5, .5,
			.5, .5, -.5,
			.5, .5, .5,
		}),
	},
}
