local Action = require "necro.game.system.Action"
local Components = require "necro.game.data.Components"
local Object = require "necro.game.object.Object"

local Direction = Action.Direction
local const = Components.constant

Components.register {
	F3D_camera = {
		Components.field.bool("active", true),
		Components.field.float("height", .5),
	},
	F3D_cameraDwarfism = {
		const.float("height", -.2),
	},
	F3D_cameraGigantism = {
		const.float("height", .2),
	},
	F3D_facing = {
		Components.field.enum("direction", Direction, Direction.UP),
		-- Unused right now.
		const.table("directionRemap", {
			[Direction.UP_RIGHT] = Direction.RIGHT,
			[Direction.UP_LEFT] = Direction.UP,
			[Direction.DOWN_LEFT] = Direction.LEFT,
			[Direction.DOWN_RIGHT] = Direction.DOWN,
		}),
		const.int("rotationMultiplier", 2),
	},
	F3D_label3D = {
		const.float("zOrder", .1),
	},
	F3D_sprite3D = {
		Components.field.float("x"),
		Components.field.float("y"),
		Components.field.float("z"),
		Components.field.float("zOrder", .01),
	},
	F3D_sprite3DDirectional = {},
	F3D_sprite3D8DirectionalVisual = {
		const.table("directions"),
	},
	F3D_sprite3DOffset = {
		const.float("x"),
		const.float("y"),
	},
	F3D_sprite3DScale = {
		const.float("x"),
		const.float("y"),
	},
	--- Don't copy sprite 3D visual from `sprite` component.
	F3D_sprite3DIgnoreSprite = {},
}

Object.resetFieldOnConvert("F3D_sprite3D", "zOrder")
