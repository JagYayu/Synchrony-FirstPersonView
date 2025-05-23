local F3DTileSchema = require "F3D.data.TileSchema"

local function f(n, tex)
	event.F3D_tileSchemaBuildNamed.add(n, n, function(tile)
		F3DTileSchema.wall(tile, { {
			F3D_texture = tex,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex),
		} })
	end)
end

f("DarkShopWall", "mods/F3D/gfx/level/wall_shop_dark.png")
f("DarkShopWallCracked", "mods/F3D/gfx/level/wall_shop_dark_crack.png")
f("ShopWall", "mods/F3D/gfx/level/wall_shop.png")
f("ShopWallCracked", "mods/F3D/gfx/level/wall_shop_crack.png")
f("UnbreakableWall", "mods/F3D/gfx/level/wall_shop.png")
