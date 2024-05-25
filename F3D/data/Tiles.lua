local F3DDataTiles = {}

local EnumSelector = require "system.events.EnumSelector"
local Utilities = require "system.utils.Utilities"

local function generateFloorEntries(zone)
	local entries = {}
	for i = 1, 6 do
		entries[i] = ("mods/F3D/gfx/tiles/floor_%s_%s.png"):format(zone, i)
	end
	return entries
end

local floorsZ1 = generateFloorEntries "z1"
local floorsZ2 = generateFloorEntries "z2"
local floorsZ3C = generateFloorEntries "z3c"
local floorsZ3H = generateFloorEntries "z3h"
local floorsZ4 = generateFloorEntries "z4"
local floorsZ5 = generateFloorEntries "z5"

event.tileSchemaBuild.add("add3DAttributes", {
	order = "modify",
	sequence = 100,
}, function(ev)
	local t

	t = ev.DoorHorizontal
	if t then
		t.F3D_floor = floorsZ1
		t.F3D_thinWall = true
		t.F3D_wall = "mods/F3D/gfx/tiles/door.png"

		t.tilesets = ev.DoorHorizontal.tilesets or {}
		t.tilesets.Zone4 = t.tilesets.Zone4 or {}
		t.tilesets.Zone4.F3D_floor = floorsZ4
	end

	t = ev.DoorVertical
	if t then
		t.F3D_floor = floorsZ1
		ev.DoorVertical.F3D_thinWall = false
		t.F3D_wall = "mods/F3D/gfx/tiles/door.png"

		t.tilesets = ev.DoorHorizontal.tilesets or {}
		t.tilesets.Zone4 = t.tilesets.Zone4 or {}
		t.tilesets.Zone4.F3D_floor = floorsZ4
	end

	t = ev.Floor
	if t then
		t.F3D_floor = floorsZ1
		t.tilesets = t.tilesets or {}
		t.tilesets.Zone4 = t.tilesets.Zone4 or {}
		t.tilesets.Zone4.F3D_floor = floorsZ4
	end

	ev.LockedStairs.F3D_floor = true

	t = ev.ShopWall
	if t then
		t.F3D_wall = "mods/F3D/gfx/tiles/wall_shop.png"
	end

	ev.Speaker1.F3D_wallHeight = 2

	ev.Stairs.F3D_floor = true

	t = ev.UnbreakableWall
	if t then
		t.F3D_wall = "mods/F3D/gfx/tiles/wall_shop.png"
		t.tilesets = t.tilesets or {}
		t.tilesets.Zone1 = t.tilesets.Zone1 or {}
		t.tilesets.Zone1.F3D_floor = floorsZ1
		t.tilesets.Zone4 = t.tilesets.Zone4 or {}
		t.tilesets.Zone4.F3D_floor = floorsZ4
	end
end)
