local quadtree = {}
local mt = { __index = quadtree }

function quadtree.new (l, t, r, b)
	return setmetatable ({
		left = l,
		top = t,
		right = r,
		bottom = b,
		object = {},
	}, mt)
end

function quadtree:insert (id, x, y)
	if x < self.left or x > self.right or y < self.top or y > self.bottom then return false end

	if self.children then
		for _, v in pairs (self.children) do
			if v:insert (id, x, y) then return true end
		end
	else
		self.object[id] = { x = x, y = y }

		if #self.object >= 20 then
			self:subdivide ()
		end
	end
end

function quadtree:subdevide ()
	local left, top, right, bottom = self.left, self.top, self.right, self.bottom
	local centerx = (left + right) // 2
	local centery = (top + bottom) // 2

	self.children = {
		quadtree.new (left, top, centerx, centery),
		quadtree.new (centerx, top, right, centery),
		quadtree.new (left, centery, centerx, bottom),
		quadtree.new (centerx, centery, right, bottom),
	}

	for k, v in pairs (self.object) do
		for _, c in self.children do
			if c:insert (k, v.x, v.y) then break end
		end
	end
	self.object = nil
end

function quadtree:query (id, left, top, right, bottom, result)
	if left > self.right or right < self.left or top > self.bottom or bottom < self.top then return end

	if self.children then
		for _, v in pairs (self.children) do
			v:query (id, left, top, right, bottom, result)
		end
	else
		for k, v in pairs (self.object) do
			if k ~= id and v.x > left and v.x < right and v.y > top and v.y < bottom then
				table.insert (result, k)
			end
		end
	end
end

return quadtree
