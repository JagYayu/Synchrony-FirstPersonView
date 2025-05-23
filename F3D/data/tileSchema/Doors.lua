local F3DTileSchema = require "F3D.data.TileSchema"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

local function def(isVertical, texture, thin)
	thin = thin or (1 / 4)
	local d = 24 * thin
	return { {
		F3D_length = isVertical and thin or 1,
		F3D_width = isVertical and 1 or thin,
		F3D_texture = texture or "mods/F3D/gfx/level/door.png",
		F3D_sprites = isVertical and { {
			top = {
				x = 12 - d / 2,
				y = 24,
				width = d,
				height = 24,
			},
			front = {
				x = 24,
				y = 24,
				width = 24,
				height = 24,
			},
			left = {
				x = 60 - d / 2,
				y = 24,
				width = d,
				height = 24,
			},
		} } or { {
			top = {
				x = 0,
				y = 12 - d / 2,
				width = 24,
				height = d,
			},
			front = {
				x = 36 - d / 2,
				y = 0,
				width = d,
				height = 24,
			},
			left = {
				x = 48,
				y = 0,
				width = 24,
				height = 24,
			},
		} },
		F3D_wallFaceCuller = false,
		F3D_wallFaceCulling = false,
	} }
end

f("DoorHorizontal", function(tile)
	F3DTileSchema.wall(tile, def())
end)
f("DoorVertical", function(tile)
	F3DTileSchema.wall(tile, def(true))
end)

return {
	def = def,
}
