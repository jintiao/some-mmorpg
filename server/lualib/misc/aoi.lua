local quadtree = require "misc.quadtree"
local print_r = require "print_r"

local aoi = {}

local object = {}
local qtree
local radius

function aoi.init (bbox, r)
	qtree = quadtree.new (bbox.left, bbox.top, bbox.right, bbox.bottom)
	radius = r
end

function aoi.insert (id, pos)
	if object[id] then return false end
	
	local tree = qtree:insert (id, pos.x, pos.z)
	if not tree then return false end

	local result = {}
	qtree:query (id, pos.x - radius, pos.z - radius, pos.x + radius, pos.z + radius, result)

	local interest_list = {}
	local notify_list = {}

	for i = 1, #result do
		local cid = result[i]
		local c = object[cid]
		if c then
			table.insert (interest_list, cid)
			table.insert (notify_list, cid)
			table.insert (c.interest_list, id)
		end
	end

	object[id] = { id = id, pos = pos, qtree = tree, interest_list = interest_list, notify_list = notify_list }
	
	return ok, interest_list, notify_list
end

function aoi.remove (id)
	local c = object[id]
	if not c then return false end

	if c.qtree then
		c.qtree:remove (id)
	else
		qtree:remove (id)
	end

	object[id] = nil
	return true, c.notify_list
end

return aoi
