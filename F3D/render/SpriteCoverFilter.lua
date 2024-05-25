local F3DSpriteCoverFilter = {}

local CommonFilter = require "necro.render.filter.CommonFilter"

F3DSpriteCoverFilter.getPath = CommonFilter.register("F3D_spriteCover", {
	"texture",
}, {
	"x",
	"y",
	"width",
	"height",
	"shiftX",
	"shiftY",
	"opacity",
}, function(args)
	-- TODO args.texture
end)

return F3DSpriteCoverFilter
