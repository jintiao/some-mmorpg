local quadtree = require "map.quadtree"

local aoi = {}

local object = {}
local qtree
local radius

function aoi.init (bbox, r)
	qtree = quadtree.new (bbox.left, bbox.top, bbox.right, bbox.bottom)
	radius = r
end

function aoi.insert (id, pos)
	if object[id] then return end
	
	local tree = qtree:insert (id, pos.x, pos.z)
	if not tree then return end

	local result = {}
	qtree:query (id, pos.x - radius, pos.z - radius, pos.x + radius, pos.z + radius, result)

	local list = {}
	for i = 1, #result do
		local cid = result[i]
		local c = object[cid]
		if c then
			list[cid] = cid
			c.list[id] = id
		end
	end

	object[id] = { id = id, pos = pos, qtree = tree, list = list }
	
	return true, list
end

function aoi.remove (id)
	local c = object[id]
	if not c then return end

	if c.qtree then
		c.qtree:remove (id)
	else
		qtree:remove (id)
	end

	for _, v in pairs (c.list) do
		local t = object[v]
		if t then
			t.list[id] = nil
		end
	end
	object[id] = nil

	return true, c.list
end

function aoi.update (id, pos)
	local c = object[id]
	if not c then return end

	if c.qtree then
		c.qtree:remove (id)
	else
		qtree:remove (id)
	end

	local olist = c.list

	local tree = qtree:insert (id, pos.x, pos.z)
	if not tree then return end

	c.pos = pos

	local result = {}
	qtree:query (id, pos.x - radius, pos.z - radius, pos.x + radius, pos.z + radius, result)

	local nlist = {}
	for i = 1, #result do
		local cid = result[i]
		nlist[cid] = cid
	end

	local ulist = {}
	for _, a in pairs (nlist) do
		local k = olist[a]
		if k then
			ulist[a] = a
			olist[a] = nil
		end
	end

	for _, a in pairs (ulist) do
		nlist[a] = nil
	end

	c.list = {}
	for _, v in pairs (nlist) do
		c.list[v] = v
	end
	for _, v in pairs (ulist) do
		c.list[v] = v
	end

	return true, nlist, ulist, olist
end

return aoi
