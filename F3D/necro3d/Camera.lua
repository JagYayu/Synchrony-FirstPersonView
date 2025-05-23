--- @class F3D.Camera
--- @field [R3D.Camera.Field] number

--- @class F3DCamera : F3D.Camera
local F3DCamera = {}
local F3DMatrix = require "F3D.necro3d.Matrix"
local F3DVector = require "F3D.necro3d.Vector"

local GFX = require "system.gfx.GFX"
local Render = require "necro.render.Render"

local staticMatrix = F3DMatrix.static()

--- Note: the near clip and far clip are controlled by graphic engine, so they do nothing and just use the default value.
--- @enum R3D.Camera.Field
F3DCamera.Field = {
	Data = 0,
	X = 1,
	Y = 2,
	Z = 3,
	Pitch = 4,
	Yaw = 5,
	Roll = 6,
	Near = 7,
	Far = 8,
	FieldOfView = 9,
	AspectRatio = 10,
	FrustumPlanes = 11,
}
local FieldData = F3DCamera.Field.Data
local FieldX = F3DCamera.Field.X
local FieldY = F3DCamera.Field.Y
local FieldZ = F3DCamera.Field.Z
local FieldPitch = F3DCamera.Field.Pitch
local FieldYaw = F3DCamera.Field.Yaw
local FieldRoll = F3DCamera.Field.Roll
local FieldNear = F3DCamera.Field.Near
local FieldFar = F3DCamera.Field.Far
local FieldFieldOfView = F3DCamera.Field.FieldOfView
local FieldAspectRatio = F3DCamera.Field.AspectRatio
local FieldFrustumPlanes = F3DCamera.Field.FrustumPlanes

F3DCamera[FieldX], F3DCamera[FieldY], F3DCamera[FieldZ] = F3DVector.zero()
F3DCamera[FieldPitch], F3DCamera[FieldYaw], F3DCamera[FieldRoll] = F3DVector.zero()
F3DCamera[FieldNear] = 1e-3
F3DCamera[FieldFar] = 1e3
F3DCamera[FieldFieldOfView] = math.rad(90)
F3DCamera[FieldAspectRatio] = GFX.getWidth() / GFX.getHeight()
F3DCamera[FieldFrustumPlanes] = false

--- @return F3D.Camera
function F3DCamera.create()
	return {
		[FieldX] = F3DCamera[FieldX],
		[FieldY] = F3DCamera[FieldY],
		[FieldZ] = F3DCamera[FieldZ],
		[FieldPitch] = F3DCamera[FieldPitch],
		[FieldYaw] = F3DCamera[FieldYaw],
		[FieldRoll] = F3DCamera[FieldRoll],
		[FieldNear] = F3DCamera[FieldNear],
		[FieldFar] = F3DCamera[FieldFar],
		[FieldFieldOfView] = F3DCamera[FieldFieldOfView],
		[FieldAspectRatio] = F3DCamera[FieldAspectRatio],
	}
end

--- @type metatable
local metatable = { __index = F3DCamera }

function F3DCamera:reset()
	self[FieldX] = F3DCamera[FieldX]
	self[FieldY] = F3DCamera[FieldY]
	self[FieldZ] = F3DCamera[FieldZ]
	self[FieldPitch] = F3DCamera[FieldPitch]
	self[FieldYaw] = F3DCamera[FieldYaw]
	self[FieldRoll] = F3DCamera[FieldRoll]
	self[FieldNear] = F3DCamera[FieldNear]
	self[FieldFar] = F3DCamera[FieldFar]
	self[FieldFieldOfView] = F3DCamera[FieldFieldOfView]
	self[FieldAspectRatio] = F3DCamera[FieldAspectRatio]
	self[FieldData] = nil
end

function F3DCamera:getData()
	return self[FieldData]
end

function F3DCamera:setData(data)
	self[FieldData] = data
end

--- @param self F3D.Camera
--- @return number x
--- @return number y
--- @return number z
function F3DCamera:getPosition()
	return self[FieldX], self[FieldY], self[FieldZ]
end

--- @param self F3D.Camera
--- @param x number
--- @param y number
--- @param z number
--- @return self
function F3DCamera:setPosition(x, y, z)
	self[FieldX] = x
	self[FieldY] = y
	self[FieldZ] = z
	return self
end

--- @param self F3D.Camera
--- @return number pitch
--- @return number yaw
--- @return number roll
function F3DCamera:getRotation()
	return self[FieldPitch], self[FieldYaw], self[FieldRoll]
end

--- @param self F3D.Camera
--- @param pitch number
--- @param yaw number
--- @param roll number
--- @return self
function F3DCamera:setRotation(pitch, yaw, roll)
	self[FieldPitch] = pitch
	self[FieldYaw] = yaw
	self[FieldRoll] = roll
	return self
end

--- @param self F3D.Camera
--- @return number dirX
--- @return number dirY
--- @return number dirZ
function F3DCamera:getDirection()
	return staticMatrix:reset():rotate(self[FieldPitch], self[FieldYaw], self[FieldRoll])(F3DVector.forward())
	-- local x, y, z = F3DMatrix.new():rotateY(self[FieldYaw])(F3DVector.forward())
	-- F3DMatrix.new():rotateX(self[FieldYaw])
end

function F3DCamera:getNear()
	return self[FieldNear]
end

function F3DCamera:setNear(v)
	self[FieldNear] = v
end

function F3DCamera:getFar()
	return self[FieldFar]
end

function F3DCamera:setFar(v)
	self[FieldFar] = v
end

function F3DCamera:getFov()
	return self[FieldFieldOfView]
end

function F3DCamera:setFov(v)
	self[FieldFieldOfView] = v
end

function F3DCamera:getAspectRatio()
	return self[FieldAspectRatio]
end

function F3DCamera:setAspectRatio(v)
	self[FieldAspectRatio] = v
end

--- @return F3DCamera
function F3DCamera.new()
	--- @diagnostic disable-next-line: return-type-mismatch
	return setmetatable(F3DCamera.create(), metatable)
end

return F3DCamera
