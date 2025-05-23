local F3DTileSchema = require "F3D.data.TileSchema"
local F3DTileSchemaDoors = require "F3D.data.tileSchema.Doors"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

local tex = "mods/F3D/gfx/level/door_metal.png"

f("LockedDoorHorizontal", function(tile)
	F3DTileSchema.wall(tile, F3DTileSchemaDoors.def(false, tex))
end)
f("LockedDoorVertical", function(tile)
	F3DTileSchema.wall(tile, F3DTileSchemaDoors.def(true, tex))
end)
f("NecrodancerDoor", function(tile)
	F3DTileSchema.wall(tile, F3DTileSchemaDoors.def(false, tex))
end)
