--- @alias F3DDraw.col integer | { [1]: Color, [2]: Color, [3]: Color, [4]: Color }

--- [0]: top
--- [1]: front
--- [2]: left
--- [3]: back
--- [4]: right
--- @alias F3DRender.wall.col integer | { [0]: F3DDraw.col, [1]: F3DDraw.col, [2]: F3DDraw.col, [3]: F3DDraw.col, [4]: F3DDraw.col }

--- You can also customize your own complex drawing functions by referring following scripts.
--- Be aware that 3D World coordinates are different to vertices coordinates, basically an x-coordinate inversion and y-z reversion.
--- @class F3DDraw
local F3DDraw = {}
local F3DMainCamera = require "F3D.camera.Main"
local F3DMatrix = require "F3D.necro3d.Matrix"
local F3DRender = require "F3D.render.Render"
local F3DUtilities = require "F3D.system.Utilities"
local F3DVector = require "F3D.necro3d.Vector"

local Color = require "system.utils.Color"
local GFX = require "system.gfx.GFX"
local StringUtilities = require "system.utils.StringUtilities"
local Utilities = require "system.utils.Utilities"

local atan2 = math.atan2
local bitAnd = bit.band
local emptyTable = F3DUtilities.emptyTable
local getImageGeometry = GFX.getImageGeometry
local getTextAttributes = F3DRender.getTextAttributes
local hpi = math.pi / 2
local min = math.min
local sqrt = math.sqrt
local staticMatrix = F3DMatrix.static()
local tonumber = tonumber
local type = type
local vectorMagnitude = F3DVector.magnitude
local vector2Magnitude = F3DUtilities.vector2Magnitude
local vectorNormalize = F3DVector.normalize
local vector2Normalize = F3DUtilities.vector2Normalize

local cameraX = 0
local cameraY = 0
local cameraZ = 0
local cameraDX = 0
local cameraDY = 0
local cameraDZ = 0
local ppu = F3DRender.getPPU()
local invPPU = 1 / ppu

event.render.add(nil, {
	order = "camera",
	sequence = 1e3,
}, function()
	cameraX, cameraY, cameraZ = F3DMainCamera.getCurrent():getPosition()
	cameraDX, cameraDY, cameraDZ = F3DMainCamera.getCurrent():getDirection()
	ppu = F3DRender.getPPU()
	invPPU = 1 / ppu
end)

--- @generic T
--- @param tbl table<T, any>
--- @return table<T, integer>
local function newArgsIndices(tbl)
	local tblOri = Utilities.fastCopy(tbl)
	local keys = Utilities.sort(Utilities.getKeyList(tbl))
	local key2Index = {}
	for i, k in ipairs(keys) do
		key2Index[k] = i
	end

	event.renderUI.add(nil, "clear", function()
		for _, k in ipairs(keys) do
			tbl[k] = tblOri[k]
		end
	end)

	return setmetatable({}, {
		__index = function(_, k)
			if key2Index[k] then
				return key2Index[k]
			end

			local msg = ("Attempt to index non-exist key '%s'"):format(k)
			local what = StringUtilities.didYouMean(k, keys)
			if what ~= k then
				msg = msg .. ". " .. k
			end
			error(msg, 2)
		end,
		__len = function()
			return #keys
		end,
		__newindex = function(_, k)
			error(("Attempt modify field '%s' at an immutable table"):format(k), 2)
		end,
	})
end

--- @generic T
--- @param argsIndices table<T, integer>
--- @return table<T, any>
local function newArgs(argsIndices)
	return setmetatable(Utilities.newTable(#argsIndices, 0), {
		__index = function(_, k)
			error(("Attempt to index non-exist field '%s'"):format(k), 2)
		end,
		__newindex = function(_, k)
			error(("Attempt to modify non-exist field '%s'"):format(k), 2)
		end,
	})
end

local function quadOrder(xL, zL, i1, i2, i3, i4)
	local x1, z1 = cameraX + invPPU * xL[i1], cameraZ - invPPU * zL[i1]
	local x2, z2 = cameraX + invPPU * xL[i2], cameraZ - invPPU * zL[i2]
	local x3, z3 = cameraX + invPPU * xL[i3], cameraZ - invPPU * zL[i3]
	local x4, z4 = cameraX + invPPU * xL[i4], cameraZ - invPPU * zL[i4]
	local x = (x1 + x2 + x3 + x4) * .25
	local z = (z1 + z2 + z3 + z4) * .25
	return -sqrt(min(x * x + z * z,
		x1 * x1 + z1 * z1,
		x2 * x2 + z2 * z2,
		x3 * x3 + z3 * z3,
		x4 * x4 + z4 * z4))
end

local va = F3DRender.getVertexAttributes()
local colL = va.color
local xL = va.x
local yL = va.y
local zL = va.z
local txL = va.tx
local tyL = va.ty
local ordL = va.zOrder
local animL = va.anim

local function procImage(col, anim)
	col = col or -1

	local vi = va[0] + 1
	va[0] = va[0] + 1

	local i4 = vi * 4
	local i3 = i4 - 1
	local i2 = i3 - 1
	local i1 = i2 - 1
	if type(col) == "table" then
		colL[i1] = tonumber(col[1]) or -1
		colL[i2] = tonumber(col[2]) or -1
		colL[i3] = tonumber(col[3]) or -1
		colL[i4] = tonumber(col[4]) or -1
	else
		col = tonumber(col) or -1
		colL[i1] = col
		colL[i2] = col
		colL[i3] = col
		colL[i4] = col
	end

	animL[vi] = anim or 0

	return vi, i1, i2, i3, i4
end

--- Draw a quad
--- @param x1 number
--- @param y1 number
--- @param z1 number
--- @param x2 number
--- @param y2 number
--- @param z2 number
--- @param x3 number
--- @param y3 number
--- @param z3 number
--- @param t string?
--- @param tx number
--- @param ty number
--- @param tw number
--- @param th number
--- @param col F3DDraw.col
--- @param ord number?
--- @param anim VertexAnimation.ID?
function F3DDraw.quad(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4,
					  t, tx, ty, tw, th, col, ord, cstOrd, anim)
	x1 = -x1
	x2 = -x2
	x3 = -x3
	x4 = -x4
	local vi, i1, i2, i3, i4 = procImage(col, anim)
	xL[i1] = ppu * x1
	xL[i2] = ppu * x2
	xL[i3] = ppu * x3
	xL[i4] = ppu * x4
	yL[i1] = ppu * y1
	yL[i2] = ppu * y2
	yL[i3] = ppu * y3
	yL[i4] = ppu * y4
	zL[i1] = ppu * z1
	zL[i2] = ppu * z2
	zL[i3] = ppu * z3
	zL[i4] = ppu * z4
	local geo = getImageGeometry(t)
	txL[i1] = geo.x + tx
	txL[i2] = geo.x + tx + tw
	txL[i3] = geo.x + tx
	txL[i4] = geo.x + tx + tw
	tyL[i1] = geo.y + ty
	tyL[i2] = geo.y + ty
	tyL[i3] = geo.y + ty + th
	tyL[i4] = geo.y + ty + th
	ordL[vi] = cstOrd
		and (ord or quadOrder(xL, zL, i1, i2, i3, i4))
		or (ord or 0) + quadOrder(xL, zL, i1, i2, i3, i4)
end

F3DDraw.QuadArgs = newArgsIndices {
	X1 = 0,
	Y1 = 0,
	Z1 = 0,
	X2 = 0,
	Y2 = 0,
	Z2 = 0,
	X3 = 0,
	Y3 = 0,
	Z3 = 0,
	X4 = 0,
	Y4 = 0,
	Z4 = 0,
	Texture = "",
	TextureShiftX = 0,
	TextureShiftY = 0,
	TextureWidth = 24,
	TextureHeight = 24,
	Color = Color.WHITE,
	Order = 0,
	CustomOrder = false,
	AnimationID = 0,
}
local QuadX1 = F3DDraw.QuadArgs.X1
local QuadY1 = F3DDraw.QuadArgs.Y1
local QuadZ1 = F3DDraw.QuadArgs.Z1
local QuadX2 = F3DDraw.QuadArgs.X2
local QuadY2 = F3DDraw.QuadArgs.Y2
local QuadZ2 = F3DDraw.QuadArgs.Z2
local QuadX3 = F3DDraw.QuadArgs.X3
local QuadY3 = F3DDraw.QuadArgs.Y3
local QuadZ3 = F3DDraw.QuadArgs.Z3
local QuadX4 = F3DDraw.QuadArgs.X4
local QuadY4 = F3DDraw.QuadArgs.Y4
local QuadZ4 = F3DDraw.QuadArgs.Z4
local QuadTexture = F3DDraw.QuadArgs.Texture
local QuadTextureShiftX = F3DDraw.QuadArgs.TextureShiftX
local QuadTextureShiftY = F3DDraw.QuadArgs.TextureShiftY
local QuadTextureWidth = F3DDraw.QuadArgs.TextureWidth
local QuadTextureHeight = F3DDraw.QuadArgs.TextureHeight
local QuadColor = F3DDraw.QuadArgs.Color
local QuadOrder = F3DDraw.QuadArgs.Order
local QuadCustomOrder = F3DDraw.QuadArgs.CustomOrder
local QuadAnimationID = F3DDraw.QuadArgs.AnimationID

F3DDraw.quadArgs = newArgs(F3DDraw.QuadArgs)
local quadArgs = F3DDraw.quadArgs

--- Draw a quad in 3D space
function F3DDraw.quad1()
	local vi, i1, i2, i3, i4 = procImage(quadArgs[QuadColor], quadArgs[QuadAnimationID])
	xL[i1] = ppu * -quadArgs[QuadX1]
	xL[i2] = ppu * -quadArgs[QuadX2]
	xL[i3] = ppu * -quadArgs[QuadX3]
	xL[i4] = ppu * -quadArgs[QuadX4]
	yL[i1] = ppu * quadArgs[QuadY1]
	yL[i2] = ppu * quadArgs[QuadY2]
	yL[i3] = ppu * quadArgs[QuadY3]
	yL[i4] = ppu * quadArgs[QuadY4]
	zL[i1] = ppu * quadArgs[QuadZ1]
	zL[i2] = ppu * quadArgs[QuadZ2]
	zL[i3] = ppu * quadArgs[QuadZ3]
	zL[i4] = ppu * quadArgs[QuadZ4]
	local geo = getImageGeometry(quadArgs[QuadTexture])
	txL[i1] = geo.x + quadArgs[QuadTextureShiftX]
	txL[i2] = geo.x + quadArgs[QuadTextureShiftX] + quadArgs[QuadTextureWidth]
	txL[i3] = geo.x + quadArgs[QuadTextureShiftX]
	txL[i4] = geo.x + quadArgs[QuadTextureShiftX] + quadArgs[QuadTextureWidth]
	tyL[i1] = geo.y + quadArgs[QuadTextureShiftY]
	tyL[i2] = geo.y + quadArgs[QuadTextureShiftY]
	tyL[i3] = geo.y + quadArgs[QuadTextureShiftY] + quadArgs[QuadTextureHeight]
	tyL[i4] = geo.y + quadArgs[QuadTextureShiftY] + quadArgs[QuadTextureHeight]
	ordL[vi] = quadArgs[QuadCustomOrder]
		and (quadArgs[QuadOrder] or quadOrder(xL, zL, i1, i2, i3, i4))
		or (quadArgs[QuadOrder] or 0) + quadOrder(xL, zL, i1, i2, i3, i4)
end

local drawQuad = F3DDraw.quad

--- Draw a billboard image
function F3DDraw.image(x, y, z, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
	local dx = x - cameraX
	local dz = z - cameraZ
	dx, dz = vector2Normalize(dx, dz)
	dx, dz = dz, -dx

	local f = w * .5
	local xl = x - dx * f
	local zl = z - dz * f
	local xr = x + dx * f
	local zr = z + dz * f

	drawQuad(xl, y + h, zl,
		xr, y + h, zr,
		xl, y, zl,
		xr, y, zr,
		t, tx, ty, tw, th,
		col, ord, cstOrd)
end

--- Draw an image perpendicular to x-axis
function F3DDraw.imageX(x, y, z, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
	x = -x
	local vi, i1, i2, i3, i4 = procImage(col)
	xL[i1] = ppu * (x)
	xL[i2] = ppu * (x)
	xL[i3] = ppu * (x)
	xL[i4] = ppu * (x)
	yL[i1] = ppu * (y)
	yL[i2] = ppu * (y)
	yL[i3] = ppu * (y + h)
	yL[i4] = ppu * (y + h)
	zL[i1] = ppu * (z)
	zL[i2] = ppu * (z + w)
	zL[i3] = ppu * (z)
	zL[i4] = ppu * (z + w)
	local geo = getImageGeometry(t)
	txL[i3] = geo.x + tx
	txL[i4] = geo.x + tx + tw
	txL[i1] = geo.x + tx
	txL[i2] = geo.x + tx + tw
	tyL[i3] = geo.y + ty
	tyL[i4] = geo.y + ty
	tyL[i1] = geo.y + ty + th
	tyL[i2] = geo.y + ty + th

	local dx, dy = cameraX + x, cameraZ - (z + w * .5)
	ordL[vi] = cstOrd
		and (ord or -vector2Magnitude(dx, dy))
		or ((ord or 0) - vector2Magnitude(dx, dy))
	-- zOrderL[vi] = ord or -vectorMagnitude(cameraX + x, cameraY - (y + h * .5), cameraZ - (z + w * .5))
	-- zOrderL[vi] = ord or quadOrder(xL, yL, zL, i1, i2, i3, i4)
end

local drawImageX = F3DDraw.imageX

--- Draw a grounded image
function F3DDraw.imageY(x, y, z, l, w, t, tx, ty, tw, th, col, ord, cstOrd)
	x = -x; l = -l
	local vi, i1, i2, i3, i4 = procImage(col)
	xL[i1] = ppu * (x)
	xL[i2] = ppu * (x + l)
	xL[i3] = ppu * (x)
	xL[i4] = ppu * (x + l)
	yL[i1] = ppu * (y)
	yL[i2] = ppu * (y)
	yL[i3] = ppu * (y)
	yL[i4] = ppu * (y)
	zL[i1] = ppu * (z + w)
	zL[i2] = ppu * (z + w)
	zL[i3] = ppu * (z)
	zL[i4] = ppu * (z)
	local geo = getImageGeometry(t)
	txL[i1] = geo.x + tx
	txL[i2] = geo.x + tx + tw
	txL[i3] = geo.x + tx
	txL[i4] = geo.x + tx + tw
	tyL[i1] = geo.y + ty
	tyL[i2] = geo.y + ty
	tyL[i3] = geo.y + ty + th
	tyL[i4] = geo.y + ty + th

	local dx = cameraX + (x + l * .5)
	local dz = cameraZ - (z + w * .5)
	ordL[vi] = cstOrd
		and (ord or -vector2Magnitude(dx, dz))
		or ((ord or 0) - vector2Magnitude(dx, dz))
	-- zOrderL[vi] = cstOrd
	-- 	and (ord or -vectorMagnitude(dx, dy, dz))
	-- 	or (ord or 0) - vectorMagnitude(dx, dy, dz)
	-- zOrderL[vi] = ord or quadOrder(xL, yL, zL, i1, i2, i3, i4)
end

local drawImageY = F3DDraw.imageY

--- Draw an image perpendicular to z-axis
function F3DDraw.imageZ(x, y, z, l, h, t, tx, ty, tw, th, col, ord, cstOrd)
	x = -x; l = -l
	local vi, i1, i2, i3, i4 = procImage(col)
	xL[i1] = ppu * (x)
	xL[i2] = ppu * (x + l)
	xL[i3] = ppu * (x)
	xL[i4] = ppu * (x + l)
	yL[i1] = ppu * (y)
	yL[i2] = ppu * (y)
	yL[i3] = ppu * (y + h)
	yL[i4] = ppu * (y + h)
	zL[i1] = ppu * (z)
	zL[i2] = ppu * (z)
	zL[i3] = ppu * (z)
	zL[i4] = ppu * (z)
	local geo = getImageGeometry(t)
	txL[i4] = geo.x + tx
	txL[i3] = geo.x + tx + tw
	txL[i2] = geo.x + tx
	txL[i1] = geo.x + tx + tw
	tyL[i4] = geo.y + ty
	tyL[i3] = geo.y + ty
	tyL[i2] = geo.y + ty + th
	tyL[i1] = geo.y + ty + th

	local dx = cameraX + (x + l * .5)
	local dz = cameraZ - z
	ordL[vi] = cstOrd
		and (ord or -vector2Magnitude(dx, dz))
		or ((ord or 0) - vector2Magnitude(dx, dz))
	-- zOrderL[vi] = ord or -vectorMagnitude(cameraX + (x + l * .5), cameraY - (y + h * .5), cameraZ - z)
	-- zOrderL[vi] = ord or quadOrder(xL, yL, zL, i1, i2, i3, i4)
end

local drawImageZ = F3DDraw.imageZ

--- Draw a cube, used by `ParticleRenderer`
--- @param x number
--- @param y number
--- @param z number
--- @param l number
--- @param h number
--- @param w number
--- @param t string
--- @param tx integer
--- @param ty integer
--- @param tw integer
--- @param th integer
--- @param col Color
--- @param ord number?
--- @param cstOrd boolean?
function F3DDraw.cube(x, y, z, l, h, w, t, tx, ty, tw, th, col, ord, cstOrd)
	drawImageX(x, y, z, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
	drawImageY(x, y, z, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
	drawImageZ(x, y, z, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
	drawImageX(x + l, y, z, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
	drawImageY(x, y + h, z, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
	drawImageZ(x, y, z + w, w, h, t, tx, ty, tw, th, col, ord, cstOrd)
end

local function procText(i, gcol)
	local vi = va[0] + 1
	va[0] = va[0] + 1

	local i4 = vi * 4
	local i3 = i4 - 1
	local i2 = i3 - 1
	local i1 = i2 - 1
	colL[i1] = gcol[i + 1]
	colL[i2] = gcol[i + 2]
	colL[i3] = gcol[i + 3]
	colL[i4] = gcol[i + 4]

	return vi, i1, i2, i3, i4
end

--- Draw billboard text
function F3DDraw.text(x, y, z, args, font, ord, cstOrd)
	local gtx, gty, gx, gy, gcol = getTextAttributes(args, font)
	if not gtx[1] then
		return
	end

	local mat = staticMatrix:reset():rotate(0, atan2(cameraDZ, cameraDX) - hpi, 0)
	local zOrd
	do
		local dx = (x + (gx[1] + gx[#gx]) * (args.alignX or font.alignX or 0)) - cameraX
		local dz = (z) - cameraZ
		zOrd = cstOrd
			and (ord or -vector2Magnitude(dx, dz))
			or (ord or 0) - vector2Magnitude(dx, dz)
	end

	x = -x

	for i = 0, #gtx - 4, 4 do
		local vi, i1, i2, i3, i4 = procText(i, gcol)

		local x1 = gx[i + 1]
		local y1 = gy[i + 1]
		local z1 = 0
		local x2 = gx[i + 2]
		local y2 = gy[i + 2]
		local z2 = 0
		local x3 = gx[i + 3]
		local y3 = gy[i + 3]
		local z3 = 0
		local x4 = gx[i + 4]
		local y4 = gy[i + 4]
		local z4 = 0

		x1, y1, z1 = mat:multiplyVector(x1, y1, z1)
		x2, y2, z2 = mat:multiplyVector(x2, y2, z2)
		x3, y3, z3 = mat:multiplyVector(x3, y3, z3)
		x4, y4, z4 = mat:multiplyVector(x4, y4, z4)

		xL[i1] = ppu * (x + x1)
		yL[i1] = ppu * (y + y1)
		zL[i1] = ppu * (z + z1)
		xL[i2] = ppu * (x + x2)
		yL[i2] = ppu * (y + y2)
		zL[i2] = ppu * (z + z2)
		xL[i3] = ppu * (x + x3)
		yL[i3] = ppu * (y + y3)
		zL[i3] = ppu * (z + z3)
		xL[i4] = ppu * (x + x4)
		yL[i4] = ppu * (y + y4)
		zL[i4] = ppu * (z + z4)
		txL[i1] = gtx[i + 1]
		tyL[i1] = gty[i + 1]
		txL[i2] = gtx[i + 2]
		tyL[i2] = gty[i + 2]
		txL[i3] = gtx[i + 3]
		tyL[i3] = gty[i + 3]
		txL[i4] = gtx[i + 4]
		tyL[i4] = gty[i + 4]
		ordL[vi] = zOrd
	end
end

--- Draw a grounded text
function F3DDraw.textY(x, y, z, args, font, ord, cstOrd)
	local gtx, gty, gx, gy, gcol = getTextAttributes(args, font)
	if not gtx[1] then
		return
	end

	local zOrd
	do
		local dx = (x + (gx[1] + gx[#gx]) * .5) - cameraX
		local dz = (z + (gy[1] + gy[#gy]) * .5) - cameraZ
		zOrd = cstOrd
			and (ord or -vector2Magnitude(dx, dz))
			or (ord or 0) - vector2Magnitude(dx, dz)
	end

	x = -x

	for i = 0, #gtx - 4, 4 do
		local vi, i1, i2, i3, i4 = procText(i, gcol)
		local wx = x + gx[i + 1]
		local wz = z + gy[i + 1]
		local l = (gx[i + 2] - gx[i + 1])
		local w = (gy[i + 3] - gy[i + 1])
		xL[i1] = ppu * (wx)
		yL[i1] = ppu * (y)
		zL[i1] = ppu * (wz)
		xL[i2] = ppu * (wx + l)
		yL[i2] = ppu * (y)
		zL[i2] = ppu * (wz)
		xL[i3] = ppu * (wx)
		yL[i3] = ppu * (y)
		zL[i3] = ppu * (wz + w)
		xL[i4] = ppu * (wx + l)
		yL[i4] = ppu * (y)
		zL[i4] = ppu * (wz + w)
		txL[i1] = gtx[i + 1]
		tyL[i1] = gty[i + 1]
		txL[i2] = gtx[i + 2]
		tyL[i2] = gty[i + 2]
		txL[i3] = gtx[i + 3]
		tyL[i3] = gty[i + 3]
		txL[i4] = gtx[i + 4]
		tyL[i4] = gty[i + 4]
		ordL[vi] = zOrd
	end
end

local defaultWallCol = { -1, -1, -1, -1, -1 }
local tempWallCol = { -1, -1, -1, -1, -1 }

--- Draw a wall, used by `F3DTileRenderer`
--- @param x number position x
--- @param z number position z
--- @param l number length
--- @param w number width
--- @param h number height
--- @param t string top & side texture
--- @param tx1 number top texture shift x
--- @param ty1 number top texture shift y
--- @param tw1 number top texture width
--- @param th1 number top texture height
--- @param tx2 number front&back texture shift x
--- @param ty2 number front&back texture shift y
--- @param tw2 number front&back texture width
--- @param th2 number front&back texture height
--- @param tx3 number left&right texture shift x
--- @param ty3 number left&right texture shift y
--- @param tw3 number left&right texture width
--- @param th3 number left&right texture height
--- @param faces integer visible face flags: 1.front, 2.left, 3.back, 4.right
--- @param col (F3DRender.wall.col | Color)?
function F3DDraw.wall(x, z, l, w, h, t,
					  tx1, ty1, tw1, th1,
					  tx2, ty2, tw2, th2,
					  tx3, ty3, tw3, th3,
					  faces, col, zOrd)
	if type(col) == "number" then
		tempWallCol[1] = col
		tempWallCol[2] = col
		tempWallCol[3] = col
		tempWallCol[4] = col
		tempWallCol[5] = col
		col = tempWallCol
	elseif type(col) ~= "table" then
		col = defaultWallCol
	end

	if cameraY > h then
		drawImageY(x, h, z, l, w, t, tx1, ty1, tw1, th1, col[1], zOrd)
	end
	if bitAnd(faces, 0b0001) ~= 0 then
		drawImageX(x + l, 0, z, w, h, t, tx2, ty2, tw2, th2, col[2], zOrd)
	end
	if bitAnd(faces, 0b0010) ~= 0 then
		drawImageZ(x, 0, z + w, l, h, t, tx3, ty3, tw3, th3, col[3], zOrd)
	end
	if bitAnd(faces, 0b0100) ~= 0 then
		drawImageX(x, 0, z, w, h, t, tx2 + tw2, ty2, -tw2, th2, col[4], zOrd)
	end
	if bitAnd(faces, 0b1000) ~= 0 then
		drawImageZ(x, 0, z, l, h, t, tx3 + tw3, ty3, -tw3, th3, col[5], zOrd)
	end
end

return F3DDraw
