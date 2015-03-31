local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"

local handler = {}
local REQUEST = {}

local user

function REQUEST.map_follow (list)
	logger.log ("map_follow")
	print_r (list)
end

function REQUEST.map_notify (character, agent)
	logger.log ("map_notify")
	print (character, agent)
end

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

