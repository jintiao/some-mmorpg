local quadtree = require "misc.quadtree"
local print_r = require "print_r"

local aoi = {}

local object = {}
local qtree
local max_radius = 0

function aoi.init (bbox)
	qtree = quadtree.new (bbox.left, bbox.top, bbox.right, bbox.bottom)
end

function aoi.insert (id, pos, radius)
	if object[id] then return false end
	
	local ok = qtree:insert (id, pos.x, pos.z)
	if ok == false then return false end

	if radius > max_radius then
		max_radius = radius
	end

	local result = {}
	qtree:query (id, pos.x - max_radius, pos.z - max_radius, pos.x + max_radius, pos.z + max_radius, result)

	local interest_list = {}
	local notify_list = {}

	local sr = radius * radius
	for i = 1, #result do
		local cid = result[i]
		local c = object[cid]
		if c then
			local src = c.radius * c.radius
			local sd = (c.pos.x - pos.x) * (c.pos.x - pos.x) + (c.pos.z - pos.z) * (c.pos.z - pos.z)
			if sd < sr then
				table.insert (interest_list, cid)
			end
			if sd < src then
				table.insert (notify_list, cid)
				table.insert (c.interest_list, id)
			end
		end
	end

	object[id] = { id = id, pos = pos, radius = radius, interest_list = interest_list }
	
	return ok, interest_list, notify_list
end

return aoi
