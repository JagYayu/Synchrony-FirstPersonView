local F3DQuadsFrames = {}

local Utilities = require "system.utils.Utilities"

F3DQuadsFrames.Frame = {}

--- TODO
function F3DQuadsFrames.Frame.hexahedron(args)

end

F3DQuadsFrames.Frame = Utilities.readOnlyTable(F3DQuadsFrames.Frame)

--- TODO
function F3DQuadsFrames.bounceTrap(args)
end

--- TODO
function F3DQuadsFrames.fakeWall(args)
	args = type(args) == "table" and args or {}
	local l = args.length
	local w = args.width
	local h = args.height

	return {
		{
		},
	}
end

function F3DQuadsFrames.firePig()
end

return F3DQuadsFrames
