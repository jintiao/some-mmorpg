local skynet = require "skynet"
local logger = require "logger"

local world = ...
local conf

local CMD = {}

function CMD.init (c)
	conf = c
end

function CMD.enter (character, agent)
	logger.log (string.format ("character (%d) entering map (%s)", character, conf.name))
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)
