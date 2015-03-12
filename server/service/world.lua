local skynet = require "skynet"
local logger = require "logger"

local CMD = {}

function CMD.enter (agent, character)
	logger.log (string.format ("character (%d) try to enter, agent (%d)", character, agent))
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (source, ...))
	end)
end)
