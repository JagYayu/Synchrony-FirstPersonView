local F3DUtility = {}

local abs = math.abs
local inf = math.huge

function F3DUtility.copySign(a, b)
	return abs(a) * ((b >= 0) and 1 or -1)
end

--- @param list number[]
--- @return number, integer
function F3DUtility.findMax(list, fpairs)
	local maxIndex
	local maxValue = -inf
	for index, value in (fpairs or ipairs)(list) do
		if value > maxValue then
			maxIndex = index
			maxValue = value
		end
	end
	return maxValue, maxIndex
end

--- @param str string
--- @param pat string
--- @param list? string[]
--- @return string[]
function F3DUtility.splitString(str, pat, list)
	list = list or {}
	local f = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(f, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			list[#list + 1] = cap
		end
		last_end = e + 1
		s, e, cap = str:find(f, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		list[#list + 1] = cap
	end
	return list
end

return F3DUtility
