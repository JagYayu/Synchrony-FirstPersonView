local F3DTileSchema = require "F3D.data.TileSchema"
local F3DTileSchemaDoors = require "F3D.data.tileSchema.Doors"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

local tex = "mods/F3D/gfx/level/door_metal.png"

f("MetalDoorHorizontal", function(tile)
	F3DTileSchema.wall(tile, F3DTileSchemaDoors.def(false, tex, 1 / 6))
end)
f("MetalDoorVertical", function(tile)
	F3DTileSchema.wall(tile, F3DTileSchemaDoors.def(true, tex, 1 / 6))
end)
