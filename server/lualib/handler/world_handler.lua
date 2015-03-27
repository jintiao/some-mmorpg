local skynet = require "skynet"

local handler = {}
local REQUEST = {}

local user

function handler.register (u)
	user = u

	local t = user.REQUEST
	for k, v in pairs (REQUEST) do
		t[k] = v
	end
end

function handler.unregister (u)
	assert (user == u)
	user = nil
	local t = u.REQUEST
	for k, _ in pairs (REQUEST) do
		t[k] = nil
	end
end

return handler

