local F3DRender = require "F3D.render.Render"
local F3DSpriteRenderer = require "F3D.render.SpriteRenderer"
local F3D_Sync = {}

local GameDLC = require "necro.game.data.resource.GameDLC"

if GameDLC.isSynchronyLoaded() then
	F3D_Sync.isActive = true
else
	F3D_Sync.isActive = false
	return F3D_Sync
end

event.entitySchemaLoadNamedEntity.add(nil, "Sync_FloorCrack", function(ev)
	if ev.entity.F3D_sprite then
		ev.entity.F3D_sprite.style = F3DSpriteRenderer.Style.Floor
	end
end)

event.entitySchemaLoadNamedEntity.add(nil, "Sync_WallSpike", function(ev)
	local frames = {}
	for frame, tex in ipairs {
		"mods/F3D/gfx/Sync/wall_spikes.png",
		"mods/F3D/gfx/Sync/wall_spikes_z2.png",
		"mods/F3D/gfx/Sync/wall_spikes_z3c.png",
		"mods/F3D/gfx/Sync/wall_spikes_z3h.png",
		"mods/F3D/gfx/Sync/wall_spikes_z5.png",
	} do
		local m = .001
		local quads = {
			{
				x1 = 1 + m,
				y1 = 1,
				z1 = 0,
				x2 = 1 + m,
				y2 = 1,
				z2 = 1,
				x3 = 1 + m,
				y3 = 0,
				z3 = 0,
				x4 = 1 + m,
				y4 = 0,
				z4 = 1,
				texture = tex,
			},
			{
				x1 = 1,
				y1 = 1,
				z1 = 1 + m,
				x2 = 0,
				y2 = 1,
				z2 = 1 + m,
				x3 = 1,
				y3 = 0,
				z3 = 1 + m,
				x4 = 0,
				y4 = 0,
				z4 = 1 + m,
				texture = tex,
			},
			{
				x1 = -m,
				y1 = 1,
				z1 = 1,
				x2 = -m,
				y2 = 1,
				z2 = 0,
				x3 = -m,
				y3 = 0,
				z3 = 1,
				x4 = -m,
				y4 = 0,
				z4 = 0,
				texture = tex,
			},
			{
				x1 = 0,
				y1 = 1,
				z1 = -m,
				x2 = 1,
				y2 = 1,
				z2 = -m,
				x3 = 0,
				y3 = 0,
				z3 = -m,
				x4 = 1,
				y4 = 0,
				z4 = -m,
				texture = tex,
			},
		}
		frames[frame] = quads
	end

	ev.entity.F3D_position = {}
	ev.entity.F3D_sprite = false

	ev.entity.F3D_quads = {
		offsetX = -.5,
		offsetZ = -.5,
		frames = frames,
		zOrder = F3DRender.ZOrder.Wall,
	}
	ev.entity.F3D_quadsFrameUseTileset = {
		mapping = {
			[false] = 1,
			Zone2 = 2,
			Zone3Cold = 3,
			Zone3Hot = 4,
			Zone5 = 5,
		}
	}
end)

event.Sync_possessionAttach.add("cameraFacing", {
	filter = "F3D_cameraFacing",
	order = "preservedFields",
}, function(ev)
	if ev.possessor.F3D_cameraFacing then
		ev.entity.F3D_cameraFacing.direction = ev.possessor.F3D_cameraFacing.direction
	end
end)

event.Sync_possessionDetach.add("cameraFacing", {
	filter = "F3D_cameraFacing",
	order = "preservedFields",
}, function(ev)
	if ev.possessor.F3D_cameraFacing then
		ev.possessor.F3D_cameraFacing.direction = ev.entity.F3D_cameraFacing.direction
	end
end)



return F3D_Sync
