local handler = {}
local mt = { __index = handler }

function handler.new (request, response)
	return setmetatable ({
		init_func = {},
		request = request,
		response = response,
	}, mt)
end

function handler:init (f)
	table.insert (self.init_func, f)
end

function handler:register (user)
	for _, f in pairs (self.init_func) do
		f (user)
	end

	local req = self.request
	if req then
		local t = user.REQUEST
		for k, v in pairs (req) do
			t[k] = v
		end
	end

	local resp = self.response
	if resp then
		local t = user.RESPONSE
		for k, v in pairs (resp) do
			t[k] = v
		end
	end
end

function handler:unregister (user)
	local req = self.request
	if req then
		local t = user.REQUEST
		for k, _ in pairs (req) do
			t[k] = nil
		end
	end

	local resp = self.response
	if resp then
		local t = user.RESPONSE
		for k, _ in pairs (resp) do
			t[k] = nil
		end
	end
end

return handler
