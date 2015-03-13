local skynet = require "skynet"
local logger = require "logger"

local world, id = ...
local CMD = {}

skynet.start (function ()
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (source, ...))
	end)
end)
